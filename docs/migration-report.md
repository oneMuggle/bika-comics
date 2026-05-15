# 哔咔漫画 桌面端→移动端 迁移分析报告

## 一、项目概况

Two projects:
- Desktop (reference): /home/ubuntu/project/picacg-qt-temp (Python/Qt)
- Mobile (target): /home/ubuntu/project/bika-comics (Flutter/Riverpod)

## 二、桌面端功能清单 (src/view/)

### P0 - 核心功能
| 功能 | 文件 | 说明 |
|------|------|------|
| 首页/推荐 | view/index/index_view.py | GetCollectionsReq, GetRandomReq |
| 分类浏览 | view/category/category_view.py | CategoryReq |
| 排行榜 | view/category/rank_view.py | RankReq, KnightRankReq |
| 搜索 | view/search/search_view.py | AdvancedSearchReq, CategoriesSearchReq, GetKeywords |
| 漫画详情 | view/info/book_info_view.py | GetComicsBookReq, GetComicsBookEpsReq |
| 漫画阅读器 | view/read/read_view.py | GetComicsBookOrderReq (多模式: 上下/左右/滚动) |
| 评论 | view/comment/, view/widget/comment_widget.py | GetCommentsReq, SendCommentReq, CommentsLikeReq |

### P1 - 重要功能
| 功能 | 文件 | 说明 |
|------|------|------|
| 登录/注册 | view/user/login_view.py | LoginReq, RegisterReq |
| 收藏/追漫 | view/user/favorite_view.py | FavoritesReq, FavoritesAdd, BookLikeReq |
| 阅读历史 | view/user/history_view.py | 记录在SQLite |
| 下载管理 | view/download/download_view.py | DownloadBookReq, 任务队列 |
| 个人中心 | view/user/ | 用户信息、修改密码、签到 |

### P2 - 辅助功能
| 功能 | 文件 | 说明 |
|------|------|------|
| 聊天室 | view/chat/ | WebSocket实时聊天 |
| 好友/动态 | view/fried/ | AppInfoReq 社区帖子 |
| 游戏 | view/game/game_view.py | GetGameReq |
| 设置 | view/setting/setting_view.py | 代理、主题、Waifu2x |
| NAS上传 | view/nas/ | SMB/WebDAV |
| 帮助/更新 | view/help/ | CheckUpdateReq |

## 三、移动端现状 (lib/features/)

### 已实现功能
| 功能 | 状态 | 文件 |
|------|------|----------|
| 首页推荐 | ✅ 已实现 | lib/features/comic/presentation/comic_list_screen.dart |
| 分类浏览 | ✅ 已实现 | lib/features/comic/presentation/categories_screen.dart |
| 排行榜 | ✅ 已实现 | lib/features/comic/presentation/leaderboard_screen.dart |
| 搜索 | ✅ 已实现 | lib/features/comic/presentation/search_screen.dart |
| 漫画详情 | ✅ 已实现 | lib/features/comic/presentation/comic_detail_screen.dart |
| 漫画阅读器 | ⚠️ 基础实现 | lib/features/reader/presentation/reader_screen.dart (photo_view, _showPageDialog为stub) |
| 评论 | ✅ 已实现 | lib/features/comic/presentation/comments_screen.dart |
| 登录/注册 | ✅ 已实现 | lib/features/auth/ |
| 收藏/追漫 | ✅ 已实现 | lib/features/comic/ |
| 我的收藏 | ✅ 已实现 | lib/features/comic/presentation/my_favourites_screen.dart |
| 我的追漫 | ✅ 已实现 | lib/features/comic/presentation/my_follows_screen.dart |
| 设置 | ⚠️ 部分实现 | lib/features/settings/presentation/settings_screen.dart (无阅读方向/质量设置) |
| 下载管理 | ❌ 仅UI占位 | lib/features/download/ (DownloadTask模型存在,无实际下载) |

### 未实现功能
| 功能 | 优先级 | 说明 |
|------|--------|------|
| 阅读历史 | P1 | 桌面端有HistoryView,移动端database.dart有History表但无UI |
| 排行榜(骑士榜) | P0 | KnightRankReq 未对接 |
| 签到(Punch-in) | P1 | 桌面端有,移动端无 |
| 高级搜索过滤 | P0 | CategoriesSearchReq categories参数未对接 |
| 阅读器页面跳转 | P0 | _showPageDialog是stub |
| 下载实现 | P1 | 仅有UI无实际下载逻辑 |
| 聊天室 | P2 | WebSocket实现缺失 |
| 好友/动态 | P2 | FriedView缺失 |
| 游戏 | P2 | GameView缺失 |
| NAS上传 | P2 | 不适用于移动端(可跳过) |
| 帮助/更新检查 | P2 | HelpView缺失 |
| 搜索热词 | P1 | GetKeywords未对接 |

## 四、API端点覆盖对比

### 桌面端API (src/server/req.py)
| 端点 | 方法 | 移动端状态 |
|------|------|----------|
| init | GET | ❌ |
| auth/sign-in | POST | ✅ |
| auth/register | POST | ✅ |
| auth/forgot-password | POST | ❌ |
| auth/reset-password | POST | ❌ |
| users/password | PUT | ❌ |
| users/profile | GET | ⚠️ 登录时获取 |
| users/my-comments | GET | ❌ |
| users/avatar | PUT | ❌ |
| users/punch-in | POST | ❌ |
| users/favourite | GET | ✅ |
| comics/{id}/favourite | POST | ✅ |
| comics/{id}/like | POST | ✅ |
| comics/advanced-search | POST | ⚠️ keyword未传 |
| comics?page=&c=&s= | GET | ⚠️ 未实现分类搜索 |
| comics/leaderboard | GET | ✅ |
| comics/knight-leaderboard | GET | ❌ |
| comics/{id} | GET | ✅ |
| comics/{id}/eps | GET | ✅ |
| comics/{id}/order/{eps}/pages | GET | ✅ |
| comics/{id}/comments | GET/POST | ✅ |
| comics/{id}/recommendation | GET | ❌ |
| comments/{id}/like | POST | ✅ |
| comments/{id}/report | POST | ❌ |
| comments/{id} | POST | ✅ (child) |
| categories | GET | ✅ |
| keywords | GET | ❌ |
| collections | GET | ❌ |
| games | GET | ❌ |
| games/{id}/comments | GET/POST | ❌ |
| chat | GET | ❌ |
| pica-apps | GET | ❌ |

## 五、迁移优先级与文件清单

### P0 必须迁移 (当前缺失或不可用)
1. **阅读器页面跳转功能** - lib/features/reader/presentation/reader_screen.dart
   - 问题: _showPageDialog (line 253-256) 是空stub
   - 修复: 实现对话框和页面跳转逻辑

2. **分类搜索** - lib/core/api/api_client.dart
   - 新增: CategoriesSearchReq categories参数支持
   - 修改: comic_repository.dart 的分类搜索方法

3. **骑士排行榜** - lib/features/comic/data/comic_repository.dart
   - 新增: getKnightLeaderboard() 方法
   - 新增: lib/features/comic/presentation/knight_leaderboard_screen.dart

4. **搜索热词** - lib/core/api/api_client.dart
   - 新增: getKeywords() 端点
   - 新增: lib/features/comic/presentation/search_screen.dart 显示热词chips

5. **高级搜索keyword参数** - lib/core/api/api_client.dart
   - 修复: advancedSearch() 确保keyword参数正确传递

### P1 重要功能迁移
6. **阅读历史** - lib/features/history/
   - 新增: history_screen.dart (UI)
   - 新增: history_repository.dart (对接History表)
   - 新增: History模型

7. **签到功能** - lib/features/auth/data/auth_repository.dart
   - 新增: punchIn() 方法
   - 新增: punch-in API端点
   - UI: 个人中心添加签到按钮

8. **漫画推荐** - lib/features/comic/
   - 新增: getComicRecommendation(comicId) 
   - 新增: comic_recommendation_screen.dart

9. **下载实现** - lib/features/download/
   - 实现: 实际图片下载逻辑
   - 对接: DownloadBookReq 或直接用Dio下载

10. **设置-阅读偏好** - lib/features/settings/
    - 新增: 阅读方向(LTR/RTL/Vertical)
    - 新增: 图片质量选择
    - 新增: 自动续读开关

### P2 辅助功能
11. **评论举报** - lib/features/comic/data/comic_repository.dart
    - 新增: reportComment(commentId)

12. **游戏列表** - lib/features/game/
    - 新增: game_list_screen.dart
    - 新增: game_repository.dart

13. **好友/动态** - lib/features/fried/ (可选，移动端不适合)

14. **聊天室** - lib/features/chat/ (可选，实现复杂)

15. **更新检查** - lib/features/settings/settings_screen.dart
    - 新增: 版本更新检查逻辑

## 六、数据库差异

### 桌面端SQLite (src/db/)
- book表: id, title, author, cover, description, epsCount, pages, finished, likesCount, categories, tags...
- category表: bookId, category
- favorite表: id, user, sortId
- system表: id, size, time, sub_version
- words表: 搜索关键词缓存

### 移动端Drift (lib/core/db/)
- Comics表: comicId, title, author, cover, isFavorite, isFollowed ✅
- Episodes表: episodeId, title, order ✅
- History表: lastPage, lastReadAt ✅ (有表无UI)
- Downloads表: status, progress ✅ (有表无实现)
- SearchHistory表: keyword, timestamp ✅

**缺失**: category表(分类缓存), words表(搜索热词缓存), system表(版本信息)

## 七、已知问题

1. Reader _showPageDialog stub - 需实现页面跳转对话框
2. 下载仅有UI无逻辑 - 需实现Dio下载+本地存储
3. KnightRankReq未对接 - 需新增骑士排行榜
4. GetKeywords未对接 - 搜索页无热词
5. CategoriesSearchReq categories参数未实现 - 分类搜索不完整
6. 阅读历史有表无UI - HistoryView缺失
7. Punch-in签到未实现 - 个人中心无签到入口
8. 移动端无评论回复嵌套显示逻辑

## 八、CI/CD现状

- GitHub Actions: .github/workflows/build.yml
- Flutter 3.24.0 + Android SDK
- drift + build_runner 代码生成
- Debug APK构建正常
- Release APK需keystore配置

---
生成时间: 基于代码分析自动生成