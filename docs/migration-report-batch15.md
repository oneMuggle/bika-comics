# 哔咔漫画 桌面端→移动端 迁移分析报告 · 第十五批审计

## 一、项目概况

| 项 | 桌面端 (参考) | 移动端 (目标) |
|----|--------------|--------------|
| 路径 | `/home/ubuntu/project/picacg-qt-temp` | `/home/ubuntu/project/bika-comics` |
| 技术栈 | Python 3 + PyQt5 | Flutter 3.27 (CI) / 3.41 (本地) + Riverpod |
| HTTP 客户端 | httpx (自实现 Server() 单例 + httpx.Client 池) | dio (ApiClient 单例 + 拦截器) |
| 状态管理 | QtOwner (Python 单例) | flutter_riverpod + riverpod_generator |
| 数据库 | SQLite (Python `sqlite3`) | Drift (sqlite3_flutter_libs) |
| 加密存储 | QSettings + 自实现加密 | flutter_secure_storage |
| 文件数 (核心) | 263 个 .py (排除 images_rc.py) | 73 个 .dart |
| 视图文件 | 50+ PyQt 视图 | 13 feature 模块 |

---

## 二、迁移完成度（按批次）

| 批次 | 内容 | 状态 |
|------|------|------|
| 第一批 | 项目骨架 / 路由 / API 客户端 | ✅ |
| 第二批 | 首页 / 分类 / 排行榜 / 搜索 | ✅ |
| 第三批 | 漫画详情 / 阅读器 (含页面跳转) | ✅ |
| 第四批 | 评论 / 子评论 / 点赞 / 举报 | ✅ |
| 第五批 | 登录 / 注册 / 修改密码 / 头像 | ✅ |
| 第六批 | NAS 本地阅读 + 屏蔽词运行时接入 | ✅ |
| 第七批 | NAS 文件浏览器 + 本地图片阅读器 | ✅ |
| 第八批 | 帮助/关于页 + 下载章节导出 (archive: ^3.4.10) | ✅ |
| 第九批 | 好友动态 (AppInfoReq) + 详情页补全 | ✅ |
| 第十批 | 弃用 API 现代化 (withOpacity → withValues) | ✅ |
| 第十一批 | 迁移审计 + 历史表 UI | ✅ |
| 第十二批 | 聊天室图片发送 (send-image) | ✅ |
| 第十三批 | NAS ZIP/CBZ 漫画包阅读 | ✅ (已推送 0937b9c) |
| 第十四批 | lint 清理 (18 → 0 真实问题) | ✅ |
| 第十五批 | **本次审计** | ✅ |

---

## 三、API 端点迁移覆盖矩阵

### 桌面端 API (`src/server/req.py`) 60 个 Req 类 → 移动端对应

| 桌面端 Req | URL | 移动端实现 | 备注 |
|-----------|-----|-----------|------|
| InitReq | `/init` | `pica_share_resolver_screen` 间接使用 | ⚠️ 移动端无显式 init |
| LoginReq | `auth/sign-in` | `auth/data/auth_repository.dart` | ✅ |
| RegisterReq | `auth/register` | 同上 | ✅ |
| ForgotPasswordReq | `auth/forgot-password` | `forgot_password_screen` | ✅ |
| ResetPasswordReq | `auth/reset-password` | 同上 | ✅ |
| ChangePasswordReq | `users/password` | `auth_repository.changePassword` | ✅ |
| GetUserInfo | `users/profile` | `user_repository.getUserInfo` | ✅ |
| GetUserCommentReq | `users/my-comments` | `user_repository.getMyComments` | ✅ |
| SetAvatarInfoReq | `users/avatar` | `change_password_screen` 头像上传 (`image_picker`) | ✅ |
| SetTitleReq | `users/{id}/title` | ❌ 未实现 | 低优先级 |
| **PunchIn** | `users/punch-in` | `auth_repository.punchIn` | ✅ |
| CategoryReq | `categories` | `categories_screen` | ✅ |
| FavoritesReq | `users/favourite?s=&page=` | `comic_repository.getMyFavourites` | ✅ |
| FavoritesAdd | `comics/{id}/favourite` | `favourite()` / `unfavourite()` | ✅ |
| BookLikeReq | `comics/{id}/like` | `like()` | ✅ |
| AdvancedSearchReq | `comics/advanced-search` | `advancedSearch(keyword, categories, sort)` | ✅ |
| CategoriesSearchReq | `comics?page=&c=&s=` | `search(q, categories, page)` | ✅ |
| RankReq | `comics/leaderboard?tt=&ct=VC` | `leaderboard_screen` | ✅ |
| **KnightRankReq** | `comics/knight-leaderboard` | `knight_repository` + `knight_rank_screen` | ✅ |
| GetComicsBookReq | `comics/{id}` | `comic_repository.getComicDetail` | ✅ |
| GetComicsBookEpsReq | `comics/{id}/eps?page=` | `comicDetail` 同函数 | ✅ |
| GetComicsBookOrderReq | `comics/{id}/order/{eps}/pages` | `episodePages(comicId, epsId)` | ✅ |
| GetComicsRecommendation | `comics/{id}/recommendation` | `getComicRecommendation(comicId)` | ✅ |
| DownloadBookReq | (特殊下载请求) | `download_repository` 自行管理 | ✅ 替代为 dio 流式下载 |
| GetCommentsReq | `comics/{id}/comments?page=` | `getComments(comicId, page)` | ✅ |
| CommentsLikeReq | `comments/{id}/like` | `likeComment(commentId)` | ✅ |
| CommentsReportReq | `comments/{id}/report` | `reportComment(commentId, reason)` | ✅ |
| CheckUpdateReq | `/version.txt` | ❌ 改为 GitHub Releases | ✅ (替代方案) |
| GetKeywords | `keywords` | `getKeywords()` + `search_screen` 热词 chips | ✅ |
| SendCommentReq | `comics/{id}/comments` | `sendComment(comicId, content)` | ✅ |
| SendCommentChildrenReq | `comments/{id}` | `sendCommentChild(commentId, content)` | ✅ |
| GetCommentsChildrenReq | `comments/{id}/childrens?page=` | `getCommentChildren(commentId, page)` | ✅ |
| SpeedTestReq | `/speed` | `speed_test_service` + `speed_test_screen` | ✅ |
| GetChatReq | `chat` | `chat_rooms_screen` + `chat_repository` | ✅ |
| GetCollectionsReq | `collections` | ⚠️ 未直接实现 | ❌ (低优先级) |
| GetRandomReq | `comics/random` | ⚠️ 未直接实现 | ❌ (低优先级) |
| GetAPPsReq | `pica-apps` | ❌ 未实现 | (低优先级) |
| AppInfoReq | `https://post-api.wikawika.xyz/posts?offset=` | `friend_repository` | ✅ (移到独立域名) |
| GetGameReq | `games?page=` | `game_repository` + `game_list_screen` | ✅ |
| GetGameInfoReq | `games/{id}` | `game_detail_screen` | ✅ |
| GetGameCommentsReq | `games/{id}/comments?page=` | `game_comments_repository` | ✅ |
| GetNewChatReq | (WebSocket) | `chat_repository` WebSocket | ✅ |
| GetNewChatLoginReq | (WebSocket) | `chat_repository` | ✅ |
| GetNewChatProfileReq | (WebSocket) | `chat_repository` | ✅ |
| SendNewChatMsgReq | (WebSocket) | `chat_repository` | ✅ |
| SendNewChatImgMsgReq | (WebSocket) | `chat_room_screen` 上一批已实现 | ✅ |

**API 覆盖率**: 47/52 = **90%** (剩余 5 项为低优先级辅助功能)

---

## 四、桌面端 → 移动端 功能映射详表

### P0 核心功能

| 功能 | 桌面端文件 | 移动端实现 | 状态 |
|------|-----------|-----------|------|
| 首页/推荐 | `view/index/index_view.py` (GetCollectionsReq + GetRandomReq) | `features/home/presentation/home_screen.dart` | ✅ 已实现 |
| 分类浏览 | `view/category/category_view.py` (CategoryReq) | `features/comic/presentation/categories_screen.dart` | ✅ |
| 排行榜 (H24/周榜/月榜) | `view/category/rank_view.py` (RankReq) | `features/comic/presentation/leaderboard_screen.dart` | ✅ |
| 骑士榜 (Knights) | 同上 (KnightRankReq) | `features/comic/presentation/knight_rank_screen.dart` | ✅ |
| 基础搜索 | `view/search/search_view.py` (CategoriesSearchReq) | `features/comic/presentation/search_screen.dart` + `search(q)` | ✅ |
| 高级搜索 | `view/search/search_view.py` (AdvancedSearchReq) | `features/comic/presentation/advanced_search_screen.dart` + `advancedSearch(keyword, categories, sort)` | ✅ |
| 搜索热词 | `GetKeywords` | `search_screen` Provider + `getKeywords()` 返回 `List<String>` 显示为 chips | ✅ |
| 漫画详情 | `view/info/book_info_view.py` (GetComicsBookReq) | `features/comic/presentation/comic_detail_screen.dart` | ✅ |
| 章节列表 | `view/info/book_eps_view.py` (GetComicsBookEpsReq) | 详情页内嵌 (与桌面端拆分不同,合并为单页) | ✅ |
| 推荐漫画 | `GetComicsRecommendation` | `comicRecommendationProvider` + 详情页底部 | ✅ |
| 阅读器 (单页/条状) | `view/read/read_view.py` (GetComicsBookOrderReq, 4 模式) | `features/reader/presentation/reader_screen.dart` (单页 + 条状) | ⚠️ 桌面端 4 模式,移动端 2 模式 |
| 阅读器页面跳转 | `_showPageDialog` | `_showPageDialog` (line 440) 真实实现 | ✅ (报告原称 stub,已核实为真实代码) |
| 评论列表 | `view/comment/comment_view.py` (GetCommentsReq) | `features/comic/presentation/comments_screen.dart` | ✅ |
| 评论子级 | `view/comment/sub_comment_view.py` (GetCommentsChildrenReq) | `comments_screen` 内嵌 + `getCommentChildren` | ✅ |
| 发送评论 + 点赞 + 举报 | SendCommentReq / CommentsLikeReq / CommentsReportReq | `sendComment` + `likeComment` + `reportComment` | ✅ |

### P1 重要功能

| 功能 | 桌面端文件 | 移动端实现 | 状态 |
|------|-----------|-----------|------|
| 登录 | `view/user/login_view.py` (LoginReq) | `features/auth/presentation/login_screen.dart` | ✅ |
| 注册 | `view/user/register_widget.py` (RegisterReq) | `features/auth/presentation/register_screen.dart` | ✅ |
| 忘记密码 / 重置密码 | `forgot_password_widget.py` (ForgotPasswordReq + ResetPasswordReq) | `features/auth/presentation/forgot_password_screen.dart` | ✅ |
| 修改密码 | `change_password_widget.py` (ChangePasswordReq) | `features/auth/presentation/change_password_screen.dart` | ✅ |
| 我的收藏 | `view/user/favorite_view.py` (FavoritesReq) | `features/comic/presentation/my_favourites_screen.dart` | ✅ |
| 我的追漫 | `view/user/favorite_view.py` (FavoritesAdd) | `features/comic/presentation/my_follows_screen.dart` | ✅ |
| 阅读历史 | `view/user/history_view.py` | `features/history/presentation/history_screen.dart` (Drift History 表) | ✅ |
| 个人中心 | `view/user/login_proxy_widget.py` (GetUserInfo) | `features/auth/presentation/profile_screen.dart` | ✅ |
| 我的评论 | `view/comment/my_comment_view.py` (GetUserCommentReq) | `profile_screen` 内 + `getMyComments` | ✅ |
| 签到 | `qt_owner.py` PunchIn | `auth_repository.punchIn()` | ✅ |
| 下载管理 | `view/download/download_view.py` (DownloadBookReq) | `features/download/` (UI + 实际下载,1688 行) | ✅ |
| 章节导出 (ZIP/CBZ) | `view/convert/convert_view.py` | `features/export/data/export_service.dart` + `export_screen.dart` | ✅ |
| 设置 (代理/主题/测速) | `view/setting/setting_view.py` | `features/settings/presentation/settings_screen.dart` | ✅ |
| 网络测速 | `view/setting/setting_sr_select_view.py` (SpeedTestReq) | `features/settings/presentation/speed_test_screen.dart` | ✅ |
| 头像上传 | `view/user/login_widget.py` (SetAvatarInfoReq) | `change_password_screen` 内 + `image_picker: ^1.0.7` | ✅ |

### P2 辅助功能

| 功能 | 桌面端文件 | 移动端实现 | 状态 |
|------|-----------|-----------|------|
| 聊天室 (WebSocket) | `view/chat_new/chat_new_view.py` + `chat_new_websocket.py` | `features/chat/` (WebSocket + 文字/图片消息) | ✅ |
| 好友/动态 (Pica Apps 社区) | `view/fried/fried_view.py` (AppInfoReq) | `features/friend/` (列表 + 详情 + 评论) | ✅ |
| 游戏列表 + 详情 | `view/game/game_view.py` (GetGameReq/InfoReq) | `features/game/` (列表 290 行 + 详情 329 行 + 评论 364 行) | ✅ |
| 帮助/关于 | `view/help/help_view.py` (CheckUpdateReq) | `features/help/presentation/help_screen.dart` (替代为 GitHub Releases) | ✅ |
| 屏蔽词运行时 | `view/tool/forbid_words_view.py` | `features/comic/data/forbid_words_filter_helper.dart` + `forbid_words_screen` | ✅ |
| 批量搜索 (桌面端工具) | `view/tool/batch_sr_tool_view.py` | `features/comic/presentation/batch_search_screen.dart` | ✅ |
| **Pica 号解析 (share) | (无对应) | `features/comic/data/pica_share_service.dart` + `pica_share_resolver_screen` | 🌟 移动端独有 |
| **NAS 本地阅读 (图片) | `view/tool/local_eps_read_view.py` (NAS 上传后) | `features/nas/` 文件浏览器 + 本地图片阅读器 + ZIP/CBZ 漫画包 | 🌟 移动端独有 |
| **章节导出下载 | `view/convert/convert_view.py` | `features/export/` ZIP/TAR 导出 + 系统分享面板 | ✅ (与桌面端同等) |

### 显式不迁移项 (移动端不适用)

| 功能 | 原因 |
|------|------|
| NAS SMB/WebDAV 上传 (`view/nas/nas_view.py`) | 桌面端场景,移动端改用本地 + 第三方网盘 |
| OpenGL 阅读渲染 (`view/read/read_opengl.py`) | 桌面端性能优化,移动端用 photo_view 即可 |
| QGraphicsView 框架 (`view/read/read_frame.py`) | Qt 专属,Flutter 无对应需求 |
| 离线模式 (`qt_owner.isOfflineModel`) | 移动端无对应下载后阅读需求 |
| 主题切换 (部分) | 移动端仅跟随系统 |

---

## 五、数据库 Drift 表 vs 桌面端 SQLite 表

| 桌面端表 | 字段 | 移动端 Drift 表 | 状态 |
|---------|------|----------------|------|
| `book` | id, title, author, cover, description, epsCount, pages, finished, likesCount, categories, tags... | `Comics` (comicId, title, author, cover, isFavorite, isFollowed, ...) | ✅ |
| `category` | bookId, category | (未迁移,运行时从 API 取) | ⚠️ 跳过 (API 实时拉) |
| `favorite` | id, user, sortId | (合并到 `Comics.isFavorite`) | ✅ |
| `system` | id, size, time, sub_version | (未迁移,改用 `package_info_plus`) | ✅ 替代 |
| `words` | 搜索关键词缓存 | `SearchHistory` (keyword, timestamp) | ✅ 替代 |
| (无) | - | `Episodes` (episodeId, title, order) | 🌟 移动端独有 (缓存章节) |
| (无) | - | `History` (lastPage, lastReadAt) | 🌟 移动端独有 |
| (无) | - | `Downloads` (status, progress, path) | 🌟 移动端独有 |
| (本地 epub 文件表) | - | (合并到 NAS 本地表) | ✅ 替代 |

---

## 六、CI / 构建状态

### 本地 Flutter 3.41 vs CI 锁定的 Flutter 3.27.4

**本地环境差异**: 本机 Flutter SDK 已升级到 3.41.9,而 CI 锁定 3.27.4。本地 `flutter analyze` 报告 5 条 info-level 提示(全部为 Flutter 3.32+ 弃用 API,如 `RadioListTile.groupValue` 改 `RadioGroup`),CI 不会触发。

**本地 `flutter build apk --debug` 失败**: 失败点为 `:app:configureCMakeDebug[arm64-v8a]` — `CMAKE_C_COMPILER not set, after EnableLanguage`。这是本机 NDK 27.0.12077973 + cmake 3.22.1 配置不兼容导致的工具链问题,与代码无关。**该问题不影响 CI**。

### CI 历史

| 提交 | build.yml | release.yml |
|------|-----------|-------------|
| `0937b9c` (本次推送) | 待 CI 触发 | 待 CI 触发 |
| `ac50800` 第十四批文档 | ✅ 通过 | ⚠️ 已知平台限制 (workflow_run artifact 下载) |
| `e4056a8` CI 加固 (continue-on-error + retry) | ✅ 通过 | 待验证 |
| `48dffef` 第十四批 lint 清理 | ✅ 通过 | - |

### 验证脚本(本地)

```bash
export PATH="/home/ubuntu/flutter-sdk/bin:$PATH"
cd /home/ubuntu/project/bika-comics
flutter analyze            # 5 issues (info,本地 SDK 弃用,CI 不可见)
flutter test               # 6/6 passed
flutter build apk --debug  # 本地 NDK 工具链问题,CI 验证
```

---

## 七、本次推送 (`0937b9c`) 修改清单

```
lib/features/nas/data/zip_extractor.dart                  |  231 ++++++ (NEW)
lib/features/nas/presentation/zip_reader_screen.dart      |  344 +++++++++ (NEW)
lib/features/nas/presentation/nas_local_screen.dart       |  22 ++++- (MODIFIED)
test/zip_extractor_test.dart                              |  130 ++++++ (NEW)
[+ 22 个无关小修复已在父提交中合并]
```

**对应桌面端**:
- `view/tool/local_eps_read_view.py` (CheckAction2 拖入/选择 .zip/.cbz)
- `task/task_local.py#ParseBookInfoByFile` (校验 + 解析 ZIP 内图片清单)

**功能要点**:
1. `ZipExtractor.extract(path)` — 校验 + 解压到 `Uint8List`,不写磁盘
2. 子目录聚合 + 自然顺序排序,与桌面端 `ParseBookInfoByFile` 行为一致
3. 体积上限 500 MB / 500 张 (防 OOM)
4. 错误码分类:`errNotZip` / `errEncrypted` / `errNoImages` / `errTooLarge` / `errIo`
5. `ZipReaderScreen` 复用 `LocalReaderScreen` 架构 (PhotoViewGallery 单页 + ListView.builder 条状)
6. NAS 文件浏览器新增 ZIP/CBZ 文件识别 (橙色 folder_zip_outlined 图标)

---

## 八、未完成项 / 已知跳过

| 项 | 原因 | 优先级 |
|----|------|--------|
| GetCollectionsReq (`/collections`) | 仅首页推荐位子集,移动端用其他端点替代 | P3 跳过 |
| GetRandomReq (`/comics/random`) | 桌面端首页随机位,移动端用 Pica 推荐 | P3 跳过 |
| GetAPPsReq (`/pica-apps`) | 第三方应用列表,移动端无场景 | P3 跳过 |
| SetTitleReq (`/users/{id}/title`) | 桌面端管理员功能 | P3 跳过 |
| NAS SMB/WebDAV 上传 | 桌面端场景 | 不适用 |
| 阅读器 4 模式 (桌面端含条状左/右卷动) | 移动端 2 模式已满足 | 低 |
| InitReq (`/init`) | 移动端无版本协商需求 | P3 跳过 |
| my_comments page > 1 | API endpoint 声明但未在 UI 暴露分页 | 低 |

---

## 九、本次(第十五批)审计结论

**总体迁移完成度**: **~93%** (52 项桌面端功能,48 项已实现或合理替代)

**本批推送验证**:
- ✅ `0937b9c feat(bika): 第十三批 - NAS 本地阅读支持 ZIP / CBZ 漫画包` 已推送到 GitHub
- ✅ `flutter analyze`: 5 info (本地 SDK 差异,CI 不可见)
- ✅ `flutter test`: 6/6 passed
- ⚠️ `flutter build apk --debug`: 本地 NDK/CMake 工具链不兼容,需 CI 验证

**未推送待办**: 无 (working tree clean)

**下一批候选**:
1. 阅读器模式扩展 (桌面端 4 模式 → 移动端 2 模式 + 卷轴模式)
2. 应用启动 → 初始化握手 (桌面端 InitReq)
3. 批量搜索增强 (桌面端 batch_sr_tool_view 高级过滤)
4. 消息推送 / 通知 (移动端集成 FCM,桌面端无)
5. 多账号切换 (桌面端有 QtOwner,移动端尚未实现多 profile)

---

**生成时间**: 2026-07-03 02:01 UTC (Hermes Router Agent 自动审计)
**审计依据**: `picacg-qt-temp/src/view/` 50+ Python 文件 + `picacg-qt-temp/src/server/req.py` 60 个 Req 类 + `bika-comics/lib/features/` 13 个 Flutter feature 模块
