# 第三十六批迁移状态审计（任务前提连续过期）

**日期**: 2026-08-01  
**触发**: cron `bika-comics-migration-daily`  
**审计基线**: 移动端 `9c2c92e2c0fb129ab028ba679c6fa8908327ddd3`；桌面端 `7d0a3fe`

## 三步现实核查

1. **仓库现实**：两个仓库均 clean；移动端本地 `main` 与 `origin/main` 一致。桌面参考仍为 `7d0a3fe`；移动端自 batch35 后只有其 SHA 回填提交，无产品代码变化。
2. **报告现实**：已读取 batch35、batch34，并复核 batch28 完整基线。迁移自 batch24 锚定 98.5%，batch26--35 连续判定无新增代码缺口；本次是连续第十二次命中过期前提。
3. **代码与基线现实**：实际盘点为桌面 `src/view` 18 个子域、移动端 14 个 feature、`lib` 76 个 Dart 文件、`test` 9 个 Dart 文件。`dart analyze lib/` 无问题，`flutter test` 38/38 通过。因此不重复实现 P0/P1/P2，仅保留本审计记录。

## 完整迁移矩阵

| 优先级 | 桌面端实际域 | 移动端实际实现 | 状态 |
|---|---|---|---|
| P0 | `index` | `features/home` | 完成 |
| P0 | `category`（分类/排行） | `features/comic/categories_screen.dart`, `leaderboard_screen.dart`, `knight_rank_screen.dart` | 完成 |
| P0 | `info/book_*`, `read` | `features/comic/comic_detail_screen.dart`, `features/reader` | 完成 |
| P0 | `search` | `features/comic/search_screen.dart`, `advanced_search_screen.dart` | 完成 |
| P0 | `user`（登录/注册/收藏/历史） | `features/auth`, `features/history`, favourites/follows screens | 完成 |
| P0 | `download` | `features/download` | 完成 |
| P1 | `comment`（漫画/动态/游戏） | comic comments、friend detail、game comments repository | 完成 |
| P1 | `chat`, `chat_new` | `features/chat`（含 WebSocket） | 完成 |
| P1 | `fried` | `features/friend` | 完成 |
| P1 | `game`, `info/game_info` | `features/game` | 完成 |
| P1 | `setting` | `features/settings`（代理/主题/自动签到/API 地址/测速） | 完成 |
| P1 | `help` | `features/help` | 完成 |
| P1 | `nas` | `features/nas`（本地/NAS/ZIP 阅读） | 完成；真实 NFS 环境待外部条件 |
| P1 | `convert` | `features/export`, `nas/zip_extractor.dart` | 完成 |
| P2 | `tool/forbid_words` | forbid words screen/repository | 完成 |
| P2 | `tool/local_*` | NAS/local/ZIP readers | 完成 |
| P2 | `tool/batch_sr`, `tool/waifu2x` | `batch_search_screen.dart` | 设计替换；移动 GPU/性能约束，不是缺口 |
| P2 | 桌面壳/Qt 专属组件 | Flutter `app.dart` 与 shared widgets | 平台适配完成，不逐件移植 Qt 控件 |

**覆盖**：18/18 桌面 view 子域均有移动实现或明确的平台设计替换。未发现可低风险补写的真实 P0/P1/P2 缺口。

## 验证

| 命令 | 结果 |
|---|---|
| `git fetch origin`; 比较 `HEAD`/`origin/main` | 均为 `9c2c92e` |
| `/home/ubuntu/flutter-sdk/bin/dart analyze lib/` | `No issues found!` |
| `/home/ubuntu/flutter-sdk/bin/flutter test` | `38/38 All tests passed!` |
| `/home/ubuntu/flutter-sdk/bin/flutter build apk --debug` | 未通过：本机 NDK 27 目录缺少 `build/cmake/android.toolchain.cmake`；同时 `jni` 提示期望 NDK 28.2 |

APK 失败发生在 CMake/Android SDK 环境配置阶段，不是 Dart 源码回归；与 batch21--35 记录的既有 NDK/CMake CI 环境问题同类。遵循“禁止无意义反复推送”，本批不为外部工具链抖动修改产品代码或工作流。

## CI 与未完成项

- GitHub CLI 可执行但当前环境未认证（要求 `gh auth login`/`GH_TOKEN`），故无法取得本次 run URL/status。
- NFS/NAS 真机互操作及 UMD/目标物理设备验证仍需要外部设备与环境。
- 未定义的 `mandatory` P2 范围仍无法实施；没有可验证需求时不猜测添加功能。
- cron 模板已连续十二次漂移。建议立即将成功且无代码变化的运行切换为 `[SILENT]` 心跳，停止生成重复审计批次。

## 本批变更

仅新增 `docs/migration-report-batch36.md`；产品源码、测试、依赖、Android 配置及桌面参考均未修改。
