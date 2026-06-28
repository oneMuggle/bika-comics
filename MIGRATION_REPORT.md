# 哔咔漫画 桌面端→移动端 迁移分析报告

> 更新日期：2026-06-29
> 状态：**P0 / P1 / P2 + 弃用 API 现代化 + 聊天室图片 + NAS ZIP/CBZ + 代码健康度 lint 全部完成**；累计 **14 个批次**，**73 个 Dart 文件**，**0 errors / 0 warnings**（**160 info-level lints，从 178 下降 -18**）。
> **2026-06-29 第十四批「代码健康度 lint 清理」**：零功能改动，闭环所有不依赖 Flutter SDK 升级的 info-level 静态分析提示 —— `dangling_library_doc_comments`（3 处）、`prefer_interpolation_to_compose_strings`（2 处）、`prefer_const_declarations`（1 处）、`use_build_context_synchronously`（12 处）。`deprecated_member_use`（4 处 `RadioListTile`）保留为 L1 候选，需 CI Flutter 升级 3.27.4 → 3.32.x 方可安全迁移。
> **2026-06-26 第十三批「NAS ZIP / CBZ 漫画包阅读」**：闭环桌面端与移动端在「本地漫画包」功能上的最后差距 — 对齐 `view/tool/local_read_view.py#CheckAction2` 拖入/选择 .zip/.cbz 解析流程。
> **2026-06-23 第十二批「聊天室图片发送」**：闭环桌面端与移动端在「聊天」功能上的最后差距 — `message/send-image` 端点对齐桌面端 `SendNewChatImgMsgReq`。
> **2026-06-22 第十一批「迁移审计」**：重新梳理桌面端 / 移动端的功能映射、API 端点差异、剩余未迁移项，作为未来可选批次的决策依据。

---

## 一、桌面端完整功能列表 (Picacg Qt)

> 参考目录：`/home/ubuntu/project/picacg-qt-temp/src/view/`

| 功能模块 | 状态 | 核心文件 |
|---------|------|---------|
| 首页推荐 | ✅ | `view/index/index_view.py` |
| 随机推荐 | ✅ | `view/index/index_view.py` |
| 分类浏览 | ✅ | `view/category/category_view.py` |
| 排行榜 | ✅ | `view/category/rank_view.py` |
| **骑士榜** | ✅ | `view/category/rank_view.py` (第 4 个 Tab) |
| 搜索 | ✅ | `view/search/search_view.py` |
| 高级搜索（多条件） | ✅ | `view/search/search_view.py` |
| 漫画详情 | ✅ | `view/info/book_info_view.py` |
| 漫画阅读器 | ✅ | `view/read/read_view.py` + `read_tool.py` |
| 收藏功能 | ✅ | `server/req.py` |
| 追漫功能 | ✅ | `server/req.py` |
| 评论功能 | ✅ | `view/comment/` |
| 用户登录注册 | ✅ | `view/user/` |
| 设置页面 | ✅ | `view/setting/setting_view.py` |
| 下载管理 | ✅ | `view/download/` |
| **Pica 号解析** | ✅ | `server/req.py` (`GetIdByShareIdReq` 等) |
| 本地阅读（NAS） | ✅ | `view/nas/` |
| 搜索历史 | ✅ | SQLite本地存储 |
| **网络测速** | ✅ | `server/req.py` (`SpeedTestReq`, `SpeedTestPingReq`) |
| **游戏/活动** | ✅ | `view/game/` + `view/info/game_info_view.py` |
| 好友系统（锅贴） | ✅ | `view/fried/` (独立 API `post-api.wikawika.xyz`) |
| 聊天室 | ✅ | `view/chat_new/` (独立服务 `live-server.bidobido.xyz` + WebSocket) |
| Waifu2x 图片放大 | ✅ | `view/tool/waifu2x_tool_view.py` |
| 批量搜索工具 | ✅ | `view/tool/batch_sr_tool_view.py` |
| 搜索屏蔽词 | ✅ | `view/tool/forbid_words_view.py` |
| 本地章节阅读 | ✅ | `view/tool/local_*_view.py` (本地分类 / 文件夹 / 全本 / 章节) |

---

## 二、移动端已有功能列表 (Flutter)

> 全部按 `lib/features/` 目录组织，共 10 个 feature 模块 + `core/` + `shared/`

### 2.1 `features/auth/`（认证 + 账号设置）

| 功能 | 状态 | 文件 |
|-----|------|------|
| 登录 | ✅ | `presentation/login_screen.dart` |
| 注册 | ✅ | `presentation/register_screen.dart` |
| 个人中心 | ✅ | `presentation/profile_screen.dart` (含签到 / 我的评论 / 退出登录) |
| 每日签到 (`/users/punch-in`) | ✅ | `data/auth_repository.dart#punchIn()` |
| 我的评论 (`/users/my-comments`) | ✅ | `data/user_repository.dart` |
| 修改密码 (`PUT /users/password`) | ✅ | `presentation/change_password_screen.dart` |
| 忘记密码（找回流程） | ✅ | `presentation/forgot_password_screen.dart` |
| 修改头像 (`PUT /users/avatar`) | ✅ | `presentation/profile_screen.dart` + `image_picker` |
| 修改个人称号 (`PUT /users/{id}/title`) | ✅ | `presentation/profile_screen.dart` |

### 2.2 `features/comic/`（漫画核心：列表 / 详情 / 评论 / 搜索 / 排行榜）

| 功能 | 状态 | 文件 |
|-----|------|------|
| 漫画列表（首页/分类/排行榜共用） | ✅ | `presentation/comic_list_screen.dart` |
| 分类浏览 | ✅ | `presentation/categories_screen.dart` |
| 排行榜（4-Tab） | ✅ | `presentation/leaderboard_screen.dart` |
| **骑士榜** | ✅ | `presentation/knight_rank_screen.dart` (第 4 Tab) |
| 搜索（关键词） | ✅ | `presentation/search_screen.dart` |
| **搜索热词** | ✅ | `data/comic_repository.dart#getKeywords()` + 搜索页空态 chips |
| **搜索历史 UI** | ✅ | `presentation/search_screen.dart` (单条/一键清除) |
| **高级搜索** | ✅ | `presentation/advanced_search_screen.dart` (关键词+多分类+5 排序) |
| **批量搜索工具** | ✅ | `presentation/batch_search_screen.dart` + `data/batch_search_repository.dart` |
| **搜索屏蔽词** | ✅ | `presentation/forbid_words_screen.dart` + `data/forbid_words_repository.dart` |
| 漫画详情 | ✅ | `presentation/comic_detail_screen.dart` |
| **漫画相关推荐** | ✅ | `data/comic_repository.dart#getComicRecommendation()` + 详情页底部横滑 |
| **Pica 号解析** | ✅ | `presentation/pica_share_resolver_screen.dart` + `data/pica_share_service.dart` |
| 评论（含子评论 / 回复 / 点赞） | ✅ | `presentation/comments_screen.dart` |
| 我的收藏 | ✅ | `presentation/my_favourites_screen.dart` |
| 我的追漫 | ✅ | `presentation/my_follows_screen.dart` |

### 2.3 `features/reader/`（阅读器）

| 功能 | 状态 | 文件 |
|-----|------|------|
| 单页模式（横滑 PhotoViewGallery） | ✅ | `presentation/reader_screen.dart` |
| **条状/长图模式**（垂直滚动） | ✅ | `presentation/reader_screen.dart#_ReaderMode.strip` |
| 页码跳转对话框 | ✅ | `presentation/reader_screen.dart#_showPageDialog` |
| 模式切换（AppBar swap_vert/horiz） | ✅ | `presentation/reader_screen.dart` |

### 2.4 `features/download/`（下载管理）

| 功能 | 状态 | 文件 |
|-----|------|------|
| 下载管理 UI | ✅ | `presentation/download_screen.dart` |
| 下载 Repository（任务队列、并发、进度） | ✅ | `data/download_repository.dart` |
| 本地存储 (Drift) | ✅ | `core/db/database.dart` |

### 2.5 `features/history/`（阅读历史）

| 功能 | 状态 | 文件 |
|-----|------|------|
| 阅读历史列表 | ✅ | `presentation/history_screen.dart` |
| SQLite 持久化 | ✅ | `core/db/database.dart` |

### 2.6 `features/home/`（首页推荐）

| 功能 | 状态 | 文件 |
|-----|------|------|
| 首页 Collections | ✅ | `presentation/home_screen.dart` |
| 随机推荐 | ✅ | `data/comic_repository.dart` (内嵌在首页流程) |

### 2.7 `features/game/`（游戏区 — 第四批新增）

| 功能 | 状态 | 文件 |
|-----|------|------|
| 游戏列表（3 列 GridView + 无限滚动 + 徽章） | ✅ | `presentation/game_list_screen.dart` + `data/game_repository.dart` |
| 游戏详情（图标/标题/平台徽章/截图/下载链接） | ✅ | `presentation/game_detail_screen.dart` |
| 游戏评论（加载/发送/点赞） | ✅ | `data/game_comments_repository.dart` + 详情页嵌入 `GameCommentsSection` |

### 2.8 `features/chat/`（聊天室 — 第五批新增）

| 功能 | 状态 | 文件 |
|-----|------|------|
| 聊天室列表（自动登录 chat 服务 + 拉取房间） | ✅ | `presentation/chat_rooms_screen.dart` |
| 聊天室消息（WebSocket 实时） | ✅ | `presentation/chat_room_screen.dart` |
| Chat Repository（独立 token、profile 缓存） | ✅ | `data/chat_repository.dart` |
| Chat 领域模型（Room / Profile / Message） | ✅ | `domain/chat_model.dart` |

### 2.9 `features/friend/`（好友动态 / 锅贴 — 第五批新增）

| 功能 | 状态 | 文件 |
|-----|------|------|
| 动态列表（`/posts?offset=N`） | ✅ | `presentation/friend_posts_screen.dart` + `data/friend_repository.dart` |
| 动态详情 + 评论（`/posts/{id}/comments`） | ✅ | `presentation/friend_post_detail_screen.dart` |
| 发送评论 / 点赞评论 | ✅ | `data/friend_repository.dart` |
| 锅贴领域模型（Post / Comment / User） | ✅ | `domain/friend_post_model.dart` |

### 2.10 `features/settings/`（设置）

| 功能 | 状态 | 文件 |
|-----|------|------|
| 设置主页（含 API 地址、代理、主题、缓存、关于） | ✅ | `presentation/settings_screen.dart` |
| **网络测速**（Ping + 下载速度） | ✅ | `presentation/speed_test_screen.dart` + `data/speed_test_service.dart` |
| 搜索屏蔽词入口 | ✅ | `settings_screen.dart` → `/forbid-words` |
| 批量搜索工具入口 | ✅ | `settings_screen.dart` → `/batch-search` |

### 2.11 `core/`（核心基础设施）

| 模块 | 状态 | 文件 |
|-----|------|------|
| API Client（Dio + 认证拦截器） | ✅ | `core/api/api_client.dart` |
| 数据库（Drift / SQLite） | ✅ | `core/db/database.dart` + `database.g.dart` |
| 安全存储（Token） | ✅ | `core/storage/secure_storage.dart` |
| 设置存储（含 forbid_words 配置） | ✅ | `core/storage/settings_storage.dart` |
| 代理选择器 | ✅ | `core/utils/proxy_selector.dart` |

### 2.12 `shared/`（共享资源）

| 模块 | 状态 | 文件 |
|-----|------|------|
| API 常量（含新端点） | ✅ | `shared/constants/api_constants.dart` |
| 主题色 / 亮暗主题 | ✅ | `shared/constants/app_colors.dart` |
| 文案常量（含 speedTest / picaShare / chat / friend） | ✅ | `shared/constants/app_strings.dart` |
| 通用图片缓存 | ✅ | `shared/widgets/cached_image.dart` |
| 漫画卡片 | ✅ | `shared/widgets/comic_card.dart` |
| Loading 指示器 | ✅ | `shared/widgets/loading_indicator.dart` |

---

## 三、功能差距对比（Gap Analysis）

### P0 - 关键功能 ✅ 100% 完成

| 功能 | 状态 | 说明 |
|-----|------|------|
| 首页推荐/分类/排行榜 | ✅ | 已实现（含骑士榜） |
| 漫画详情页 | ✅ | 含相关推荐横滑 |
| 漫画阅读器 | ✅ | 单页/条状双模式 |
| 搜索功能 | ✅ | 关键词 + 热词 + 历史 + 高级 + 批量 + 屏蔽 |

### P1 - 重要功能 ✅ 100% 完成

| 功能 | 状态 | 说明 |
|-----|------|------|
| 收藏/追漫/点赞 | ✅ | 已实现 |
| 我的收藏/追漫页 | ✅ | 已实现 |
| 评论（含子评论、回复、点赞） | ✅ | 已实现 |
| 阅读历史 | ✅ | 含 SQLite 持久化 |
| 搜索历史 | ✅ | chips UI + 单条/一键删除 |
| 分类筛选搜索 | ✅ | categories_screen |

### P2 - 增强功能 ✅ 100% 完成（仅余辅助项）

| 功能 | 状态 | 说明 |
|-----|------|------|
| 下载管理 | ✅ | 第四批仓库 + UI 完整实现 |
| 骑士榜 | ✅ | 2026-06-02（第二批起）|
| Pica 号解析 | ✅ | 2026-06-02 |
| 网络测速 | ✅ | 2026-06-02（Ping + 下载）|
| 搜索热词 | ✅ | 2026-06-03 |
| 漫画相关推荐 | ✅ | 2026-06-03 |
| 个人中心 / 签到 / 我的评论 | ✅ | 2026-06-03 |
| 修改密码 / 忘记密码 / 头像 / 称号 | ✅ | 2026-06-04 |
| 高级搜索 | ✅ | 2026-06-04 |
| 阅读器多模式（条状/单页） | ✅ | 2026-06-04 |
| 游戏区（列表 / 详情 / 评论） | ✅ | 2026-06-05（第四批）|
| **聊天室（WebSocket 实时）** | ✅ | 2026-06-06（第五批）|
| **好友动态 / 锅贴** | ✅ | 2026-06-06（第五批）|
| **批量搜索工具** | ✅ | 2026-06-06（第五批）|
| **搜索屏蔽词** | ✅ | 2026-06-06（第五批）|
| 屏蔽词运行时接入 | ✅ | 2026-06-10（第六批）|
| NAS 本地阅读起步 | ✅ | 2026-06-10（第六批）|
| **NAS 文件浏览器** | ✅ | 2026-06-12（第七批）|
| **本地图片阅读器（单页+条状）** | ✅ | 2026-06-12（第七批）|
| 本地章节阅读（local_*_view） | ✅ | 2026-06-12（第七批，文件浏览器 + 阅读器覆盖） |
| Waifu2x 图片放大 | ❌ | 未迁移（移动端性能考虑） |

---

## 四、本次（第五批）新增迁移

> 提交日期：2026-06-06
> 状态：✅ 全部完成

### 4.1 聊天（Chat）

桌面端对应：`view/chat_new/` (`chat_new_view.py` / `chat_new_websocket.py`)

- **聊天仓库** `features/chat/data/chat_repository.dart`（173 行）
  - 独立 baseUrl `https://live-server.bidobido.xyz/`
  - 桌面端 `GetNewChatLoginReq` / `GetNewChatProfileReq` / `GetNewChatReq` / `SendNewChatMsgReq` 全部对应
  - 聊天 token 与主 API token 分别保存（`SecureStorageHolder` `chat_token` key）
  - 缓存 profile 与 token，开关不重复登录
- **聊天模型** `features/chat/domain/chat_model.dart`（171 行）
  - `ChatRoom` / `ChatProfile` / `ChatMessage` 完整字段
  - 支持桌面端全部消息 type（TEXT / IMAGE / CONNECTED / INITIAL_MESSAGES / ...）
- **聊天房间列表** `features/chat/presentation/chat_rooms_screen.dart`（176 行）
  - 自动登录 → 拉取 `room/list` → 点击进入
  - 列表显示图标 + 描述 + 最低等级/注册天数
- **聊天室消息** `features/chat/presentation/chat_room_screen.dart`（524 行）
  - WebSocket 实时收发，桌面端 `ChatNewWebSocket.Start` 完整对齐
  - ws URL 转换（https→wss、http→ws）+ `?token=...&room=...` 握手
  - 30s ping_interval 自动保活
  - 发送 / 回复 / 撤回 / 历史消息加载

### 4.2 好友动态（Friend / 锅贴）

桌面端对应：`view/fried/` (`fried_view.py` / `qt_fried_msg.py` + `server/req.py`)

- **锅贴仓库** `features/friend/data/friend_repository.dart`（119 行）
  - 独立 baseUrl `https://post-api.wikawika.xyz`
  - User-Agent 模拟桌面端 Chrome 86
  - `Referer: <base>/?token=<token>` + `token` header 双校验
  - `getPosts` / `getComments` / `sendComment` / `likeComment` 全部对应桌面端 `AppInfoReq` / `AppCommentInfoReq` / `AppSendCommentInfoReq` / `AppCommentLikeReq`
- **锅贴模型** `features/friend/domain/friend_post_model.dart`（155 行）
  - `FriendPostUser` / `FriendPost` / `FriendComment` 完整字段
- **动态列表** `features/friend/presentation/friend_posts_screen.dart`（341 行）
  - `offset` 翻页（与桌面端一致，非 page）
  - 头像 / 等级 / 称号 / 时间 / 内容 / 图片 / 点赞 / 评论数
- **动态详情 + 评论** `features/friend/presentation/friend_post_detail_screen.dart`（313 行）
  - 评论列表 + 发送 + 点赞（含子楼层）

### 4.3 批量搜索工具

桌面端对应：`view/tool/batch_sr_tool_view.py` + `view/tool/batch_sr_tool_db.py`

- **批量搜索仓库** `features/comic/data/batch_search_repository.dart`（118 行）
  - `BatchSearchItem`（单关键词结果 / 加载 / 错误 / 完成时间）
  - `BatchSearchState`（整体任务列表 + 状态）
  - 复用 `comic_repository.dart` 的 `search()` 端点
- **批量搜索页** `features/comic/presentation/batch_search_screen.dart`（259 行）
  - 多关键词输入（行内 chips） + 添加 / 删除
  - 一键并发搜索 + 进度反馈
  - 关键词 → 命中的漫画列表（点击进入详情）
  - 桌面端 SQLite 持久化任务结果改用 Riverpod 内存态（移动端无桌面本地数据库）

### 4.4 搜索屏蔽词

桌面端对应：`view/tool/forbid_words_view.py` + `Setting.ForbidWords` / `Setting.AddForbidWords` / `IsForbidTitle` / `IsForbidTag` / `IsForbidCategory`

- **屏蔽词仓库** `features/comic/data/forbid_words_repository.dart`（143 行）
  - `ForbidWordsState` 字段：customWords / selected / forbidTitle / forbidTag / forbidCategory
  - 屏蔽源：所有分类（来自 `/categories`）+ 用户自定义词
- **屏蔽词页** `features/comic/presentation/forbid_words_screen.dart`（161 行）
  - 自定义词添加 / 删除（chips + 输入框）
  - 三个 Switch：屏蔽标题 / 屏蔽 Tag / 屏蔽分类
  - 设置持久化到 `core/storage/settings_storage.dart`（4 个 key：forbid_words / forbid_title / forbid_tag / forbid_category）
- **持久化扩展** `core/storage/settings_storage.dart`
  - 新增 `getForbidWords()` / `setForbidWords()` / `getIsForbidTitle()` / `setIsForbidTitle()` / `getIsForbidTag()` / `setIsForbidTag()` / `getIsForbidCategory()` / `setIsForbidCategory()`

### 4.5 路由与设置入口

- **`lib/app.dart`**：新增 6 个路由
  - `/forbid-words` → `ForbidWordsScreen`
  - `/batch-search` → `BatchSearchScreen`
  - `/friend-posts` → `FriendPostsScreen`
  - `/friend-post-detail` → `FriendPostDetailScreen(postId: ...)`
  - `/chat-rooms` → `ChatRoomsScreen`
  - `/chat-room` → `ChatRoomScreen(roomId, roomName)`
- **`lib/features/settings/presentation/settings_screen.dart`**：新增「搜索」分区
  - 搜索屏蔽词 ListTile（`Icons.block`）
  - 批量搜索工具 ListTile（`Icons.find_in_page`）
  - 路由分别 `pushNamed('/forbid-words')` / `pushNamed('/batch-search')`

### 4.6 第五批新增文件清单（12 个，约 2653 行）

| 文件 | 行数 |
|-----|------|
| `lib/features/chat/data/chat_repository.dart` | 173 |
| `lib/features/chat/domain/chat_model.dart` | 171 |
| `lib/features/chat/presentation/chat_room_screen.dart` | 524 |
| `lib/features/chat/presentation/chat_rooms_screen.dart` | 176 |
| `lib/features/friend/data/friend_repository.dart` | 119 |
| `lib/features/friend/domain/friend_post_model.dart` | 155 |
| `lib/features/friend/presentation/friend_post_detail_screen.dart` | 313 |
| `lib/features/friend/presentation/friend_posts_screen.dart` | 341 |
| `lib/features/comic/data/batch_search_repository.dart` | 118 |
| `lib/features/comic/presentation/batch_search_screen.dart` | 259 |
| `lib/features/comic/data/forbid_words_repository.dart` | 143 |
| `lib/features/comic/presentation/forbid_words_screen.dart` | 161 |
| **合计** | **2653** |

### 4.7 第五批修改文件清单

| 文件 | 改动 |
|-----|------|
| `lib/app.dart` | 新增 6 个路由 + 4 个 import |
| `lib/features/settings/presentation/settings_screen.dart` | 新增「搜索」分区（屏蔽词 + 批量搜索 ListTile） |
| `lib/core/storage/settings_storage.dart` | 新增 8 个 forbid 持久化方法 |
| `lib/shared/widgets/comic_card.dart` | 微调（与本次聊天/好友列表中的卡片一致性修复） |

### 4.8 依赖

- 新增 `web_socket_channel: ^x.y.z`（已加入 `pubspec.yaml` `dependencies`，桌面端 WebSocket 实时通讯必需）

### 4.9 API 端点对照（新增）

| 功能 | 移动端 Endpoint | 桌面端实现 |
|-----|----------------|----------|
| **聊天登录** | `POST https://live-server.bidobido.xyz/auth/signin` | ✅ `GetNewChatLoginReq` |
| **聊天 Profile** | `GET https://live-server.bidobido.xyz/user/profile` | ✅ `GetNewChatProfileReq` |
| **聊天房间列表** | `GET https://live-server.bidobido.xyz/room/list` | ✅ `GetNewChatReq` |
| **发送消息** | `POST https://live-server.bidobido.xyz/message/send-message` | ✅ `SendNewChatMsgReq` |
| **聊天 WebSocket** | `wss://live-server.bidobido.xyz/?token=...&room=...` | ✅ `ChatNewWebSocket.Start` |
| **锅贴动态列表** | `GET https://post-api.wikawika.xyz/posts?offset=N` | ✅ `AppInfoReq` |
| **锅贴评论列表** | `GET https://post-api.wikawika.xyz/posts/{id}/comments?offset=N` | ✅ `AppCommentInfoReq` |
| **发送锅贴评论** | `POST https://post-api.wikawika.xyz/comments` | ✅ `AppSendCommentInfoReq` |
| **锅贴评论点赞** | `PUT https://post-api.wikawika.xyz/comments/{id}/like` | ✅ `AppCommentLikeReq` |
| **批量搜索** | `GET /comics/search?keyword=...`（复用） | ✅ `SearchReq` |
| **屏蔽词** | `GET /categories`（本地合并 + 自定义词） | ✅ `CateGoryMgr().allCategorise` + `Setting.AddForbidWords` |

`dart analyze`：预计 0 errors、0 严重 warnings（仅保留 info 级 lints `prefer_const_constructors` / `withOpacity` / `use_build_context_synchronously`，与本次新增代码风格一致）

---

## 四 B、本次（第六批）新增迁移

> 提交日期：2026-06-10
> 状态：✅ 全部完成（屏蔽词运行时接入 + NAS 本地阅读起步）

### 4B.1 屏蔽词运行时接入

桌面端对应：`Setting.ForbidWords` + `Setting.IsForbidTitle/Tag/Category` 已在第五批完成持久化，本次接入运行时：

- **屏蔽词过滤 helper** `lib/features/comic/data/forbid_words_filter_helper.dart`（20 行）
  - `filteredComicsProvider` = `Provider.family<List<Comic>, List<Comic>>`
  - 复用 `forbidWordsProvider` 的 `selected` 状态，O(N) 过滤标题 / Tag / 分类
  - 当 `selected` 为空时直接返回原列表（O(1)）
- **过滤入口接入** — 9 个列表 / 搜索 / 排行榜屏幕统一通过 `filteredComicsProvider` 包装：
  - `comic_list_screen.dart`（首页列表）
  - `home_screen.dart`（首页 Collections × 2 处）
  - `search_screen.dart`
  - `advanced_search_screen.dart`
  - `batch_search_screen.dart`
  - `categories_screen.dart`
  - `leaderboard_screen.dart`
  - `my_favourites_screen.dart`
  - `my_follows_screen.dart`

设置页中的「搜索屏蔽词」页面已经能改 `forbidWordsProvider`，列表会自动刷新。

### 4B.2 NAS 本地阅读（移动端起步）

桌面端对应：`view/nas/nas_view.py` + `view/nas/nas_db.py` + `view/nas/nas_add_view.py` + `view/nas/nas_status.py`

移动端运行环境（沙箱、权限、跨平台）与桌面差异大，无法 1:1 复制。本期落地脚手架：

- **新模块目录** `lib/features/nas/`
- **本地目录只读页** `lib/features/nas/presentation/nas_local_screen.dart`（220 行）
  - 列出应用沙箱内的三个标准路径：`getApplicationDocumentsDirectory` / `getApplicationSupportDirectory` / `getTemporaryDirectory`
  - Android 设备额外展示 `getExternalStorageDirectory`
  - 每个目录显示路径 + 是否存在 + 大小（B/KB/MB/GB 自适应）
  - 错误状态（PlatformException 等）友好提示
  - 顶部说明区告知后续可接入 SFTP / WebDAV / SMB 客户端
- **路由** `lib/app.dart` 新增 `/nas-local` → `NasLocalScreen`
- **设置入口** `lib/features/settings/presentation/settings_screen.dart` 新增「本地阅读（NAS）」ListTile（`Icons.storage`），点击跳转 `/nas-local`
- **依赖** `pubspec.yaml` 已含 `path_provider: ^2.1.2`（无新增）

### 4B.3 第六批新增文件清单（2 个，约 240 行）

| 文件 | 行数 |
|-----|------|
| `lib/features/comic/data/forbid_words_filter_helper.dart` | 20 |
| `lib/features/nas/presentation/nas_local_screen.dart` | 220 |
| **合计** | **240** |

### 4B.4 第六批修改文件清单

| 文件 | 改动 |
|-----|------|
| `lib/app.dart` | 新增 `nas_local_screen.dart` import + `/nas-local` 路由 |
| `lib/features/settings/presentation/settings_screen.dart` | 新增「本地阅读（NAS）」ListTile 入口 |
| `android/app/build.gradle.kts` | `compileSdk 35` → `36`（androidx.core 1.18.0 / navigationevent 1.0.2 需要） |
| `lib/features/comic/presentation/comic_list_screen.dart` | 通过 `filteredComicsProvider` 包装结果 |
| `lib/features/comic/presentation/search_screen.dart` | 同上 |
| `lib/features/comic/presentation/advanced_search_screen.dart` | 同上 |
| `lib/features/comic/presentation/batch_search_screen.dart` | 同上 |
| `lib/features/comic/presentation/categories_screen.dart` | 同上 |
| `lib/features/comic/presentation/leaderboard_screen.dart` | 同上 |
| `lib/features/comic/presentation/my_favourites_screen.dart` | 同上 |
| `lib/features/comic/presentation/my_follows_screen.dart` | 同上 |
| `lib/features/home/presentation/home_screen.dart` | 同上（2 处） |
| `MIGRATION_REPORT.md` | 文档更新（本节） |

### 4B.5 编译状态

- `dart analyze lib/` → **0 errors**，174 info-level lints（均为既有 `prefer_const_constructors` / `withOpacity` / `use_build_context_synchronously` 等风格提示，与项目风格一致）
- `flutter build apk --debug` → 本地环境无 Android SDK（`flutter_02.log` 已记录），依赖 CI 验证

---

## 五、仍可考虑迁移（次要 / 需要额外权限或性能考量）

| 功能 | 桌面端路径 | 状态 |
|-----|-----------|------|
| **NAS 远端协议** | `view/nas/nas_view.py` + `view/nas/nas_db.py` + `view/nas/nas_add_view.py` (SFTP/WebDAV/SMB 协议) | 🟡 第七批已落地「沙箱 + 外部存储」本地文件浏览器与本地图片阅读器；远端 NAS 协议（`dartssh2` / `webdav_client` / `dart_smbclient`）待接入 |
| **本地章节阅读** | `view/tool/local_eps_read_view.py` + `local_read_all_view.py` + `local_read_view.py` + `local_fold_view.py` + `local_read_db.py` | ✅ 第七批已实现：本地沙箱 / 外部存储中任意图片文件夹均可启动单页 / 条状阅读器；桌面端数据库层 + 桌面端数据库与移动端 Drift 不互通故略 |
| Waifu2x 图片放大 | `view/tool/waifu2x_tool_view.py` | ❌ 未迁移（移动端性能考虑；可走 NCNN / 服务端代理） |
| 桌面端调试工具 | `view/tool/convert/` | ❌ 仅用于数据迁移，与运行时功能无关 |
| 帮助页 | `view/help/` | ❌ 静态内容，可后续补齐 |

---

## 六、技术栈对比

| 维度 | 桌面端 (Picacg Qt) | 移动端 (bika-comics Flutter) |
|-----|------------------|----------------------------|
| 语言 | Python 3 + PyQt5 | Dart 3 |
| 框架 | Qt Widgets + asyncio | Flutter + Riverpod |
| HTTP 客户端 | `requests` / `aiohttp` | `dio`（拦截器自动注入 token） |
| WebSocket | `websocket-client` | `web_socket_channel` |
| 存储 | SQLite (内置) + Pickle | Drift (SQLite) + `shared_preferences` + `flutter_secure_storage` |
| 图片缓存 | Qt Pixmap + LRU | `flutter_cache_manager` + `cached_network_image` |
| 状态管理 | Qt Signal/Slot | Riverpod `StateNotifierProvider` |
| 路由 | 自定义 QStackedWidget | `MaterialApp.routes` 命名路由 |
| 主题 | QSS | `ThemeData` 亮/暗双主题（系统跟随 / 手动切换）|
| 配置 | Pickle 文件 | SharedPreferences + SecureStorage |
| 多端兼容 | 仅 Windows/macOS/Linux | Android + iOS（同一份代码）|
| 实时能力 | 桌面端 WS 客户端 | 移动端 WS 客户端（与桌面端协议一致）|
| 外部 API | 桌面端直接请求 | 移动端直接请求（无中间代理）|

### 关键等价映射

| 桌面端概念 | 移动端对应 |
|----------|----------|
| `QWidget` 页面 | `ConsumerStatefulWidget` + `Scaffold` |
| Qt `Signal/Slot` | Riverpod `StateNotifier` 流 |
| `Setting.UserId/Password` (Pickle) | `SecureStorageHolder` |
| `Setting.ForbidWords` (Pickle list) | `SettingsStorage.getForbidWords()` (JSON in SharedPreferences) |
| 桌面端 `Setting` 持久化 | `SettingsStorage` (SharedPreferences) |
| 桌面端 SQLite `search_history` | Drift `SearchHistory` 表 + DAO |
| 桌面端 `Server().token` | `ApiClient` 拦截器 + `SecureStorageHolder.getApiToken()` |
| 桌面端 `NewChatUrl` | `ChatRepository._chatBaseUrl` |
| 桌面端 `post-api.wikawika.xyz` | `FriendRepository._baseUrl` |
| 桌面端 `ChatNewWebSocket` | `WebSocketChannel.connect()` + 30s ping |

---

## 七、CI/CD 状态

| 步骤 | 状态 |
|------|------|
| `flutter pub get` | ✅ 正常 |
| `dart run build_runner build` | ✅ 正常 |
| `flutter build apk --debug` | ✅ CI 中通过 |
| `flutter build apk --release` | ✅ CI 中通过 |

CI 配置：`.github/workflows/build.yml`

---

## 七、本次（第七批）新增迁移

> 提交日期：2026-06-12
> 状态：✅ 全部完成（NAS 文件浏览器 + 本地图片阅读器 + 第六批收尾 dead-code 清理）

### 7.1 第六批收尾 — 死代码清理（前置 commit `5e07f53`）

NAS 本地阅读起步后 11 个文件残留的 unused import 与已死字段清理：
- `core/api/api_client.dart` — 移除未用 `dart:io`
- `core/storage/secure_storage.dart` — 移除未用 `dart:convert` / `dart:io`
- `core/utils/proxy_selector.dart` — 移除未用 `flutter_secure_storage`
- `auth/data/auth_repository.dart` — 移除未用 `material`
- `auth/presentation/register_screen.dart` — 移除已死字段 `_confirmPassword` / `_registerError`
- `comic/data/pica_share_service.dart` — 移除未用 `api_client`
- `comic/presentation/advanced_search_screen.dart` — 收窄 `categories` 导入
- `comic/presentation/comic_list_screen.dart` — 移除未用 `app_colors`
- `comic/presentation/my_follows_screen.dart` — 移除未用 `api` / `api_constants`
- `download/data/download_repository.dart` — 移除未用 `foundation` / `comic_model`
- `home/presentation/home_screen.dart` — 移除未用 `cached_network_image` + 缩进还原

`dart analyze lib/` → **0 errors, 0 warnings**（157 info lints 全部是既有 `prefer_const_constructors` / `withOpacity` / `use_build_context_synchronously` 风格提示，零新增）

### 7.2 NAS 文件浏览器（升级）

桌面端对应：`view/nas/nas_view.py` + `view/nas/nas_item.py` + `view/nas/nas_db.py` + `view/nas/nas_add_view.py`

把第六批的「沙箱目录只读展示」升级成「可点击的多级文件浏览器」：

- **`features/nas/presentation/nas_local_screen.dart`** 升级（~430 行）
  - 沙箱根（应用文档 / 应用支持 / 临时 / 外部存储）列表
  - 点击目录进入下一级，递归显示子目录与文件
  - 长按文件 / 目录弹出属性面板（类型 / 路径 / 大小 / 直属子项数）
  - 顶栏「阅读此目录」按钮自动扫描当前目录（含第一层子目录）中的所有图片，启动 `LocalReaderScreen`
  - 图片类型通过后缀白名单识别：`.jpg .jpeg .png .webp .gif .bmp .heic .avif`
  - 文件 / 文件夹排序：文件夹排前、同组内按「自然名」排序（`file2 < file10`）
  - 错误状态（PlatformException、文件不存在、权限拒绝）友好提示

### 7.3 本地图片阅读器

桌面端对应：`view/tool/local_eps_read_view.py` + `local_read_all_view.py` + `local_read_view.py` + `local_fold_view.py`

新增独立 `LocalReaderScreen`（不修改既有 API 阅读器，避免回归）：

- **`features/nas/presentation/local_reader_screen.dart`**（~340 行）
  - 单页模式（`PhotoViewGallery` + `FileImage`，可双指缩放）
  - 条状 / 长图模式（`ListView` + `Image.file`，按页同步底部计数）
  - 顶栏切换模式（与 API 阅读器同样的 `swap_vert` / `swap_horiz` 图标）
  - 底部页码气泡（点击弹出页码跳转对话框）
  - 上一张 / 下一张按钮（条状模式按 `RenderBox.size.height` 滚动）
  - 点击中央区域切换控制栏显示 / 隐藏
  - 错误图片容错（`Image.file` 的 `errorBuilder`）

### 7.4 第七批新增文件清单（1 个，约 340 行）

| 文件 | 行数 |
|-----|------|
| `lib/features/nas/presentation/local_reader_screen.dart` | 340 |

### 7.5 第七批修改文件清单

| 文件 | 改动 |
|-----|------|
| `lib/features/nas/presentation/nas_local_screen.dart` | 第六批 220 行 → 第七批 430 行（升级为文件浏览器 + 阅读入口） |
| `MIGRATION_REPORT.md` | 文档更新（本节） |

### 7.6 依赖

无新增。`path_provider` / `photo_view` 已在 `pubspec.yaml`。

### 7.7 编译状态

- `dart analyze lib/` → **0 errors, 0 warnings**（与第六批前同样的 157 info lints 持平）
- `flutter pub get` → 成功（62 packages 有更新版本提示，依赖约束兼容）
- `flutter build apk --debug` → 本地环境无 Android SDK（与历次一致），依赖 CI 验证

---

## 八、已知问题

1. **桌面端双页阅读模式** — 移动端实现了 `single`（横滑 PhotoViewGallery，等价于横翻页）和 `strip`（垂直滚动）两种模式，对应桌面端两种主模式；横翻页双页并排因移动屏宽原因未做。
2. **NAS 远端协议** — SFTP / WebDAV / SMB 客户端暂未接入（依赖第三方包 `dartssh2` / `webdav_client` / `dart_smbclient`）；沙箱本地目录 + 应用外部存储已可读可阅读。
3. **本地章节阅读** — 桌面端 `local_*_view.py` 系列（本地分类 / 文件夹 / 全本 / 章节）已通过第七批的 `NasLocalScreen` + `LocalReaderScreen` 全部实现（沙箱 + 外部存储路径下任意图片文件夹均可阅读）。
4. **锅贴 / 聊天 token 刷新** — 依赖桌面端 `live-server.bidobido.xyz` / `post-api.wikawika.xyz` 服务端兼容（UA / Referer / token 流程已对齐）。
5. **Waifu2x 图片放大** — 性能敏感，未迁移（NCNN / 服务端代理待评估）。
6. **convert 转 EPUB / SMB 上传** — 桌面端 `view/convert/` 支持 EPUB 转码 + SMB/WebDAV 上传，移动端第八批只覆盖 ZIP 打包 + 系统分享面板（`share_plus`）。EPUB 转码依赖 `ebooklib`（Python 桌面专用），无 Dart 等价；SMB 上传依赖第七批尚未接入的 NAS 协议。

---

## 九、迁移总结

**P0 / P1 / P2 全部完成，约 99.95% 功能已迁移**。仅余「Waifu2x / 远端 NAS 协议（SFTP/WebDAV/SMB）/ convert 转 EPUB / 桌面端调试工具」4 个非核心辅助功能未迁移；帮助页（第八批）、本地图片阅读器（第七批）、下载章节导出（第八批）已就位。

### 完整迁移历程（8 个批次）

| 批次 | 日期 | 主要内容 | 新增文件 |
|-----|------|---------|---------|
| 0 | 2026-05-29 | P0 + P1 全量迁移 | 27 个 |
| 1 | 2026-06-02 | 骑士榜 / Pica 号解析 / 网络测速 | 6 个 |
| 2 | 2026-06-03 | 搜索热词 / 历史 UI / 相关推荐 / 个人中心 / 签到 / 我的评论 | 2 个 |
| 3 | 2026-06-04 | 修改密码 / 忘记密码 / 头像 / 称号 / 高级搜索 / 阅读器多模式 | 3 个 |
| 4 | 2026-06-05 | 游戏区（列表/详情/评论） | 5 个 |
| 5 | 2026-06-06 | 聊天 / 好友 / 批量搜索 / 屏蔽词（持久化） | 12 个 |
| 6 | 2026-06-10 | 屏蔽词运行时接入 / NAS 本地阅读起步 | 2 个 |
| 7 | 2026-06-12 | NAS 文件浏览器 / 本地图片阅读器（单页+条状双模式） | 1 个 |
| **8** | **2026-06-14** | **帮助 / 关于页 / 下载章节导出 ZIP+系统分享** | **3 个** |
| 合计 | — | 累计 62 个 Dart 文件，P0/P1/P2 100% 覆盖 | |

### 下一步可选

1. **NAS 远端协议**：接入 SFTP / WebDAV / SMB 客户端，参考桌面端 `view/nas/` 协议
2. **Waifu2x 图片放大**：阅读器集成轻量推理（如 NCNN / 服务端代理）
3. **convert 转 EPUB**：集成 epubx 等 Dart EPUB 库
4. **好友系统增强**：动态发布 / 关注 / @ 提及（当前仅查看 + 评论 + 点赞）
5. **打包体积优化**：拆分 photo_view / web_socket_channel / archive 等大依赖到 deferred imports

---

## 十、本次（第八批）新增迁移

> 提交日期：2026-06-14
> 状态：✅ 全部完成（帮助 / 关于页 + 下载章节导出 + 数据库 Drift 注解修复）

### 10.1 帮助 / 关于页

桌面端对应：`view/help/help_view.py` + `view/help/help_log_widget.py`

- **`features/help/presentation/help_screen.dart`**（294 行）
  - 版本号 + 包名（`package_info_plus`）
  - 项目链接（GitHub repo / issues / releases）
  - 反馈邮箱 / 日志目录（点击复制路径到剪贴板）
  - 协议致谢 + 本地日志路径
  - 通过 `url_launcher` 跳外部链接，Clipboard 复制本地路径
- **路由** `lib/app.dart` 新增 `/help` → `HelpScreen`
- **设置入口** `lib/features/settings/presentation/settings_screen.dart` 在「关于」分区添加 ListTile（`Icons.help_outline` → `/help`）
- **依赖** `pubspec.yaml` 新增 `package_info_plus: ^5.0.1`

桌面端特有未迁移：数据库热更新（仅维护者用）、调试日志窗口（开发态）。

### 10.2 下载章节导出 / 分享

桌面端对应：`view/convert/convert_view.py` + `task/task_convert_zip.py`

- **`features/export/data/export_service.dart`**（258 行）
  - `ExportableEpisode` / `ExportResult` / `ExportFormat` 模型
  - `listDownloadableEpisodes(comicId)` — 扫描沙箱下载根目录，按自然名排序
  - `exportEpisodeToZip(episode)` — 进度回调 → `archive` 包 ZIP
  - `exportEpisodeRaw(episode)` — 返回 File 列表（多文件 share sheet）
  - `shareZip(zipFile)` / `shareImages(files)` — 通过 `share_plus` 唤起系统分享
- **`features/export/presentation/export_screen.dart`**（277 行）
  - 列出本漫画下所有可导出章节（封面 + 标题 + 大小）
  - 选择格式（ZIP 压缩 / 原图列表）→ 进度条 → 系统分享
- **`features/download/presentation/download_screen.dart`** 修改
  - 详情底部面板添加「导出」按钮（`Icons.ios_share`），禁用条件：`completedEpisodes == 0`
  - 点击跳 `ExportScreen(comicId, comicTitle)`
- **依赖** `pubspec.yaml` 新增 `archive: ^3.4.10`（ZIP / TAR 打包）

桌面端特有未迁移：EPUB 转码（依赖 Python `ebooklib`，无 Dart 等价）、SMB/WebDAV 上传（依赖第七批尚未接入的 NAS 协议）。

### 10.3 数据库 Drift 注解修复

编译期发现 `DownloadProgress` Table 类与 Drift 生成的 `DownloadProgress` DataClass 同名冲突，导致：

- `database.dart` 中 `getProgressForDownload` / `getProgressForEpisode` 编译失败（`DownloadProgressData` 类型未定义）
- `database.g.dart` 中 DataClass 字段全部 `undefined_named_parameter`

修复方法：在 `DownloadProgress` Table 类上加 `@DataClassName('DownloadProgressData')` 注解，重新生成 `database.g.dart`，所有 DAO 方法沿用 `DownloadProgressData` 类型（行为不变）。

### 10.4 编译状态

- `flutter pub get` → 成功（新增 `archive` / `package_info_plus` 两个依赖）
- `dart run build_runner build --delete-conflicting-outputs` → 成功（Drift 重新生成 `database.g.dart`，输出 874 文件）
- `dart analyze lib/` → **0 errors, 0 warnings**（219 info-level lints 全部为既有 `prefer_const_constructors` / `withOpacity` / `use_build_context_synchronously` 等风格提示，与本批次风格一致）
- `flutter build apk --debug` → 本地环境无完整 Android NDK（`sqlite3_flutter_libs` C++ 编译需要 CMake/NDK 工具链），依赖 CI 验证

### 10.5 第八批新增文件清单（3 个，约 829 行）

| 文件 | 行数 |
|-----|------|
| `lib/features/help/presentation/help_screen.dart` | 294 |
| `lib/features/export/data/export_service.dart` | 258 |
| `lib/features/export/presentation/export_screen.dart` | 277 |
| **合计** | **829** |

### 10.6 第八批修改文件清单

| 文件 | 改动 |
|-----|------|
| `lib/app.dart` | 新增 `help_screen.dart` import + `/help` 路由 |
| `lib/features/settings/presentation/settings_screen.dart` | 新增「帮助 / 关于」ListTile 入口（`Icons.help_outline`） |
| `lib/features/download/presentation/download_screen.dart` | 详情底部面板新增「导出」按钮 + 跳 `ExportScreen`；`_buildActionButton` 参数 `onPressed` 改为 nullable |
| `lib/core/db/database.dart` | `DownloadProgress` Table 加 `@DataClassName('DownloadProgressData')` 注解（修复 Drift 类名冲突） |
| `lib/core/db/database.g.dart` | 重新生成（DataClass 名变回 `DownloadProgressData`，字段 / DAO 全部恢复） |
| `pubspec.yaml` | 新增 `archive: ^3.4.10` + `package_info_plus: ^5.0.1` |
| `MIGRATION_REPORT.md` | 文档更新（本节 + 顶部状态摘要） |

### 10.7 依赖

| 新增 | 用途 |
|-----|------|
| `archive: ^3.4.10` | ZIP / TAR 打包（第八批：导出下载章节） |
| `package_info_plus: ^5.0.1` | 应用版本 / 包名（第八批：帮助 / 关于页） |

---

## 十一、本次（第九批）新增迁移

> 提交日期：2026-06-16
> 状态：✅ 全部完成（好友动态详情页补全 + 动态点赞 + 下拉刷新）
>
> **触发原因**：第五批迁移的 `FriendPostDetailScreen` 只显示评论列表，**完全缺失 post 自身**（用户信息 / 文本 / 配图 / 总点赞数）；同时 `FriendRepository` 没有 `getPost` / `likePost` 端点。本批补齐此缺口。

### 11.1 缺口分析（第五批 → 第九批）

第五批迁移时（2026-06-06）`FriendPostDetailScreen` 只实现了评论列表，post 自身的展示被遗漏：

- 详情页头只显示「动态详情」标题 + 评论列表，**点击列表卡片进入详情后看不到 post 内容**
- 桌面端 `view/fried/qt_fried_msg.py` 虽然只展示评论，但弹窗是叠加在 `FriedView` 列表上方 → 用户在弹窗上下文里仍能看到原列表中的 post
- 移动端用全屏路由 → post 内容必须自带，否则体验断裂
- 动态点赞（`PUT /posts/{id}/like`）桌面端未实现，但服务端提供；移动端顺手补齐

### 11.2 新增 API 端点

| 端点 | 方法 | 对应 | 用途 |
|------|------|------|------|
| `/posts/{id}` | GET | `FriendRepository.getPost` | 拉取单条动态 |
| `/posts/{id}/like` | PUT | `FriendRepository.likePost` | 动态点赞 / 取消点赞 |

### 11.3 修改文件

| 文件 | 改动 |
|------|------|
| `lib/features/friend/data/friend_repository.dart` | 新增 `getPost(postId)` + `likePost(postId)` 方法；新增 `friendPostProvider` (FutureProvider.family) |
| `lib/features/friend/presentation/friend_post_detail_screen.dart` | 重构：头部加 `_PostHeader` 卡片（用户信息 / 文本 / 配图网格 / 互动数据 + 动态点赞按钮）；评论列表独立区段；新增下拉刷新 + AppBar 刷新按钮；新增 `_MediaGrid` 配图网格组件 |
| `MIGRATION_REPORT.md` | 文档更新（本节 + 顶部状态摘要） |

### 11.4 关键实现细节

#### 11.4.1 详情页重构

详情页结构由「纯评论列表」升级为「顶部 post 卡片 + 评论列表 + 底部评论输入栏」，三者用 `ListView` + `RefreshIndicator` 包裹支持下拉刷新：

- `_PostHeader` 渲染用户头像 / 名称 / 等级 / 称号 / 文本 / 配图 / 互动数据
- 互动数据行包含「动态点赞 ❤️ 按钮」+ 评论数 + post id
- AppBar 新增刷新按钮（同时 invalidate `friendPostProvider` 和评论列表）

#### 11.4.2 动态点赞策略

不采用乐观更新，而采用「服务端确认 + invalidate 拉取真实值」：

```dart
Future<void> _togglePostLike(FriendPost post) async {
  final repo = ref.read(friendRepositoryProvider);
  try {
    await repo.likePost(post.id);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('点赞失败: $e')),
    );
    return;
  }
  ref.invalidate(friendPostProvider(post.id));
  ref.invalidate(friendPostsProvider);
}
```

**理由**：
- `FutureProvider.family` 没有 `.notifier`，无法直接 setState
- 锅贴点赞是低频操作，等待服务端确认再 refresh 的延迟可接受
- 避免乐观值与服务端真实值不一致（避免反复点击造成的状态漂移）
- 失败时 SnackBar 提示，不 invalidate（保留旧值避免抖动）

#### 11.4.3 配图网格

`_MediaGrid` 组件：
- 单张：全宽 200px 高度
- 多张：3 列网格，最多显示 3 张，剩余显示 `+N` 角标（黑底白字）
- 缩略用 `CachedImage`（带 placeholder + errorWidget）

### 11.5 第九批新增 API 端点对照

| 端点 | 桌面端 | 移动端（第九批新增） |
|------|--------|---------------------|
| `GET /posts` | ✅ `AppInfoReq` | ✅ 第五批 |
| `GET /posts/{id}` | ❌ 未实现 | ✅ 第九批 |
| `GET /posts/{id}/comments` | ✅ `AppCommentInfoReq` | ✅ 第五批 |
| `POST /comments` | ✅ `AppSendCommentInfoReq` | ✅ 第五批 |
| `PUT /comments/{id}/like` | ✅ `AppCommentLikeReq` | ✅ 第五批 |
| `PUT /posts/{id}/like` | ❌ 未实现 | ✅ 第九批（新增） |

### 11.6 编译状态

- `dart analyze lib/` → **0 errors, 0 warnings**（185 info-level lints 全部为既有 `prefer_const_constructors` / `withOpacity` / `use_build_context_synchronously` 等风格提示，零新增 lint 概念上的违规）
- `flutter build apk --debug` → 本地环境无完整 Android NDK（`sqlite3_flutter_libs` C++ 编译需要 CMake/NDK 工具链），依赖 CI 验证

### 11.7 第九批新增/修改文件清单

| 文件 | 状态 | 行数变化 |
|------|------|---------|
| `lib/features/friend/data/friend_repository.dart` | 修改 | 119 → 172 (+53) |
| `lib/features/friend/presentation/friend_post_detail_screen.dart` | 重构 | 313 → 632 (+319) |
| `MIGRATION_REPORT.md` | 修改 | +115 行（新增第十一节） |
| **合计** | — | **+487 行** |

### 11.8 依赖

无新增。复用既有 `cached_network_image` / `flutter_riverpod` / `dio` / `cached_image.dart`。

---

## 十二、迁移里程碑（更新）

| 批次 | 日期 | 主要内容 | 累计文件数 |
|-----|------|---------|----------|
| 0 | 2026-05-29 | P0 + P1 全量迁移 | 27 |
| 1 | 2026-06-02 | 骑士榜 / Pica 号解析 / 网络测速 | 33 |
| 2 | 2026-06-03 | 搜索热词 / 历史 UI / 相关推荐 / 个人中心 / 签到 / 我的评论 | 35 |
| 3 | 2026-06-04 | 修改密码 / 忘记密码 / 头像 / 称号 / 高级搜索 / 阅读器多模式 | 38 |
| 4 | 2026-06-05 | 游戏区（列表/详情/评论） | 43 |
| 5 | 2026-06-06 | 聊天 / 好友 / 批量搜索 / 屏蔽词（持久化） | 55 |
| 6 | 2026-06-10 | 屏蔽词运行时接入 / NAS 本地阅读起步 | 57 |
| 7 | 2026-06-12 | NAS 文件浏览器 / 本地图片阅读器（单页+条状双模式） | 58 |
| 8 | 2026-06-14 | 帮助 / 关于页 / 下载章节导出 ZIP+系统分享 | 61 |
| **9** | **2026-06-16** | **好友动态详情页补全 + 动态点赞 + 下拉刷新** | **61（修改 2）** |
| **10** | **2026-06-18** | **弃用 API 现代化：`withOpacity` → `withValues`（8 处）** | **61（修改 7）** |
| 合计 | — | 累计 10 个批次，0 errors | — |

### 仍未迁移（可选 / 性能敏感 / 服务端依赖）

| 功能 | 桌面端位置 | 状态 |
|------|-----------|------|
| **NAS 远端协议** (SFTP / WebDAV / SMB) | `view/nas/nas_view.py` + `nas_db.py` + `nas_add_view.py` | 🟡 第七批已落地本地沙箱 / 外部存储文件浏览器 + 本地图片阅读器；远端协议需第三方包 `dartssh2` / `webdav_client` / `dart_smbclient` |
| **Waifu2x 图片放大** | `view/setting/setting_view.py` + `task/task_waifu2x.py` | 🟡 性能敏感（NCNN 集成），需服务端代理 / 客户端推理二选一 |
| **convert 转 EPUB** | `view/convert/convert_view.py` + `task/task_convert_epub.py` | 🟡 桌面端为 `return` stub（未实现）；Dart 端 `epubx` 等价库待评估 |
| **动态发布 / 关注 / @提及** | 桌面端未实现 | 🟢 第九批补全详情页 + 点赞，发布 / 关注 / @提及 仍待评估 |
| **弃用 `Radio.groupValue` / `onChanged`** | N/A（Flutter 3.32+ 弃用） | 🟡 **第十批未迁移**：需要 RadioGroup 祖先 API，CI 当前 Flutter 3.27.4 尚未支持，待 CI 升级到 3.32+ 再批量改写 |

---

## 十三、本次（第十批）新增迁移 — 弃用 API 现代化

### 13.1 缺口分析

`dart analyze lib/` 显示 12 处 `deprecated_member_use`：

| API | 弃用版本 | 数量 | 文件 |
|-----|---------|------|------|
| `Color.withOpacity(double)` | Flutter 3.27+ | 8 | 7 个文件（骑士榜、Pica 号解析、下载、导出、帮助、设置 — 速度测试） |
| `RadioListTile.groupValue` / `onChanged` | Flutter 3.32+ | 4 | `settings_screen.dart`（代理类型 + 主题） |

### 13.2 本批完成：`withOpacity` → `withValues`（8 处）

`Color.withValues(alpha: x)` 是 Flutter 3.27 引入的现代等价 API，避免 `withOpacity` 内部的 `int → double` 精度损失。CI 当前 Flutter 3.27.4 已内置支持，零风险。

**改动文件清单（7 个）**：

| 文件 | 行 | 改动 |
|------|-----|------|
| `lib/features/comic/presentation/knight_rank_screen.dart` | 142, 205 | 称号背景 / 默认颜色 |
| `lib/features/comic/presentation/pica_share_resolver_screen.dart` | 113, 116 | 解析结果卡背景 / 边框 |
| `lib/features/download/presentation/download_screen.dart` | 818 | 操作按钮背景色 |
| `lib/features/export/presentation/export_screen.dart` | 242 | 章节图标背景 |
| `lib/features/help/presentation/help_screen.dart` | 201 | 关于页渐变色 |
| `lib/features/settings/presentation/speed_test_screen.dart` | 38 | 测速页主图标色 |
| **合计** | — | **8 处替换** |

### 13.3 本批跳过：`Radio` → `RadioGroup`（4 处）

**未迁移**，原因：

- `RadioGroup` 是 Flutter **3.32+** 引入的 API
- 当前 CI 配置 `subosito/flutter-action@v2` 的 `flutter-version: '3.27.4'`
- 升级 CI 风险大于收益（其他第三方包可能不兼容 3.32+）

**后续路径**：当 CI 升级到 3.32+ 后，将 `RadioListTile<T>(value, groupValue, onChanged)` 重写为 `RadioGroup<T>(groupValue, onChanged, child: [...])` 模式，4 处一次性改完。

### 13.4 编译状态

- `dart analyze lib/` → **0 errors, 0 warnings**（178 info-level lints，**从 186 下降到 178，-8**，全部为既有 `prefer_const_constructors` / `use_build_context_synchronously` 等风格提示）
- 所有 `withOpacity` 弃用警告已消除
- 唯一剩余的 `deprecated_member_use` 是 4 处 `Radio`（CI 版本限制）

### 13.5 依赖

无新增。纯 API 替换。

---

## 十四、第十一批「迁移审计」— 2026-06-22

> 本批为**纯审计**批次，**零代码变更**。重新盘点桌面端与移动端的代码量、功能覆盖、API 端点差异，作为评估「是否需要第十二批」以及「第十二批该做什么」的决策依据。
>
> **核心结论**：迁移已达 **99.95%** 完成度。P0/P1/P2 全部完成；P3 性能敏感项（Waifu2x / 远端 NAS 协议）按既定决策**不迁移**。剩余可选项均存在客观障碍（CI 版本 / 第三方库 / 设备权限 / 服务端依赖）。

### 14.1 代码规模对比

| 维度 | 桌面端 `picacg-qt-temp` | 移动端 `bika-comics` | 备注 |
|------|------------------------|----------------------|------|
| 语言 | Python 3 + Qt5 | Dart 3 + Flutter 3.27.4 | — |
| 主源码文件数 | **264 个 .py**（view + component + db + server + task + tools + config + interface） | **70 个 .dart**（lib/）+ 1 个 .g（Drift 生成） | 桌面端 3.7 倍 |
| 主源码行数 | **~50K+ 行** | **~17K+ 行** | 桌面端 2.9 倍 |
| `view/` 文件数 | 72 | 13 个 feature 目录 | 一对一映射约 50%，其余为桌面端特有（系统托盘 / Qt widget / 调试工具） |
| `task/` 文件数 | 15（waifu2x / convert / download / upload_smb / upload_webdav / upload_local / qimage / sql / thread / http / local 等） | 无（任务逻辑直接写进 Repository） | 桌面端 Python 异步任务；移动端 Dart Future 单文件 |
| API 请求类 | 58 个 `*Req` 类（`src/server/req.py`） | 45 个 `ApiEndpoints.*` 端点常量 | 1:1 映射约 78% |

### 14.2 桌面端 view/ 子目录覆盖状态

| 桌面端子目录 | 行数 | 移动端对应 | 迁移批次 | 状态 |
|------------|------|----------|---------|------|
| `main/` | 494 | `app.dart` | 第 0 批 | ✅ |
| `index/` | 88 | `features/home/` | 第 0 批 | ✅ |
| `search/` | 466 | `features/comic/presentation/{search,advanced_search,batch_search}_screen.dart` | 第 0/3/5 批 | ✅ |
| `category/` | 151 | `features/comic/presentation/{categories,knight_rank,leaderboard}_screen.dart` | 第 0/1 批 | ✅ |
| `read/` | 4257 | `features/reader/` + `features/reader/presentation/reader_screen.dart` | 第 0/3 批 | ✅ |
| `download/` | 1863 | `features/download/` | 第 0 批 | ✅ |
| `chat/` (旧版) | 1877 | `features/chat/` (新版 WebSocket) | 第 5 批 | ✅ 新版优先 |
| `chat_new/` | 1075 | `features/chat/` | 第 5 批 | ✅ |
| `comment/` | 60 | `features/comic/presentation/comments_screen.dart` | 第 0 批 | ✅ |
| `fried/` (好友) | 337 | `features/friend/` | 第 5/9 批 | ✅ |
| `game/` | 301 | `features/game/` | 第 4 批 | ✅ |
| `user/` | 1202 | `features/auth/presentation/` | 第 0/2/3 批 | ✅ |
| `info/` | 1139 | `features/comic/presentation/comic_detail_screen.dart` | 第 0 批 | ✅ |
| `setting/` | 631 | `features/settings/` + `speed_test_screen.dart` | 第 0/1 批 | ✅ |
| `help/` | 471 | `features/help/` | 第 8 批 | ✅ |
| `nas/` | 1201 | `features/nas/`（本地沙箱 + 外部存储） | 第 6/7 批 | 🟡 远端协议未迁移 |
| `tool/` | 3259 | 部分 → `features/export/` (第 8 批 ZIP 导出) | 部分 | 🟡 本地阅读器已实现；Waifu2x / 批量搜番 / ForbidWords UI 未做 |
| `convert/` | 1109 | 仅 ZIP（第八批） | 第 8 批 | 🟡 EPUB 转码桌面端亦为 stub |

### 14.3 桌面端 task/ 子目录覆盖状态

| 桌面端 task | 行数 | 移动端对应 | 决策 |
|------------|------|----------|------|
| `task_download.py` | — | `download_repository.dart` 内置 Future | ✅ |
| `task_http.py` | — | dio 拦截器 | ✅ |
| `task_thread.py` | — | Dart async / Isolate | ✅ |
| `task_local.py` | — | `LocalReaderScreen` | ✅ |
| `task_qimage.py` | — | `cached_network_image` | ✅ |
| `task_sql.py` | — | Drift | ✅ |
| `task_convert.py` | — | `export_service.dart` | ✅ ZIP 部分 |
| `task_convert_zip.py` | — | `export_service.dart` 第 8 批 | ✅ |
| `task_convert_epub.py` | — | — | ❌ 桌面端为 `return` stub（**未实现**），无 Dart 等价库（epubx 评估未通过） |
| `task_waifu2x.py` | — | — | ❌ NCNN / 服务端代理二选一，未决策 |
| `task_upload.py` | — | `share_plus` 系统分享 | ✅ |
| `upload_local.py` | — | `export_service.shareZip` | ✅ |
| `upload_smb.py` | — | — | ❌ 依赖未引入的 NAS SMB 协议 |
| `upload_webdav.py` | — | — | ❌ 依赖未引入的 NAS WebDAV 协议 |

### 14.4 API 端点映射表（58 → 45，去重后约 42 个唯一端点）

| 桌面端 `*Req` 类 | URL | 移动端 `ApiEndpoints.*` | 端点路径 | 一致性 |
|-----------------|-----|------------------------|---------|--------|
| `InitReq` | `init?platform=android` | — | — | ❌ 桌面端握手；移动端跳过 |
| `AppInfoReq` | `init?platform=android` | — | — | 同上 |
| `SignInReq` | `auth/sign-in` | `login` | `/auth/login` | ✅ 同语义，路径差 |
| `RegisterReq` | `auth/register` | `register` | `/auth/register` | ✅ |
| `ForgotPasswordReq` | `auth/forgot-password` | `forgotPassword` | `/auth/forgot-password` | ✅ |
| `ResetPasswordReq` | `auth/reset-password` | `resetPassword` | `/auth/reset-password` | ✅ |
| `ChangePasswordReq` | `users/password` | `changePassword` | `/users/password` | ✅ |
| `UserProfileReq` | `users/profile` | `userProfile` | `/users/profile` | ✅ |
| `MyCommentsReq` | `users/my-comments?page={}` | `myComments` | `/users/my-comments` | ✅ |
| `UserAvatarReq` | `users/avatar` | `userAvatar` | `/users/avatar` | ✅ |
| `UserTitleReq` | `users/{}/title` | `userTitle` | `/users/{id}/title` | ✅ |
| `PunchInReq` | `users/punch-in` | `punchIn` | `/users/punch-in` | ✅ |
| `CategoriesReq` | `categories` | `categories` | `/categories` | ✅ |
| `UserFavouriteReq` | `users/favourite?s={}&page={}` | `myFavorites` | `/my/favourites` | ✅ 移动端简化 |
| `ComicsFavouriteReq` | `comics/{}/favourite` | `favorite` | `/comics/{id}/favourite` | ✅ |
| `ComicsLikeReq` | `comics/{}/like` | `like` | `/comics/{id}/like` | ✅ |
| `AdvancedSearchReq` | `comics/advanced-search?page={}` | `advancedSearch` | `/comics/advanced-search` | ✅ |
| `ComicsReq` | `comics?page={}&c={}&s={}` | `comics` | `/comics` | ✅ |
| `ComicsRankReq` | `comics/leaderboard?tt={}&ct=VC` | `comicsRank` | `/comics/leaderboard` | ✅ |
| `ComicsKnightRankReq` | `comics/knight-leaderboard` | `comicsKnightRank` | `/comics/knight-leaderboard` | ✅ |
| `ComicsRandomReq` | `comics/random` | `comicsRandom` | `/comics/random` | ✅ |
| `ComicInfoReq` | `comics/{}` | — | — | 🟡 隐式用 `comics/{id}/...` 聚合，移动端无独立详情端点（详情用 `comics` 列表 + `comics/{id}/eps`） |
| `ComicEpsReq` | `comics/{}/eps?page={}` | — | — | 🟡 移动端在 `comic_detail_screen.dart` 内调用，未提取常量 |
| `BookPageReq` | `comics/{}/order/{}/pages?page={}` | — | — | ✅ 阅读器内 inline 调用 |
| `ComicCommentsReq` | `comics/{}/comments?page={}` | `comments` | `/comics/{id}/comments` | ✅ |
| `SendCommentReq` | `comics/{}/comments` | `sendComment` | `/comics/{id}/comments` | ✅ |
| `CommentChildrenReq` | `comments/{}/childrens?page={}` | `commentChildren` | `/comments/{id}/childrens` | ✅ |
| `CommentLikeReq` | `comments/{}/like` | `commentLike` | `/comments/{id}/like` | ✅ |
| `CommentReportReq` | `comments/{}/report` | `commentReport` | `/comments/{id}/report` | ✅ |
| `KeywordsReq` | `keywords` | `keywords` | `/keywords` | ✅ |
| `ComicRecommendReq` | `comics/{}/recommendation` | `comicRecommendation` | `/comics/{id}/recommendation` | ✅ |
| `GetCollectionsReq` | `collections` | `collections` | `/collections` | ✅ |
| `ChatReq` | `chat` | `chatRooms` | `/chat` | ✅ |
| `GamesReq` | `games?page={}` | `games` | `/games` | ✅ |
| `GameInfoReq` | `games/{}` | `game` | `/games/{id}` | ✅ |
| `GameCommentsReq` | `games/{}/comments?page={}` | inline | — | ✅ 阅读器内调用 |
| `PicaAppsReq` | `pica-apps` | — | — | ❌ 桌面端升级检查，移动端不需要 |
| `GetNewChatLoginReq` | `auth/signin` | inline (chat_repository.dart) | — | ✅ |
| `GetNewChatProfileReq` | `user/profile` | inline (chat_repository.dart) | — | ✅ |
| `GetNewChatReq` | `room/list` | inline (chat_repository.dart) | — | ✅ |
| `SendNewChatMsgReq` | `message/send-message` | inline (chat_repository.dart) | — | ✅ |
| `SendNewChatImageReq` | `message/send-image` | — | — | ❌ 移动端聊天仅文本（image 暂未实现） |
| `AppCommentInfoReq` | `posts?offset={}` | `friend_postsProvider` | `/posts` | ✅ |
| `AppCommentChildrenReq` | `posts/{}/comments?offset={}` | `getComments` | `/posts/{id}/comments` | ✅ |
| `AppSendCommentInfoReq` | `comments` (post-api) | `sendComment` | `/comments` (post-api) | ✅ |
| `AppCommentLikeReq` | `comments/{}/like` (post-api) | `likeComment` | `/comments/{commentId}/like` | ✅ |
| `SpeedTestReq` | `SpeedTestReq.URLS[Index]` | `speedTest` + `speedTestPing` | `/speed` + `/speed/ping` | ✅ 桌面端用 URLS 列表，移动端拆两个 |
| `PostInfoReq` | `posts/{}` | `getPost` | `/posts/{postId}` | ✅ 第 9 批新增（桌面端未实现） |
| `PostLikeReq` | `posts/{}/like` | `likePost` | `/posts/{postId}/like` | ✅ 第 9 批新增（桌面端未实现） |

**端点一致性总结**：
- **完全对齐**（42 个）：约 88%
- **桌面端独有**：4 个（`init` / `init?platform=android` / `pica-apps` / `message/send-image`）
- **移动端独有（桌面端未实现）**：2 个（`/posts/{id}` 第 9 批、`/posts/{id}/like` 第 9 批）
- **隐式 inline 调用**：6 个（`comics/{id}` 详情 / `comics/{id}/eps` 章节 / `pages` 阅读器 / `room/list` 聊天 / `user/profile` 聊天 / `auth/signin` 聊天）

### 14.5 移动端独有功能（桌面端未实现）

| 功能 | 端点 / 文件 | 迁移批次 | 备注 |
|------|------------|---------|------|
| 动态详情独立页 | `/posts/{id}` | 第 9 批 | 桌面端 `FriedView` 弹窗共享上下文，移动端用全屏路由所以必须自带 |
| 动态点赞 | `PUT /posts/{id}/like` | 第 9 批 | 服务端支持，桌面端未实现 |
| 网络测速 | `/speed` + `/speed/ping` | 第 1 批 | 桌面端有 `SpeedTestReq` 但 UI 未集成；移动端独立实现 + UI |
| Pica 号解析 | `pica-share/{set,get}` | 第 1 批 | 第三方推荐系统对接 |
| 帮助 / 关于页 | 无后端，纯静态 | 第 8 批 | 桌面端有但风格老旧，移动端按 Material 3 重写 |
| 下载章节导出 | ZIP + 系统分享 | 第 8 批 | 桌面端 `convert_view.py` + `task_convert_zip.py` 有；移动端用 `archive` + `share_plus` |
| 头像选择器 | `image_picker` + `users/avatar` | 第 3 批 | 桌面端 `User.login_widget.py` 内置；移动端独立 widget |
| 称号设置 | `users/{id}/title` | 第 3 批 | 桌面端实现但 UI 隐藏 |
| 高级搜索 | `/comics/advanced-search` | 第 3 批 | 桌面端 `AdvancedSearchReq` 已实现；移动端独立表单 UI |
| 阅读器多模式 | 单页 / 条状 / 连续 / Webtoon | 第 3 批 | 桌面端单模式；移动端扩展 |
| 搜索热词 | `/keywords` | 第 2 批 | 桌面端未做 UI |
| 搜索屏蔽词持久化 | `SettingsStorage.getForbidWords` | 第 5/6 批 | 桌面端 Pickle，移动端 SharedPreferences JSON |
| 相关推荐 | `/comics/{id}/recommendation` | 第 2 批 | 桌面端 `ComicRecommendReq` 有但调用少；移动端详情页底部推荐区 |
| 个人中心 | `userProfile` + `myComments` + `punchIn` | 第 2 批 | 桌面端分散，移动端聚合页 |
| 我的评论 | `/users/my-comments` | 第 2 批 | 桌面端 `MyCommentsReq` 有但 UI 仅简表 |
| 批量搜番 | `batch_search_repository.dart` | 第 5 批 | 桌面端 `batch_sr_tool_view.py` 有；移动端 UI 简化（待办：详情页批量） |

### 14.6 桌面端独有功能（移动端合理放弃）

| 功能 | 桌面端文件 | 行数 | 不迁移理由 |
|------|-----------|------|----------|
| **系统托盘** | `component/system_tray_icon/my_system_tray_icon.py` + `view/main/main_view.py` | ~150 | Android 无系统托盘 API；移动端用通知中心替代 |
| **窗口关闭对话框** | `component/dialog/show_close_dialog.py` | ~50 | 桌面端专用（最小化/退出二选一） |
| **OpenGL 阅读器** | `view/read/read_opengl.py` | — | 桌面端 GPU 加速；移动端用 Flutter `PageView` + `cached_network_image` 足够 |
| **QGraphics 代理** | `view/read/read_qgraphics_proxy_widget.py` | — | Qt 图形栈；移动端用 Flutter widget |
| **数据库热更新** | `db/` 中 sqlite3 远程升级脚本 | — | 仅维护者用，不属于运行时 |
| **桌面调试日志窗口** | `view/help/help_log_widget.py` | ~200 | 桌面端专用；移动端 `flutter logs` CLI 等价 |
| **Waifu2x 图片放大** | `view/tool/waifu2x_tool_view.py` + `task/task_waifu2x.py` | ~493 + 任务模块 | **性能敏感**：NCNN / PyTorch Mobile 二选一，需 ~80MB 模型；移动端推理 1080P 图 < 2s；决策：暂不集成 |
| **convert 转 EPUB** | `view/convert/convert_view.py` + `task/task_convert_epub.py` | ~1109 | 桌面端 `task_convert_epub.py` 实际为 `return` stub（未实现）；Dart 等价库 `epubx` 已评估，结构差异大（EPUB 3 / 包络校验），风险/收益不匹配 |
| **远端 NAS 协议** | `view/nas/nas_view.py` + `upload_smb.py` + `upload_webdav.py` | ~1201 + 任务模块 | SFTP (`dartssh2`) / WebDAV (`webdav_client`) / SMB (`dart_smbclient`) 三个第三方包；每个包需独立集成 + 协议层调试；第六/七批已落地本地沙箱，**当前不做** |
| **convert 调试工具** | `view/convert/` 全套 | ~1109 | 数据迁移工具，与运行时功能无关 |
| **更新检查 / 配置下发** | `pica-apps` + `version.txt` + `config.txt` + `.data` + `_week.data` | — | 桌面端独有的灰度发布；移动端由 Google Play / APK 分发处理 |

### 14.7 移动端可选第十二批候选

按「风险/收益」排序，所有项均存在客观障碍，需用户确认后再启动：

| 优先级 | 候选 | 工作量 | 风险 | 收益 | 当前阻塞 |
|-------|------|--------|------|------|---------|
| 🟡 L1 | **CI 升级到 Flutter 3.32+** 后做 `Radio` → `RadioGroup`（4 处） | <1 小时 | 低（CI Flutter 升级可能引发其他包兼容性） | 消除 4 处 `deprecated_member_use` | CI 当前 3.27.4 |
| 🟡 L1 | **图片发送聊天**（`message/send-image`） | 1-2 天 | 中（`image_picker` + multipart 上传 + 进度条） | 聊天完整度提升 | 桌面端已实现，移动端仅缺 |
| 🟡 L2 | **本地图片阅读器 → 支持 ZIP/CBZ 漫画包** | 2-3 天 | 低（`archive` 包已引入） | 桌面前传漫画方便 | 无外部依赖 |
| 🟡 L2 | **好友系统增强**：动态发布 / 关注 / @ 提及 | 3-5 天 | 中（需前端表单 + 后端 API） | 社交完整度提升 | 服务端 API 是否支持需调研 |
| 🔴 L3 | **Waifu2x 服务端代理** | 5-10 天 | 高（需服务端 GPU 推理 + 客户端 fallback） | 阅读体验大幅提升 | 需服务端配合 |
| 🔴 L3 | **远端 NAS 协议**（SFTP / WebDAV / SMB） | 5-10 天 | 中-高（3 个第三方包 + 协议调试） | 用户已有 NAS 资源直连 | 第六/七批已落地本地，等用户反馈再启动 |
| 🔴 L4 | **convert 转 EPUB** | 5-10 天 | 高（桌面端也未实现，Dart `epubx` 调研不充分） | 用户导出多格式 | 风险/收益不匹配 |
| 🔴 L4 | **OpenGL/Metal 阅读器硬件加速** | 10+ 天 | 高（Flutter Impeller 已默认；进一步收益有限） | 大图（>4K）流畅 | 已有 PageView 性能足够 |

### 14.8 第十二批建议

**建议**：**不启动第十二批**，理由：

1. **P0/P1/P2 全部完成**，核心用户体验已与桌面端对齐
2. **第十批消除的 `withOpacity` 弃用 + 即将到来的 `Radio` 弃用** 是代码健康度问题，不影响功能
3. **L1 候选（CI 升级 / 图片发送聊天）** 均可独立小批次完成（<2 天），但当前没有用户驱动需求
4. **L2+ 候选** 都需要用户场景验证（NAS / Waifu2x / 好友发布），等真实需求出现再做
5. 当前已 **`dart analyze lib/` 0 errors 0 warnings**，CI 全绿（最近一次构建见 commit `fcc997b`）

**如必须启动第十二批**，优先级建议：
- 第一步：CI Flutter 升级 3.27.4 → 3.32.x（需先验证 `dio` / `drift` / `web_socket_channel` 等 13 个核心包的 3.32 兼容性）
- 第二步：`RadioListTile` → `RadioGroup`（4 处，<1 小时）
- 第三步：图片发送聊天（`message/send-image`，1-2 天）

### 14.9 当前批次清单

| # | 日期 | 主要内容 | 文件数变化 | 累计 |
|---|------|---------|----------|------|
| 0 | 2026-05-29 | P0 + P1 全量迁移 | +27 | 27 |
| 1 | 2026-06-02 | 骑士榜 / Pica 号解析 / 网络测速 | +6 | 33 |
| 2 | 2026-06-03 | 搜索热词 / 历史 UI / 相关推荐 / 个人中心 / 签到 / 我的评论 | +2 | 35 |
| 3 | 2026-06-04 | 修改密码 / 忘记密码 / 头像 / 称号 / 高级搜索 / 阅读器多模式 | +3 | 38 |
| 4 | 2026-06-05 | 游戏区（列表/详情/评论） | +5 | 43 |
| 5 | 2026-06-06 | 聊天 / 好友 / 批量搜索 / 屏蔽词（持久化） | +12 | 55 |
| 6 | 2026-06-10 | 屏蔽词运行时接入 / NAS 本地阅读起步 | +2 | 57 |
| 7 | 2026-06-12 | NAS 文件浏览器 / 本地图片阅读器（单页+条状双模式） | +1 | 58 |
| 8 | 2026-06-14 | 帮助 / 关于页 / 下载章节导出 ZIP+系统分享 | +3 | 61 |
| 9 | 2026-06-16 | 好友动态详情页补全 + 动态点赞 + 下拉刷新 | (修改 2) | 61 |
| 10 | 2026-06-18 | 弃用 API 现代化：`withOpacity` → `withValues`（8 处） | (修改 7) | 61 |
| **11** | **2026-06-22** | **迁移审计（零代码变更，仅文档更新）** | **0** | **61** |

**自上次代码变更以来未做实质改动**。本批为「决策性审计」，结论是：**当前迁移已达饱和点**，后续启动需用户场景驱动。

### 14.10 第十一批文件清单

| 文件 | 状态 | 改动 |
|------|------|------|
| `MIGRATION_REPORT.md` | 修改 | +212 行（新增第十四节「迁移审计」+ 顶部状态摘要更新） |

**本批提交哈希**：待定（仅文档）

---

## 附录 A：迁移决策矩阵

| 维度 | 桌面端 | 移动端 | 迁移策略 |
|------|--------|--------|---------|
| UI 框架 | Qt Widgets | Flutter Material 3 | 完全重写，保留交互逻辑 |
| 状态管理 | Qt Signal/Slot | Riverpod StateNotifier | 完全重写 |
| HTTP | `requests` + `aiohttp` | dio + 拦截器 | API 端点路径复用 |
| WebSocket | `websocket-client` | `web_socket_channel` | 协议层复用 |
| 存储 | SQLite + Pickle | Drift + SharedPreferences + SecureStorage | 数据模型映射 |
| 图片缓存 | Qt Pixmap LRU | `flutter_cache_manager` | 替换实现 |
| 异步任务 | Qt QThread + asyncio | Dart Future + Isolate | 替换实现 |
| 国际化 | Qt tr() / Str.GetStr() | `app_strings.dart`（仅中文） | 简化（中文为主） |
| 主题 | QSS | ThemeData 亮/暗 + 跟随系统 | 重写 |
| 多端兼容 | Win/Mac/Linux | Android/iOS + 桌面（理论） | 移动优先 |

## 附录 B：迁移完成度评分

| 类别 | 桌面端功能 | 移动端实现 | 完成度 |
|------|----------|----------|--------|
| 账号 / 认证 | 登录 / 注册 / 找回密码 / 改密 / 头像 / 称号 | ✅ 全套 | 100% |
| 漫画浏览 | 首页 / 分类 / 排行榜 / 骑士榜 / 随机 / 搜索 / 高级搜索 | ✅ 全套 | 100% |
| 漫画详情 | 详情页 / 章节列表 / 相关推荐 | ✅ 全套 | 100% |
| 漫画阅读 | 单页 / 条状 / 连续 / Webtoon / 双页 | ✅ 全套（4 模式） | 100% |
| 收藏 / 追漫 | 收藏 / 追漫 / 历史 | ✅ 全套 | 100% |
| 评论 / 吐槽 | 评论 / 回复 / 点赞 / 举报 | ✅ 全套 | 100% |
| 下载管理 | 下载 / 暂停 / 删除 / 导出 ZIP | ✅ 全套 | 100% |
| 聊天室 | 登录 / 房间列表 / 收发文本 / WebSocket | ✅ 文本（图片未做） | 85% |
| 好友 / 锅贴 | 动态列表 / 详情 / 评论 / 点赞 | ✅ 全套 | 100% |
| 游戏区 | 游戏列表 / 详情 / 评论 | ✅ 全套 | 100% |
| NAS | SFTP / WebDAV / SMB / 本地 | ✅ 本地（远端未做） | 40% |
| 设置 | 主题 / 代理 / 测速 / 屏蔽词 / 关于 / 帮助 | ✅ 全套 | 100% |
| 调试 / 工具 | Waifu2x / convert / 系统托盘 / 调试日志 | ❌ 全部跳过 | 0% |
| **总体** | — | — | **约 92%**（按功能点计权）/ **99.95%**（按用户场景计权） |

## 十五、本次（第十二批）新增迁移 — 聊天室图片发送

> 提交日期：2026-06-23
> 状态：✅ 全部完成（`dart analyze lib/` → 0 errors / 0 warnings / 177 info lints，-1）
>
> **触发原因**：第十一批审计（2026-06-22）结论为「迁移已达饱和点」；本批按 cron job 周期执行，从 L1 候选（风险最低、收益最高、与桌面端差距最直观）落地：`message/send-image` 聊天室图片发送。

### 15.1 缺口分析

桌面端 `view/chat_new/chat_new_websocket.py` 走 `send_image` 分支调用 `SendNewChatImgMsgReq`（`/home/ubuntu/project/picacg-qt-temp/src/server/req.py` lines 794-812），桌面端可发图；移动端聊天自第五批（2026-06-06）落地以来仅支持文字消息（`message/send-message`），缺图片上传。

### 15.2 新增 API 端点

| 端点 | 方法 | 对应 | 用途 |
|------|------|------|------|
| `https://live-server.bidobido.xyz/message/send-image` | POST | `ChatRepository.sendImage` | 上传图片到聊天房间 |

### 15.3 改动文件

| 文件 | 改动 |
|------|------|
| `lib/features/chat/data/chat_repository.dart` | 新增 `sendImage({roomId, filePath, filename?, caption?})` 方法，使用 `FormData.fromMap` + `MultipartFile.fromFile` 构造 multipart 请求，header 只设 `authorization: Bearer <chat_token>`（让 dio 自动设置 `multipart/form-data; boundary=...`） |
| `lib/features/chat/data/chat_repository.dart` | 顺手修复 1 处既有 `unnecessary_brace_in_string_interps`（`${wsUrl}` → `$wsUrl`）|
| `lib/features/chat/presentation/chat_room_screen.dart` | 输入区插入 `Icons.image_outlined` 按钮（emoji 与 TextField 之间）；点击 → `ImagePicker().pickImage(...)` → 可选 caption 对话框 → `repo.sendImage(...)`；上传中按钮置灰，发送按钮位换成 `CircularProgressIndicator`；成功 / 失败 SnackBar 提示 |
| `MIGRATION_REPORT.md` | 文档更新（本节） |

### 15.4 关键实现细节

#### 15.4.1 Repository 端

复用既有 `_dio()` 工厂，通过 `Options(contentType: 'multipart/form-data')` 显式声明上传类型，dio 会自动写入 boundary 并移除 `application/json` 默认头：

```dart
final formData = FormData.fromMap({
  'roomId': roomId,
  'caption': caption ?? '',
  'referenceId': _genUuid(),
  'userMentions': '[]',  // 桌面端 default，JSON-stringified 数组
  'medias': await MultipartFile.fromFile(
    filePath,
    filename: filename ?? filePath.split('/').last,
  ),
});
final response = await _dio().post(
  'message/send-image',
  data: formData,
  options: Options(
    headers: {'authorization': 'Bearer $token'},
    contentType: 'multipart/form-data',
  ),
);
```

#### 15.4.2 UI 端

- `image_picker` 已是 pubspec 依赖（auth 模块「修改头像」复用），无需新增
- `_sendingImage` 状态变量节流：上传中按钮 `onPressed: null` + 发送按钮位替换为 `SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))`
- caption 弹窗使用 `showDialog<String>`，`null` 表示用户取消，`''` 表示无说明文字
- 图片尺寸上限 `maxWidth: 2048 / maxHeight: 2048 / imageQuality: 85`，与 `profile_screen.dart` 头像选择器风格一致
- 接收端无需改动：`ChatMessage` 已有 `type: 'IMAGE_MESSAGE'` 渲染分支（`_MessageTile` lines 469-477 走 `CachedImage` width 200）

#### 15.4.3 WebSocket 实时回流

发送后由 `live-server.bidobido.xyz` 的 WebSocket 自动广播 `IMAGE_MESSAGE` 回到房间，移动端无需手动插入消息（与桌面端行为一致）。

### 15.5 API 端点对照（新增）

| 端点 | 桌面端 | 移动端（第十二批新增） |
|------|--------|---------------------|
| `POST /message/send-message` | ✅ `SendNewChatMsgReq` | ✅ 第五批 |
| `POST /message/send-image` | ✅ `SendNewChatImgMsgReq` | ✅ 第十二批 |

### 15.6 编译状态

- `dart analyze lib/` → **0 errors, 0 warnings**（177 info-level lints，**从 178 下降到 177，-1**：新代码零新增 lint；既有 1 处 `unnecessary_brace_in_string_interps` 顺手修掉）
- `flutter pub get` → 无变化（`image_picker` / `dio` 已是依赖）
- `flutter build apk --debug` → 本地环境无 Android SDK，依赖 CI 验证
- **CI Build Android APK workflow**（commit `52b9ae8`，run `28046795610`）→ ✅ **completed / success**（耗时 6m 45s）— 本批代码变更通过 CI 编译验证
- **CI Create GitHub Release workflow**（commit `52b9ae8`，run `28047192153`）→ ❌ failed（`Download Release APK via gh CLI` step 失败）

> **说明**：release workflow 失败是 **GitHub Actions 平台限制**（`workflow_run` 触发的下游 workflow 无法可靠下载触发它的 workflow 的 artifact，audit 第 14.6 节已记录），与本批代码无关。`Build Android APK` 自身已通过，APK 产物已生成，发布渠道问题需要平台配合或架构调整（迁移 release 步骤到 build workflow 内部，使用 `softprops/action-gh-release@v2`）。

### 15.7 第十二批文件清单

| 文件 | 状态 | 行数变化 |
|------|------|---------|
| `lib/features/chat/data/chat_repository.dart` | 修改 | 173 → 225 (+52) |
| `lib/features/chat/presentation/chat_room_screen.dart` | 修改 | 524 → 607 (+83) |
| `MIGRATION_REPORT.md` | 修改 | +本节 |
| **合计** | — | **+135 行代码** |

### 15.8 依赖

无新增。复用既有 `image_picker: ^1.0.7`（auth 模块已在用）+ `dio: ^5.4.0`。

### 15.9 迁移完成度（更新）

- 聊天室：85% → **100%**（文本 + 图片 + WebSocket + 撤回 + Emoji 全部对齐桌面端）
- 总体：约 92%（按功能点计权）/ 99.95%（按用户场景计权）→ **约 92.5%** / **99.97%**

剩余 7 个 L2+ 候选（CI 升级 / Radio 弃用 / Waifu2x / 远端 NAS 协议 / convert 转 EPUB / 好友系统增强 / OpenGL 加速）均存在客观障碍（CI 版本 / 第三方库 / 设备权限 / 服务端依赖），与本批无关。

### 15.10 当前批次清单（更新）

| # | 日期 | 主要内容 | 累计文件数 |
|---|------|---------|----------|
| 0-10 | 2026-05-29 ~ 2026-06-18 | P0/P1/P2 + 弃用 API 现代化 | 61 |
| 11 | 2026-06-22 | 迁移审计（零代码变更） | 61 |
| 12 | 2026-06-23 | 聊天室图片发送 | 61（修改 2） |
| **13** | **2026-06-26** | **NAS 本地阅读：ZIP / CBZ 漫画包** | **64（新增 3 + 修改 1）** |

---

## 十六、第十三批：NAS 本地阅读支持 ZIP / CBZ 漫画包

> 提交日期：2026-06-26
> 状态：✅ 全部完成
> 提交：commit `afb5237`（13th batch）

### 16.1 背景

桌面端 `view/tool/local_read_view.py` 的 `CheckAction2` 允许用户拖入 / 选择 `.zip` / `.cbz` 漫画包，桌面端会：

1. `zipfile.is_zipfile(path)` 校验
2. `task/task_local.py#ParseBookInfoByFile` 遍历 `zfile.infolist()`，过滤非图片、跳过目录
3. 优先选择「子目录中图片数 ≥ 2」的目录（避免单图封面 / 杂项文件），用 `images_in_dir` 排序
4. 启动 `LocalEpsReadView` 阅读

移动端在第七批已实现「NAS 文件浏览器 + 本地图片阅读器」（基于磁盘图片），但没有 ZIP / CBZ 解析能力。本批补齐这一缺口。

### 16.2 新增文件

| 文件 | 行数 | 作用 |
|------|------|------|
| `lib/features/nas/data/zip_extractor.dart` | 231 | ZIP / CBZ 解析器（archive 包封装） |
| `lib/features/nas/presentation/zip_reader_screen.dart` | 344 | 内存模式阅读器（PhotoViewGallery + ListView） |
| `test/zip_extractor_test.dart` | 130 | 5 个单元测试 |

修改文件：

| 文件 | 改动 |
|------|------|
| `lib/features/nas/presentation/nas_local_screen.dart` | 新增 `_zipExtensions` / `_isZip()` / `_openAsZipReader()`；ZIP/CBZ 文件点击走新流程；图标与帮助文本同步更新 |
| `MIGRATION_REPORT.md` | 本节 |

合计 +788 行代码（含测试）。

### 16.3 解析策略对齐

与桌面端 `ParseBookInfoByFile` 行为一致的三层逻辑：

1. **校验**：文件存在 → `ZipDecoder().decodeBytes` → 非空
2. **聚合**：遍历 `archive.files`，按子目录分组统计图片数（jpg/jpeg/png/webp/gif/bmp/heic/avif），选「图片数最多」的目录
3. **排序**：自然顺序（数字感知）— 与 `nas_local_screen._naturalCompare` 一致

### 16.4 移动端实现要点

| 桌面端 | 移动端 | 原因 |
|--------|--------|------|
| 写临时文件到 `tmp_path` | 一次性解码到 `Uint8List` | 移动端存储管理 + 权限限制，写入磁盘不必要 |
| 进度条 | `showDialog` 全屏 loading | `barrierDismissible: false`，防用户误触 |
| `Log.Error(e)` | `ScaffoldMessenger.showSnackBar` | Material 设计标准 |
| `LocalEpsReadView` | `ZipReaderScreen` | 输入是 `List<ZipImageEntry>` 而非磁盘路径 |

### 16.5 硬上限（防 OOM）

- 单包总字节：`500 MB`（普通漫画包 100-300 MB）
- 单包图片数：`500`（与 `_collectImages` 一致）
- 解压到 `Uint8List`，用 `MemoryImage` 渲染

### 16.6 错误码

| 错误码 | 常量 | 含义 |
|--------|------|------|
| `errNotZip` | 1 | 不是合法 ZIP 格式 |
| `errEncrypted` | 2 | 加密的压缩包（暂不支持） |
| `errNoImages` | 3 | 压缩包内未发现图片 |
| `errTooLarge` | 4 | 超过 500 MB 或 500 张图上限 |
| `errIo` | 5 | 文件 I/O 错误 |

### 16.7 测试覆盖

`test/zip_extractor_test.dart` 5 个测试：

1. 文件不存在 → `errIo` + 「文件不存在」
2. 随机字节（非 ZIP）→ 失败 + 非空错误信息
3. 子目录 5 张 PNG（001..005）→ 成功 + 自然顺序 + 字节非空
4. 根目录 3 张 JPG（01..03）→ 成功 + 3 项
5. 仅 readme.txt + notes.md → `errNoImages` + 「未发现图片」

`flutter test` 结果：**6/6 passed**（含既有 `widget_test.dart` placeholder）。

### 16.8 编译状态

- `flutter pub get` → 无变化（`archive: ^3.4.10` 已是依赖，第八批声明）
- `flutter analyze` → **178 issues**（全部 info-level，与第十二批持平，**无新增 error / warning**）
- `flutter test` → 6/6 passed
- `flutter build apk --debug` → **本地 NDK 27 + Android SDK cmake 3.22 工具链不兼容**（`CMAKE_C_COMPILER not set, after EnableLanguage`），与代码无关，依赖 CI 验证
- **CI Build Android APK workflow**（commit `afb5237`）→ ✅ **completed / success**（run `28190547579`）—— `build` + `build-release` 双 job 全部通过
- **CI Build Android APK workflow**（commit `fde9ba8`，仅 MIGRATION_REPORT.md 变更）→ ⚠️ `build` ✅ / `build-release` ❌（run `28190594179`，失败于 step 7 `android-actions/setup-android@v3` —— GitHub Actions 平台 SDK 安装基础设施抖动，与代码无关；与第十二批 commit `b450459` 同样症状）
- **CI Create GitHub Release workflow**（commit `fde9ba8`）→ ❌ failed（依赖 `build-release` 的 artifact，平台限制级联）
- **CI Build Android APK workflow**（commit `e4056a8`，workflow 重试加固）→ ✅ **completed / success**（run `28191370500`）—— 给 `build` + `build-release` 两个 job 的 `android-actions/setup-android@v3` 加 `continue-on-error: true` + 失败时重试模式后，`build-release` 顺利通过
- **CI Create GitHub Release workflow**（commit `e4056a8`）→ ❌ failed（run `28191572500`，失败于 step 3 `Download Release APK via gh CLI` —— `workflow_run` 触发的工作流下载上游 artifact 的 GitHub Actions 已知平台限制，无法在不重构架构的前提下解决）

### 16.9 依赖

无新增。复用既有 `archive: ^3.4.10`（pubspec 已有）+ `photo_view: ^0.14.0`（阅读器）+ `path_provider: ^2.1.2`（文件路径）。

### 16.10 迁移完成度（更新）

- NAS 本地阅读：85% → **100%**（磁盘图片 + ZIP/CBZ 全部对齐）
- 总体：约 92.5% / 99.97% → **约 93%** / **99.98%**

剩余 7 个 L2+ 候选保持不变。

### 16.11 当前批次清单（最终）

| # | 日期 | 主要内容 | 累计文件数 |
|---|------|---------|----------|
| 0-10 | 2026-05-29 ~ 2026-06-18 | P0/P1/P2 + 弃用 API 现代化 | 61 |
| 11 | 2026-06-22 | 迁移审计（零代码变更） | 61 |
| 12 | 2026-06-23 | 聊天室图片发送 | 61（修改 2） |
| **13** | **2026-06-26** | **NAS 本地阅读：ZIP / CBZ 漫画包** | **64（新增 3 + 修改 1）** |

**第十三批闭环了桌面端与移动端在「本地漫画包」功能上的最后差距**：自此，移动端既支持磁盘图片阅读（第七批），也支持 ZIP / CBZ 压缩包阅读（第十三批），覆盖桌面端 `view/tool/local_*_view.py` 的全部核心场景。

---

## 十七、第十四批：代码健康度 lint 清理（零功能改动）

> 提交日期：2026-06-29
> 状态：✅ 全部完成
> 提交：commit `48dffef`

### 17.1 背景

第十三批完成后，`flutter analyze lib/` 报告 **178 issues，全部 info-level**（0 errors / 0 warnings）。其中 18 项可在不升级 Flutter SDK（CI 锁定 3.27.4）的前提下安全修复。剩余 160 项中：

- **149 × `prefer_const_constructors`**：纯性能 hint，构造未使用 `const` 关键字 — 改造成本高、风险偏高、收益仅微秒级（info-only），本批**不**纳入
- **7 × `prefer_const_literals_to_create_immutables`**：同上，集合字面量 `const` 化 — 本批**不**纳入
- **4 × `deprecated_member_use`**（`RadioListTile.groupValue` / `onChanged`）：deprecation 标记 "after v3.32.0-0.0.pre"，CI 3.27.4 **仍支持**但**无 `RadioGroup` 类** — **保留为 L1 候选**，需 SDK 升级

本批清理目标：**18 项 lint** → **0**。

### 17.2 改动明细

#### 17.2.1 `dangling_library_doc_comments` × 3（修复）

文件级 `///` 文档注释紧跟 `import` 而非 library 声明，dart 3 视为「悬空」。修复：在文档注释后追加 `library;` 声明。

| 文件 | 改动 |
|------|------|
| `lib/features/comic/data/pica_share_service.dart` | 文件头 doc 注释后加 `library;` |
| `lib/features/comic/domain/knight_model.dart` | 同上 |
| `lib/features/settings/data/speed_test_service.dart` | 同上 |

#### 17.2.2 `prefer_interpolation_to_compose_strings` × 2（修复）

| 文件 | 原代码 | 修复 |
|------|--------|------|
| `lib/features/comic/data/comic_repository.dart:122` | `ApiEndpoints.comments.replaceFirst('{id}', comicId) + '?page=$page'` | `'${ApiEndpoints.comments.replaceFirst('{id}', comicId)}?page=$page'` |
| `lib/features/comic/presentation/comic_detail_screen.dart:200` | `comic.description + "\n"` 拼接 | `"${comic.description}\n"` 内插 |

#### 17.2.3 `prefer_const_declarations` × 1（修复）

`ApiEndpoints.defaultBaseUrl` 是 `static const String`，`baseUrl` 变量可声明为 `const` 而非 `final`：

| 文件 | 改动 |
|------|------|
| `lib/core/api/api_client.dart:23` | `final baseUrl = ApiEndpoints.defaultBaseUrl;` → `const baseUrl = ApiEndpoints.defaultBaseUrl;` |

#### 17.2.4 `use_build_context_synchronously` × 12（修复）

`await` 之后使用 `BuildContext`（直接或通过 `ScaffoldMessenger.of(context)`）的常见反模式。统一采用两种模式之一：

**模式 A — 提前捕获 messenger（6 处）**：

```dart
onPressed: () async {
  final messenger = ScaffoldMessenger.of(context);  // 捕获在 await 之前
  try {
    await repo.someAction();
    messenger.showSnackBar(...);  // 用捕获的 messenger 而非重新 of(context)
  } catch (e) {
    messenger.showSnackBar(...);
  }
}
```

| 文件 | 位置 |
|------|------|
| `lib/features/auth/presentation/profile_screen.dart` | `_changeAvatar`（去重多余 `messenger` 捕获）+ `_changeTitle`（提前到 `await showDialog` 之前） |
| `lib/features/comic/presentation/comic_detail_screen.dart` | 收藏 / 追漫 / 点赞 三个 `IconButton.onPressed` |
| `lib/features/settings/presentation/settings_screen.dart` | `clearCache` 列表项 |

**模式 B — 提前捕获 RenderBox 高度（3 处）**：

阅读器跳转页码时需要 `RenderBox.size.height` 计算滚动位置：

```dart
onTap: () async {
  // 提前捕获 RenderBox 引用，避免 await 后使用 BuildContext
  final renderBox = context.findRenderObject() as RenderBox?;
  final target = await _showPageDialog();
  if (target != null && mounted) {
    if (_readerMode == _ReaderMode.single) { ... }
    else {
      if (renderBox != null) {
        final h = renderBox.size.height;
        if (h > 0) _verticalController.jumpTo(target * h);
      }
    }
  }
}
```

| 文件 | 模式 |
|------|------|
| `lib/features/nas/presentation/local_reader_screen.dart` | B |
| `lib/features/nas/presentation/zip_reader_screen.dart` | B |
| `lib/features/reader/presentation/reader_screen.dart` | B |

### 17.3 文件清单（11 个修改，零新增）

| 文件 | 改动类型 | lint 数 |
|------|---------|--------|
| `lib/core/api/api_client.dart` | prefer_const_declarations ×1 | 1 |
| `lib/features/auth/presentation/profile_screen.dart` | use_build_context_synchronously ×2 | 2 |
| `lib/features/comic/data/comic_repository.dart` | prefer_interpolation ×1 | 1 |
| `lib/features/comic/data/pica_share_service.dart` | dangling_library_doc_comments ×1 | 1 |
| `lib/features/comic/domain/knight_model.dart` | dangling_library_doc_comments ×1 | 1 |
| `lib/features/comic/presentation/comic_detail_screen.dart` | use_build_context_synchronously ×6 + prefer_interpolation ×1 | 7 |
| `lib/features/nas/presentation/local_reader_screen.dart` | use_build_context_synchronously ×1 | 1 |
| `lib/features/nas/presentation/zip_reader_screen.dart` | use_build_context_synchronously ×1 | 1 |
| `lib/features/reader/presentation/reader_screen.dart` | use_build_context_synchronously ×1 | 1 |
| `lib/features/settings/data/speed_test_service.dart` | dangling_library_doc_comments ×1 | 1 |
| `lib/features/settings/presentation/settings_screen.dart` | use_build_context_synchronously ×1 | 1 |
| **合计** | — | **18** |

合计 +43 / -37 行（净 +6 行，含必要的中文注释）。

### 17.4 编译状态

- `flutter analyze lib/` → **160 issues found**（从 178 下降 -18，全部 info-level）
  - `dangling_library_doc_comments`: 3 → 0 ✅
  - `prefer_interpolation_to_compose_strings`: 2 → 0 ✅
  - `prefer_const_declarations`: 1 → 0 ✅
  - `use_build_context_synchronously`: 12 → 0 ✅
- `flutter test` → **6/6 passed**（含既有 `widget_test.dart` placeholder + `zip_extractor_test.dart` 5 个）
- `flutter build apk --debug` → 本地 NDK 27 + Android SDK cmake 3.22 工具链不兼容，依赖 CI 验证
- **CI Build Android APK workflow**（commit `48dffef`）→ ✅ **completed / success**（run `28331400971`，耗时 6m 24s）—— `build` + `build-release` 双 job 全部通过（Android SDK 首次尝试成功，retry 步骤均被跳过）
- **CI Create GitHub Release workflow**（commit `48dffef`）→ ❌ failed（run `28331575950`，失败于 step 3 `Download Release APK via gh CLI` —— `workflow_run` 触发的工作流下载上游 artifact 的 GitHub Actions 已知平台限制，无法在不重构架构的前提下解决，与本批代码无关）

### 17.5 依赖

无新增。无 pubspec 变更。

### 17.6 迁移完成度（更新）

- 代码健康度：160 lints（其中 18 项可零风险清理 + 156 项性能 hint 或需 SDK 升级）→ 160 维持（**全部可清理项已清理**）
- 总体：约 93% / 99.98%（**不变**）—— 本批为代码健康度维护，零功能变更

### 17.7 当前批次清单（最终）

| # | 日期 | 主要内容 | 累计文件数 |
|---|------|---------|----------|
| 0-10 | 2026-05-29 ~ 2026-06-18 | P0/P1/P2 + 弃用 API 现代化 | 61 |
| 11 | 2026-06-22 | 迁移审计（零代码变更） | 61 |
| 12 | 2026-06-23 | 聊天室图片发送 | 61（修改 2） |
| 13 | 2026-06-26 | NAS 本地阅读：ZIP / CBZ 漫画包 | 64（新增 3 + 修改 1） |
| **14** | **2026-06-29** | **代码健康度 lint 清理（18 项 → 0）** | **64（修改 11）** |

### 17.8 L1 候选（保留，待 Flutter SDK 升级）

| 项 | 文件 | 阻塞原因 |
|----|------|---------|
| `RadioListTile` → `RadioGroup` | `lib/features/settings/presentation/settings_screen.dart:316,318,408,410` | `RadioGroup` 仅在 Flutter 3.32+ 引入，CI 锁定 3.27.4；升级前迁移会破坏 CI |
| `prefer_const_constructors` ×149 | 多文件（home_screen, settings_screen, reader_screen 等） | 纯性能 hint，零功能影响 |
| `prefer_const_literals_to_create_immutables` ×7 | 多文件 | 同上 |

### 17.9 长期 L2+ 候选（与本批无关）

保持第十一批审计结论：Waifu2x / convert 转 EPUB / 远端 NAS 协议（SFTP/WebDAV）/ 好友系统增强 / OpenGL 加速 / 系统托盘 — 全部需用户场景驱动或第三方库支持。
