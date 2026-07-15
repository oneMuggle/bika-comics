# 哔咔漫画 桌面端→移动端 迁移分析报告 · 第二十五批

## 一、批次概述

| 项目 | 状态 |
|---|---|
| 批次日期 | 2026-07-16 |
| 起始 HEAD | `b3f8095`（第二十四批 v2，与 `origin/main` 一致） |
| 本批目标 | 把"API 自定义地址"从 UI 持久化升级为运行时真正生效 |
| 完成度（前） | 98%（第二十四批口径） |
| 完成度（本批后保守估计） | **98.5%**（P2 列表再消 1 个 ⚠️ 缺口） |

本批以"已实现、但运行时未接通"的最后一个稳定 P2 缺口为目标，**不**触碰 CI/NDK 工具链（参见第二十一、二十二批的 stop-after-N 决策）。

---

## 二、本批解决的具体缺口

第二十四批已明确列为 ⚠️ 未生效：

> API 地址设置：设置页可保存，但 `ApiClient.instance` 仍硬编码 `defaultBaseUrl`

桌面端对应行为：`config.setting.Setting` 持久化用户填写的 API 主机，并在每次 `server.Server` 构造 HTTP 客户端时直接读取。本批为移动端实现对等语义。

---

## 三、桌面端证据

### 桌面端实现路径

1. `src/config/setting.py`：`SettingValue` 注册 `Host` 字段持久化用户配置。
2. `src/server/server.py`：构造 HTTP 客户端前读取 `setting.Host`，拼接请求路径。
3. `src/view/setting/setting_view.py`：设置页表单写入 `Setting` 实例。
4. 桌面端"自定义 API 地址"作用于 base URL，不影响 endpoint 路径。

### 关键代码引用

```python
# 桌面端 src/server/server.py（简化）
self.baseUrl = "https://%s/" % setting.Host.value
self.httpClient = requests.Session()
self.httpClient.headers.update({"User-Agent": setting.UserAgent.value})
```

关键点：base URL 与 endpoint 路径解耦；endpoint 全部以 `/auth/sign-in`、`/comics/...` 这种相对路径写死。移动端必须保持相同抽象，否则后续 endpoint 修复会被 base URL 改动影响。

---

## 四、移动端实现

### 4.1 设计选择：复用同步缓存，不引入新的全局可观察对象

`SettingsStorage` 已经通过 `populateCache()` 在 `main()` 中同步预加载了所有键值对，并由 `SettingsStorageHolder` 提供全局访问。这意味着 `ApiClient.instance`（每次构造 Dio 时同步读取）可以**无需**引入 `Future` 或 `riverpod` 异步监听——只要 `main()` 在 `runApp` 前调用 `populateCache`，后续每次 `ApiClient.instance` 都能拿到最新值。

不引入 `riverpod ref.watch` 的原因：

1. `ApiClient` 是无状态的静态工具类（`static Dio get instance`），接入 ref 会破坏现有所有调用方；
2. base URL 变化频率极低（用户手动改一次），用 `setApiBaseUrl` 显式写入后，下次 `ApiClient.instance` 调用就会读到新值；
3. 桌面端语义本身是"读取后即时生效"，不需要响应式订阅。

### 4.2 代码改动

#### 4.2.1 `lib/core/api/api_client.dart`

新增 `ApiClient.resolveBaseUrl()` 静态方法：

```dart
static String resolveBaseUrl() {
  try {
    final settings = SettingsStorageHolder.instance;
    final custom = settings.getApiBaseUrlSync();
    if (custom != null && custom.isNotEmpty &&
        ApiEndpoints.isValidBaseUrl(custom)) {
      return custom;
    }
  } on StateError {
    // SettingsStorageHolder 未初始化（仅在测试场景下可能发生），回退默认值。
  }
  return ApiEndpoints.defaultBaseUrl;
}
```

`instance` getter 改为调用 `resolveBaseUrl()`：

```dart
static Dio get instance {
  _dio.options.baseUrl = resolveBaseUrl();
  // ... 拦截器配置保持不变
}
```

非法 URL 防御性回退：用户保存了合法 URL 但运行时同步缓存被外部破坏（理论上不会发生，但保留为健壮性兜底）时，回退到默认 URL 而**不**抛异常，避免运行时崩溃。

#### 4.2.2 `lib/shared/constants/api_constants.dart`

新增 `ApiEndpoints.isValidBaseUrl(String?)` 与 `normalizeBaseUrl(String)` 工具方法：

```dart
/// 校验 http/https Base URL 合法性
static bool isValidBaseUrl(String? url) {
  if (url == null) return false;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  if (uri.host.isEmpty) return false;
  return true;
}

/// 去除首尾空白与末尾斜杠
static String normalizeBaseUrl(String url) {
  var v = url.trim();
  while (v.endsWith('/')) {
    v = v.substring(0, v.length - 1);
  }
  return v;
}
```

#### 4.2.3 `lib/features/settings/presentation/settings_screen.dart`

`SettingsNotifier.setApiBaseUrl` 改为先校验再保存：

```dart
Future<void> setApiBaseUrl(String url) async {
  if (!ApiEndpoints.isValidBaseUrl(url)) {
    throw ArgumentError.value(
      url, 'url',
      'API 地址必须为 http:// 或 https:// 开头的合法 URL',
    );
  }
  final normalized = ApiEndpoints.normalizeBaseUrl(url);
  await _storage.setApiBaseUrl(normalized);
  state = state.copyWith(apiBaseUrl: normalized);
}
```

行为变化：

- 非法输入抛 `ArgumentError`，调用方（设置页对话框）已经 try/catch + 弹 SnackBar；
- 合法输入会被去除末尾斜杠，避免 `https://x.com/` 与 `https://x.com` 被视为两个不同设置；
- 由于 `_storage.setApiBaseUrl` 会更新同步缓存，下一次 `ApiClient.instance` 自动读取新值，无需重启 App。

---

## 五、测试

### 5.1 新增 `test/api_base_url_resolve_test.dart`

共 10 个用例：

| 用例分组 | 用例 | 覆盖 |
|---|---|---|
| isValidBaseUrl | 接受 https/http（带或不带末尾斜杠、首尾空白） | 正向：合法 URL |
| isValidBaseUrl | 拒绝 null/空/纯空白 | 反向：空值 |
| isValidBaseUrl | 拒绝 ftp/file/javascript/无 scheme | 反向：非法 scheme |
| isValidBaseUrl | 拒绝 `https://` 等无 host 形式 | 反向：缺 host |
| normalizeBaseUrl | 去除单/多个末尾斜杠 | 正向：规范 |
| normalizeBaseUrl | 去除首尾空白 | 正向：规范 |
| resolveBaseUrl | 未初始化 holder 时回退默认值 | 健壮性 |
| resolveBaseUrl | 已初始化但未配置时回退默认值 | 默认路径 |
| resolveBaseUrl | 已配置合法 URL 时返回自定义值 | 主路径 |
| resolveBaseUrl | 已配置非法 URL 时回退默认值，不抛 | 健壮性 |

### 5.2 验证结果

| 检查 | 结果 |
|---|---|
| `flutter analyze lib/ test/` | ✅ 0 issues |
| `flutter test` | ✅ **38/38** 通过（含本批新增 10 个） |
| `git diff --check` | ✅ 通过 |
| `dart format` | ✅ 4 个文件全部已格式化 |

### 5.3 范围控制

**不**测试真实 HTTP 拉取：base URL 的生效是运行时行为，需要 mock Dio + 完整 network stack；本批目标是证明 URL 选择逻辑正确，而非真实联网测试。后者应留待集成测试或 UI 测试。

---

## 六、修改文件清单

| 文件 | 类型 | 说明 |
|---|---|---|
| `lib/core/api/api_client.dart` | 修改 | 新增 `resolveBaseUrl()`；`instance` getter 调用之 |
| `lib/shared/constants/api_constants.dart` | 修改 | 新增 `isValidBaseUrl` / `normalizeBaseUrl` |
| `lib/features/settings/presentation/settings_screen.dart` | 修改 | `setApiBaseUrl` 校验 + 规范化 |
| `test/api_base_url_resolve_test.dart` | 新增 | 10 个 URL 选择与校验用例 |
| `docs/migration-report-batch25.md` | 新增 | 本批迁移报告 |

未修改：`.github/workflows/`、`android/`、`pubspec.yaml`、数据库 schema、所有生成代码。

---

## 七、未完成项与原因

| 项 | 状态 | 原因 / 下一步 |
|---|---|---|
| HTTP 代理真实生效 | ⚠️ | 仍需 `IOHttpClientAdapter` / `HttpClient.findProxy` 接入并通过真实代理测试 |
| SOCKS5 代理真实生效 | ❌ | 需要评估 `dart:socks5` 等依赖与平台支持 |
| 远端 NAS（SFTP/WebDAV/SMB） | ❌ | 第三方依赖、凭证存储、平台权限未设计 |
| 阅读器桌面四模式 | ⏭️ | 移动 UX 不适合 |
| EPUB / 自更新 / Init / 数据库下载 | ⏭️ | 桌面 stub 或平台专用 |
| Waifu2x | ⏸️ | 需服务端 GPU 或移动推理方案 |
| APK / CI 绿构建 | ⚠️ | NDK/CMake 工具链问题，需管理员日志 |

---

## 八、本批决策日志

| 决策 | 选择 | 否决方案 | 原因 |
|---|---|---|---|
| base URL 同步读取 | `SettingsStorageHolder.instance.getApiBaseUrlSync()` | `ref.watch` + StateNotifier | 调用方 0 改动；语义对齐桌面端 |
| 非法 URL 处理 | 抛 `ArgumentError`（save）/ 静默回退（load） | 静默保存 / 一律抛错 | 写时早失败，读时绝不崩溃 |
| 末尾斜杠 | 规范化去除 | 保留原样 | 避免 `https://x.com` 与 `https://x.com/` 被视作不同配置 |
| 是否引入新依赖 | 否 | `flutter_dotenv` / `dio_http2` | 零依赖扩张，符合 stop-after-N 节奏 |

---

## 九、结论

第二十五批以最小代码改动（4 个文件，其中 1 个新增测试 + 3 个修改）把"自定义 API 地址"从 UI 持久化升级为运行时生效，与桌面端语义对齐。复用现有 `SettingsStorage` 同步缓存与 `SettingsStorageHolder` 全局访问机制，不引入新依赖、不触碰 CI/NDK 工具链。

后续剩余 ⚠️ 缺口（HTTP/SOCKS5 代理运行时接线、远端 NAS）需要更大改动面与真实网络测试，应作为下一轮独立批次处理。