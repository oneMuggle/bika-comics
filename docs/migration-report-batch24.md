# 哔咔漫画 桌面端→移动端 迁移分析报告 · 第二十四批（功能补漏）

## 一、批次概述

| 项目 | 状态 |
|---|---|
| 批次日期 | 2026-07-15 |
| 起始 HEAD | `1a01ff0`（与 `origin/main` 一致，工作区初始干净） |
| 本批目标 | 自动签到设置 + 收藏列表远程排序 |
| P0 / P1 核心迁移 | ✅ 已完成，本批不重复实现 |
| 批次前总体完成度 | 96%（第二十三批口径） |
| 批次后保守估计 | **98%**（补齐 2 个用户功能，并追加修复 P0/P1 首页与关键 API 主链路；代理仍为部分实现） |
| 严格桌面请求类计数 | **58** 个（`src/server/req.py` 中匹配 `^class \w+Req`） |
| CI / Gradle 改动 | **零**（继续遵守同根因 stop-after-N 规则） |

本批先核查桌面端与移动端实际代码，再实施可独立验证、风险较低的真实缺口。旧报告中的“63 个请求类”混用了历史/端点口径；按当前 `req.py` 的严格类名规则，结果为 58，后续报告应同时注明计数规则，避免把第三方 inline URL、重复路径或非 `*Req` 能力混在同一分母中。

---

## 二、完整迁移清单（桌面端有什么 → 移动端现在有什么 → 还缺什么）

### 2.1 P0（必须迁移）

| 桌面端能力 | 移动端实现 | 当前状态 |
|---|---|---|
| 首页推荐 / Collections / Random | `features/home/presentation/home_screen.dart` | ✅ |
| 分类浏览 | `features/comic/presentation/categories_screen.dart` | ✅ |
| 日/周/月/骑士排行榜 | `leaderboard_screen.dart`、`knight_rank_screen.dart` | ✅ |
| 漫画详情、章节、相关推荐 | `comic_detail_screen.dart` | ✅ |
| 阅读器 | `features/reader/presentation/reader_screen.dart` | ✅ 左右/上下双模式；桌面双页/卷模式因移动端 UX 暂不迁 |
| 搜索 / 热词 / 历史 / 分类筛选 | `search_screen.dart`、Drift 搜索历史 | ✅ |

### 2.2 P1（重要功能）

| 桌面端能力 | 移动端实现 | 当前状态 |
|---|---|---|
| 收藏 / 取消收藏 | `ComicRepository.favourite/unfavourite` | ✅ |
| 收藏列表远程排序 `dd/da` | `getMyFavourites(sort:)` + 收藏页排序菜单 | ✅ **本批补齐** |
| 追漫 / 取消追漫 | `ComicRepository.follow/unfollow` | ✅ |
| 评论、子评论、回复、点赞、举报 | `comments_screen.dart` + `ComicRepository` | ✅ |
| 下载管理 / ZIP 导出 | `features/download/`、`features/export/` | ✅ |
| 登录 / 注册 / 忘记密码 / 修改密码 | `features/auth/` | ✅ |
| 自动登录 | `AuthNotifier.login()` 保存凭证，`PicacgApp.initState()` 调用 `restore()` | ✅ 审计确认，非缺口 |
| 每日签到 | `AuthNotifier.punchIn()` + 个人中心手动入口 | ✅ |
| 登录后自动签到 | `SettingsStorage.autoSign` + `LoginScreen` 开关/触发 | ✅ **本批补齐** |
| 个人中心 / 头像 / 称号 / 我的评论 | `profile_screen.dart`、`user_repository.dart` | ✅ |
| 高级搜索 / 批量搜索 / 屏蔽词 | 对应 `features/comic/presentation/` 页面 | ✅ |

### 2.3 P2（辅助/增强功能）

| 桌面端能力 | 移动端实现 | 当前状态 / 差距 |
|---|---|---|
| 好友动态 | `features/friend/` | ✅ 含详情、评论和点赞 |
| 新聊天室 | `features/chat/` | ✅ 含 WebSocket 和图片发送 |
| 游戏 / 活动 / 游戏评论 | `features/game/`；`GameCommentsSection` 已挂到详情页 | ✅ |
| 设置 / 主题 /缓存 | `features/settings/` | ✅ |
| API 地址设置 | 设置页可保存，但 `ApiClient.instance` 仍硬编码 `defaultBaseUrl` | ⚠️ **部分实现，尚未生效** |
| HTTP / SOCKS5 代理 | 设置页和 `ProxySelector` 模型存在 | ⚠️ **链路未接通**：`ApiClient` 未调用 `ProxySelector`；写入 `Dio.options.extra` 也没有 adapter 消费 |
| 网络测速 | `speed_test_screen.dart` | ✅ |
| NAS 本地阅读 / ZIP / CBZ | `features/nas/` | ✅ |
| 远端 SFTP / WebDAV / SMB | 无 | ❌ 需验证第三方依赖、认证与平台权限 |
| 帮助 / 关于 | `features/help/` | ✅ |
| Pica Apps | `features/pica_apps/` | ✅ |
| 桌面自更新 / 数据库下载 / Init/IP 分流 | 无 | ⏭️ 平台专用，不迁移 |
| EPUB 转换 | 无 | ⏭️ 桌面任务本身为 stub，移动端无明确场景 |
| Waifu2x | 无 | ⏸️ 需 GPU 服务或移动端 NCNN 方案 |

---

## 三、本批实施内容

### 3.1 自动签到设置

**桌面端证据**：

- `src/config/setting.py`：`AutoSign = SettingValue("Other", 1, False)`，默认开启。
- `src/view/user/login_widget.py`：登录窗提供“自动打卡”复选框。
- `src/component/widget/navigation_widget.py`：登录成功后在 `AutoSign` 开启时触发签到。

**移动端实现**：

- `SettingsStorage` 新增 `auto_sign` 同步/异步读写，缺失时默认 `true`。
- `LoginScreen` 新增“自动签到”开关。
- 手动登录成功后保存开关；开启时调用既有 `AuthNotifier.punchIn()`。
- 签到失败不会回滚已成功的登录，也不会阻塞页面关闭。

> 自动登录不属于本批缺口：移动端此前已经安全存储邮箱/密码，并在 App 初始化时调用 `restore()` 重新登录。

### 3.2 收藏列表远程排序

**桌面端证据**：

- `src/view/user/favorite_view.py`：`sortList = ["dd", "da"]`。
- `src/interface/ui_favorite.py`：下拉项 index 0 为“新到旧”，index 1 为“旧到新”。
- `FavoritesReq` 把排序值透传为 `users/favourite?s=<sort>&page=<page>`。

**移动端实现**：

- `ComicRepository.getMyFavourites()` 新增 `sort` 参数并透传 `s=`。
- 新增 `FavouritesSort`：`dd/新到旧`、`da/旧到新`。
- 收藏页面 AppBar 新增排序菜单；Provider 以排序值作为 family key，切换后重新拉取。
- 保留刷新、错误重试和屏蔽词过滤。

---

## 四、审计修正与新发现

### 4.1 已实现、不得重复开发

| 审计项 | 代码证据 | 结论 |
|---|---|---|
| 自动登录 | `AuthNotifier.login()` 的 `setCredentials()`；`app.dart` 的 `restore()` | ✅ |
| 搜索分类过滤 | `search_screen.dart` 的 `selectedCategoryProvider` + `FilterChip` | ✅ |
| 评论举报 UI | `comments_screen.dart` 的 `_reportComment`、`onReport` 与举报底部菜单 | ✅ |
| 游戏评论 UI | `game_detail_screen.dart` 挂载 `GameCommentsSection(gameId:)` | ✅ |

### 4.2 代理设置报告需降级为“部分实现”

当前设置页可以保存 API 地址、HTTP/SOCKS5 类型、主机和端口，但运行时网络层并未真正应用：

1. `core/api/api_client.dart` 将 base URL 固定为 `ApiEndpoints.defaultBaseUrl`，未读取 `SettingsStorage.getApiBaseUrlSync()`。
2. `ProxySelector.applyToDio()` 没有调用点。
3. 即使调用，当前实现只写 `dio.options.extra['proxy']`，Dio 默认 IO adapter 不会自动消费该元数据。
4. HTTP 代理需要 `IOHttpClientAdapter`/`HttpClient.findProxy` 等经过测试的适配；SOCKS5 还需要独立支持方案，不能把配置 UI 等同于网络功能已完成。

因此代理链路列为后续 P2 功能缺口；本批不在没有网络集成测试的情况下扩张范围。

---

## 五、修改文件清单

| 文件 | 类型 | 说明 |
|---|---|---|
| `lib/core/storage/settings_storage.dart` | 修改 | 自动签到设置的持久化和同步缓存 |
| `lib/features/auth/presentation/login_screen.dart` | 修改 | 自动签到开关与登录后非阻塞签到 |
| `lib/features/comic/data/comic_repository.dart` | 修改 | 收藏排序参数透传 |
| `lib/features/comic/presentation/my_favourites_screen.dart` | 修改 | 排序枚举、Provider family、排序菜单 |
| `test/settings_storage_auto_sign_test.dart` | 新增 | 自动签到默认值、持久化、缓存恢复测试 |
| `test/favourites_sort_test.dart` | 新增 | 排序 API 映射与默认 Provider 状态测试 |
| `test/api_endpoints_p0_test.dart` | 新增（追加修复） | 登录、收藏、阅读器、分类、首页端点回归测试 |
| `test/home_screen_test.dart` | 新增（追加修复） | 首页 TabController 与抽屉回调 Widget 测试 |
| `lib/app.dart` | 修改（追加修复） | 推荐首页接入底部导航；保留全部漫画路由/抽屉入口 |
| `lib/shared/constants/api_constants.dart` | 修改（追加修复） | 修正关键 API 路径并新增分类 URL helper |
| `lib/features/home/presentation/home_screen.dart` | 修改（追加修复） | DefaultTabController、抽屉回调、Collections 常量 |
| `lib/features/comic/presentation/categories_screen.dart` | 修改（追加修复） | 使用分类标题构造 `/comics?c=` 请求 |
| `lib/features/comic/presentation/comic_list_screen.dart` | 修改（追加修复） | 独立路由时不再尝试打开不存在的内层 drawer |
| `docs/migration-report-batch24.md` | 新增 | 本批迁移与审计报告 |

未修改：`.github/workflows/`、`android/`、`pubspec.yaml`、数据库 schema、生成代码及以前批次报告。

---

## 六、验证结果

| 检查 | 结果 |
|---|---|
| `flutter pub get` | ✅ 成功 |
| `dart run build_runner build --delete-conflicting-outputs` | ✅ 成功，963 outputs / 1968 actions；仅提示 analyzer 版本低于当前 Dart SDK，未失败 |
| `flutter analyze lib/ test/` | ✅ 0 issues |
| `flutter test` | ✅ 28/28 全部通过（含追加端点与首页 Widget 测试） |
| `git diff --check` | ✅ 通过 |
| `flutter build apk --debug` | ❌ 本地 Android 工具链阻塞，非本批 Dart 代码错误 |

本地 APK 构建的直接证据：

- 项目固定 `ndkVersion = "27.0.12077973"`，当前 `jni` 插件提示需要 NDK `28.2.13676358`。
- 实际致命错误为 `CXX1429`：本地 NDK 27 缺少 `build/cmake/android.toolchain.cmake`，随后出现 `CMAKE_C_COMPILER/CXX_COMPILER not set`。

最新已完成 CI（推送本批前）：

- Run **#62**，数据库 ID `29273129492`，SHA `1a01ff0`。
- Setup Android SDK：Debug job 42s、Release job 34s，均成功。
- Build Debug APK / Build Release APK：均 158s 后失败，与 Run #60 的 158–160s 相同。
- 说明第二十三批文档提交没有改变既有工具链失败模式。

按 stop-after-N 规则，本批不继续盲目修改 Flutter、NDK、CMake、Gradle 或 workflow。推送本批后只做一次非阻塞 CI 状态核查；若仍是同一 Build APK 失败，则记录而不追加无证据配置提交。

---

## 七、未完成项与原因

| 项 | 状态 | 原因 / 下一步 |
|---|---|---|
| API 自定义地址运行时生效 | ⚠️ | 将 SettingsStorage 接入 ApiClient，并添加 URL 校验和网络测试 |
| HTTP 代理真实生效 | ⚠️ | 接入 IOHttpClientAdapter/HttpClient，测试认证和清除配置 |
| SOCKS5 代理真实生效 | ❌ | 默认 HttpClient 不原生提供完整 SOCKS5 路径，需评估依赖与安全模型 |
| 远端 NAS（SFTP/WebDAV/SMB） | ❌ | 第三方依赖、凭证存储、平台权限和失败恢复尚未设计 |
| 阅读器桌面四模式 | ⏭️ | 移动屏 UX 不适合直接照搬；现有左右/上下覆盖主路径 |
| EPUB / 自更新 / Init / 数据库下载 | ⏭️ | 桌面 stub 或平台专用能力 |
| Waifu2x | ⏸️ | 需要服务端 GPU 或移动端推理方案 |
| APK/CI 绿构建 | ⚠️ | 已知 NDK/CMake 工具链问题；需要管理员日志或用户批准的工具链决策 |

---

## 九、追加修复：P0 首页可达性与关键 API（late audit）

在本批首次提交 `2c76f71` 后，追加的源码级端点审计发现了数个**自初始脚手架即存在**、并非自动签到/收藏排序改动引入的运行时缺陷。此前静态分析和无网络单元测试无法发现这些问题，旧报告又记录了正确的桌面路径，导致“文档正确、代码错误”的偏差长期未被注意。

### 9.1 追加修复清单

| 严重度 | 旧状态 | 修复 |
|---|---|---|
| P0 | 底部“首页”实际显示通用 `ComicListScreen`，推荐/随机 `HomeScreen` 仅有无人调用的 `/home` 路由 | MainShell 首屏改为 `HomeScreen`；通过外层 `ScaffoldState` 回调正常打开抽屉；“全部漫画”保留为独立 `/comics` 路由和抽屉入口 |
| P0 | `HomeScreen` 的 `TabBar/TabBarView` 没有 `TabController`，一旦接线会断言 | 使用 `DefaultTabController(length: 2)` 包裹 |
| P0 | 登录常量是 `/auth/login`，桌面 `LoginReq` 和报告均为 `/auth/sign-in` | 改为 `/auth/sign-in` |
| P0 | 阅读器图片 helper 使用 `/eps/{episode}/pages`，桌面 `GetComicsBookOrderReq` 为 `/order/{episode}/pages?page=` | 改为 `/comics/{comic}/order/{episode}/pages?page=1`，支持显式 page |
| P1 | 收藏列表常量是 `/my/favourites`，桌面 `FavoritesReq` 为 `/users/favourite` | 改为 `/users/favourite`，保留本批 `s=dd/da` 排序参数 |
| P1 | 分类漫画调用占位 `/category?ccat=<id>`，桌面 `CategoriesSearchReq` 为 `/comics?page=&c=<分类标题>&s=` | 新增纯函数 helper，按分类标题 URL 编码并构造真实查询路径 |
| 维护性 | 首页推荐写死 `'/collections'` | 改用 `ApiEndpoints.collections` |

### 9.2 追加测试

- `test/api_endpoints_p0_test.dart`：登录、收藏、阅读器、分类、Collections/Random 路径回归测试。
- `test/home_screen_test.dart`：验证首页两个 Tab 可正常构建，以及菜单按钮能调用外层抽屉回调。

追加修复完成后，P0/P1 主链路的保守完成度由本报告前文的 97% 更新为 **98%**。剩余主要差距仍是 API 自定义地址/HTTP/SOCKS5 代理运行时接线、远端 NAS、平台专用能力以及 Android NDK/CMake CI 工具链。

---

## 十、结论

第二十四批最终包含两层工作：

1. 功能补漏：自动签到、收藏新旧排序；
2. late audit 追加修复：真正接通推荐首页，并纠正登录、收藏、阅读器和分类的关键请求路径。

这些追加缺陷均可追溯到初始 Flutter 脚手架，未由本批新功能造成。修复后由端点纯函数测试和首页 Widget 测试防止再次回归。
