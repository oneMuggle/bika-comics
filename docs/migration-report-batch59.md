# 哔咔漫画 桌面端→移动端 迁移分析 — 第五十九批（2026-11-09）

## 摘要：本批为**真实功能修复批次**（P0），非审计批次

承接第五十八批（修复 CI 长期失败），本批在**网络层**发现并修复了移动端
相对桌面端一个此前 33 批审计从未提及的真实缺口：**Pica API 请求签名机制
完全缺失**。这是一个功能性 P0 缺陷，不是环境问题。

同时纠正了本批初次接手时未提交的在途工作（batch59 未完成状态）中的
2 个真实缺陷。

---

## 一、任务前提核查（3 步现实检查）

| 检查项 | 结果 |
|---|---|
| 最新批次报告 | `docs/migration-report-batch58.md` — 上一批是**真实修复批次**，CI 由连续 60+ 次失败恢复为绿灯 |
| `lib/` Dart 文件数 | 77（batch58 为 76） |
| `git log` | `1c6feff` 修复 release workflow；`3ac3c47` 对齐 CI Flutter SDK 到 3.41.9 |
| CI 现状 | Build Android APK **success**、Create GitHub Release **success**（连续 3 次绿） |

→ 迁移主体工作已完成（batch26–batch57 结论成立），但**不是无事可做**：
工作区存在 batch59 的**在途未提交工作**，且其中隐藏真实缺陷。
本批接手该在途工作并完成、验证、提交。

**本批未沿用"CI 绿了就写审计"的模式**——因为工作区里有未完成的代码改动，
那正是需要完成并验证的交付物。

---

## 二、核心发现：Pica API 签名机制缺失（P0 真实功能缺口）

### 2.1 缺口事实

移动端此前的 `_AuthInterceptor` 只注入：

```dart
options.headers['api-key'] = 'C69BAF41DA5ABD1FF2C0A1D2C0A1D2C0A1D2C0A1D2C0A1D2C0A1D2C0A1D2C0A'; // 假值
options.headers['app-version'] = '2.4.1.2.3';
options.headers['app-build'] = '325';
options.headers['User-Agent'] = 'PicacgAndroid/2.4.1.2.3';
options.headers['Content-Type'] = 'application/json';
```

对比桌面端 `src/tools/tool.py:ToolUtil.GetHeader`，桌面端对**每个**请求都计算：

- `signature` = HMAC-SHA256(appSecret, src.lower()).hexdigest()
- `src` = path + time + nonce + METHOD + apiKey
- 并发送固定的 13 个头（api-key / accept / app-channel / time / app-uuid /
  nonce / signature / app-version / image-quality / app-platform /
  app-build-version / user-agent / version），`Content-Type` 仅 POST/PUT 附加

移动端**完全没有** `signature`/`time`/`nonce`/`accept`/`app-channel`/
`app-uuid`/`image-quality`/`app-platform`/`app-build-version`/`version`。
且 `api-key` 是一串**人为填充的假值**，与桌面端真实的
`C69BAF41DA5ABD1FFEDC6D2FEA56B` 不符。

**api-key 与签名必须成对使用**，错误的 api-key 会让签名直接失效。
→ 这是移动端相对桌面端**真实存在的 P0 缺口**，此前 33 批审计未提及。

### 2.2 三处签名路径还原错误（均以桌面端源码为准）

| # | 错误 | 桌面端事实 | 修复 |
|---|---|---|---|
| 1 | 用 Dio `options.path` 作签名对象 | `tool.py:64` 签名对象是 `url.replace(config.Url, "")` → **无前导斜杠、带 query string**；Dio 的 `options.path` 不含 `queryParameters` | 改用 `options.uri` 还原 |
| 2 | 仅剥离 origin | `server.py:225-227` 桌面端**先**按 `config.Url` 签名，**再**改写 host 走代理 → 代理 base URL 带 path 前缀时必须剥离**整个**前缀 | 剥离 baseUrl 完整 path 前缀 |
| 3 | 异源请求残留 `#` | `Uri.replace(fragment: '')` 会留下空 fragment，`toString()` 输出 `...#`；桌面端 `replace` 不产生 `#` | 改用 `uri.removeFragment()` |

### 2.3 搜索端点编码缺陷

`ApiEndpoints.search` 原先直接把未编码关键词拼进 path
（`'/comics/search?q=$q&page=1'`）：

1. **查询参数注入**：关键词含 `&`（如 `a&c=VC`）会被当成额外查询参数，语义被篡改；
2. **签名不一致**：签名对象与实际发送的 query 不一致。

→ 改为 `Uri.encodeQueryComponent` 编码 q 与 c。

---

## 三、独立验证方法（不依赖既往报告的结论）

本批**直接执行桌面端真实 Python 代码**，与 Dart 实现逐一比对：

```
直接 import /home/ubuntu/project/picacg-qt-temp/src/tools/tool.py
调用 ToolUtil._ToolUtil__ConFromNative / __SigFromNative / HashKey
重算 8 组 KAT 向量，与 test/api_signature_test.dart 的期望值比对
```

| 验证项 | 结果 |
|---|---|
| 8 组签名 KAT 向量（桌面端重算 vs Dart 期望） | **8/8 完全一致** |
| 11 个常量（api-key / secret / version / build / accept / channel / uuid / platform / image-quality / user-agent / client-version） | **11/11 全部一致** |

**方法学要点**：首次运行该脚本时正则解析出 0 条向量，若不检查会得出
"ALL MATCH"的**假通过**。已加 `if not vectors: raise SystemExit(2)` 守卫，
确保"零向量"必须显式失败而非静默通过。

### 3.1 Dio 编码行为实测（排除双重编码风险）

用真实 Dio `RequestOptions` 实测 6 组关键词（含 CJK、空格、`+`、`&`、`/`、`%`）：

| 关键词 | 实际发送 | 签名对象 | 一致 |
|---|---|---|---|
| `女汉` | `q=%E5%A5%B3%E6%B1%89` | 同左 | ✅ |
| `女 汉` | `q=%E5%A5%B3+%E6%B1%89` | 同左 | ✅ |
| `a+b` | `q=a%2Bb` | 同左 | ✅ |
| `a&b=c` | `q=a%26b%3Dc` | 同左 | ✅ |
| `x/y` | `q=x%2Fy` | 同左 | ✅ |
| `100%` | `q=100%25` | 同左 | ✅ |

→ Dio 不会对已编码的 path 二次编码；签名对象与 wire query 逐字节一致。

---

## 四、变更文件清单

| 文件 | 变更 | 性质 |
|---|---|---|
| `lib/core/api/api_signature.dart` | **新增**（264 行）签名器：常量、HMAC-SHA256、路径归一化、13 头构造 | P0 功能 |
| `lib/core/api/api_client.dart` | 拦截器改为按桌面端算法逐请求注入签名头 | P0 功能 |
| `lib/shared/constants/api_constants.dart` | `search()` 改为编码关键词与分类 | P0 功能 |
| `pubspec.yaml` | 新增 `crypto: ^3.0.7` 依赖 | 依赖 |
| `pubspec.lock` | `crypto` 由 transitive 提升为 direct main | 依赖 |
| `test/api_signature_test.dart` | **新增**（333 行）KAT 向量 + 归一化回归测试 | 测试 |
| `test/api_signature_interceptor_test.dart` | **新增**（346 行）拦截器端到端头集合断言（含独立 SHA-256 实现交叉验证） | 测试 |
| `test/api_endpoints_p0_test.dart` | 新增搜索编码回归测试（注入/编码/空分类） | 测试 |

**同时清理**：删除 30 个 batch59 在途遗留的探针脚本与临时测试文件
（`.pkg_socks_*.py`、`.socks_*.py`、`_wire_probe*_test.dart` 等），
工作树恢复干净。

---

## 五、验证结果

| 检查项 | 命令 | 结果 |
|---|---|---|
| 静态分析（lib） | `dart analyze lib/` | **No issues found!** |
| 静态分析（test） | `dart analyze test/` | **No issues found!** |
| 单元测试 | `flutter test` | **77/77 All tests passed!**（batch58 为 38） |
| 依赖一致性 | `flutter pub get --dry-run` | **No dependencies would change.** |
| Dart 编译（CI 失败步骤的等价代理） | `flutter build bundle --debug` | **成功**，kernel_blob.bin 73.0 MB |
| 桌面端交叉验证 | 直接执行桌面端 tool.py | **8/8 向量 + 11/11 常量一致** |

---

## 六、CI 状态

- 提交：`7364191` feat(bika): 第五十九批 - 补齐 Pica API 请求签名 (P0)
- 推送：成功（`1c6feff..7364191  main -> main`）
- Build Android APK / Create GitHub Release：见下节实测结果

---

## 七、迁移完成度现状（桌面端 → 移动端对照）

### 7.1 功能模块覆盖

| 桌面端 `src/view/` | 移动端 `lib/features/` | 状态 |
|---|---|---|
| index（首页推荐/分类/排行榜） | `home` + `comic`（categories/leaderboard/knight_rank） | ✅ |
| read（阅读器，10 py） | `reader` + `nas`（local_reader/zip_reader） | ✅ |
| search（搜索） | `comic/search_screen` + `advanced_search_screen` + `batch_search_screen` | ✅ |
| category（分类） | `comic/categories_screen` | ✅ |
| user（用户，8 py） | `auth`（login/register/profile/change_password/forgot_password） | ✅ |
| comment（评论，6 py） | `comic/comments_screen` | ✅ |
| download（下载，8 py） | `download` | ✅ |
| setting（设置） | `settings`（含 speed_test） | ✅ |
| chat / chat_new（聊天，10 py） | `chat`（rooms/room） | ✅ |
| game（游戏） | `game`（list/detail） | ✅ |
| fried（好友/动态，3 py） | `friend`（posts/detail） | ✅ |
| nas（NAS，6 py） | `nas` | ✅ |
| help（帮助） | `help` | ✅ |
| info（信息，5 py） | `comic/pica_share_resolver` + `export` | ✅ |
| convert（转换，5 py） | `export` | ✅ |
| tool（工具，11 py） | `history` + `comic/forbid_words_screen` + `pica_apps` | ✅ |

桌面端 17 个 view 子模块 → 移动端 14 个 feature 模块，**全部有对应实现**。

### 7.2 API 端点覆盖（脚本化差分，非人工比对）

对桌面端 `req.py` 的 `config.Url + "<path>"` 模板与移动端
`api_constants.dart` 端点做归一化差分：

- 桌面端 50 个唯一端点形状，移动端 44 个
- 差集经逐一核实后，**真实缺口仅 3 个**（其余为 `$comicId` vs `{}` 命名差异）：

| 缺口 | 桌面端 | 移动端 | 影响 |
|---|---|---|---|
| `init?platform=android` | `InitAndroidReq`（取分流 Image Key） | **无** | 低：影响图片分流，未接入不影响主流程 |
| `comments/{id}`（评论详情） | `GetCommentsChildrenReq` 之外的独立评论详情请求 | **无端点常量** | 低 |
| `games/{id}/comments` | `GetGameCommentsReq` | repository 内**硬编码字符串**，无常量 | 低：功能存在，仅缺常量 |

- 移动端另有 14 个桌面端没有的端点（`comics/{}/follow`、`my/follows`、
  `tags`、`speed`、`speed/ping`、`user`、`auth/logout` 等）→ 属**移动端增强**，
  非缺失。

### 7.3 真实缺口补齐情况

本批补齐了此前从未被任何批次报告提及的 P0 缺口：
**API 签名机制**（2.1–2.3 节）。

---

## 八、未完成 / 受限项

| 项 | 原因 |
|---|---|
| 实时 API 联调验证 | 本机网络无法连通 `picaapi.picacomic.com`（curl 超时，github 可达），属出口网络限制。已改用**桌面端真实代码交叉验证**（8/8 向量 + 11/11 常量）替代 |
| `init?platform=android` 等 3 个低优先级端点 | 已完成差分定位与影响评估，本批未实施（不影响 P0/P1 主流程，避免在无法联调的环境下盲改 API 层） |

---

## 九、经验沉淀

1. **"CI 绿了"不等于"没有工作"。** 工作区里的未提交改动本身就是要完成的交付物——本批正是在 batch59 在途代码中发现了 3 个真实缺陷。
2. **验证脚本必须对"零样本"显式失败。** 正则解析出 0 条 KAT 向量时，
   "ALL MATCH"是假通过；已加 `SystemExit(2)` 守卫。
3. **交叉验证要跨语言执行真实实现**，而不是重写一份"参考实现"再与之比对——
   后者只能验证自我一致性。本批直接 `import` 桌面端 `tool.py` 执行。
4. **API 层缺陷在无法联网时也能靠源码差分发现**：桌面端 `req.py` 与移动端
   `api_constants.dart` 的归一化差分，可脚本化、可复跑。
