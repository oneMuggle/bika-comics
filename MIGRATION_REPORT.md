# 哔咔漫画 桌面端→移动端 迁移分析报告

## 桌面端完整功能列表 (Picacg Qt)

| 功能模块 | 状态 | 核心文件 |
|---------|------|---------|
| 首页推荐 | ✅ | `view/index/index_view.py` |
| 随机推荐 | ✅ | `view/index/index_view.py` |
| 分类浏览 | ✅ | `view/category/category_view.py` |
| 排行榜 | ✅ | `view/category/rank_view.py` |
| 搜索 | ✅ | `view/search/search_view.py` |
| 高级搜索 | ✅ | `view/search/search_view.py` |
| 漫画详情 | ✅ | `view/info/book_info_view.py` |
| 漫画阅读器 | ✅ | `view/read/read_view.py` |
| 收藏功能 | ✅ | `server/req.py` |
| 追漫功能 | ✅ | `server/req.py` |
| 评论功能 | ✅ | `view/comment/` |
| 用户登录注册 | ✅ | `view/user/` |
| 设置页面 | ✅ | `view/setting/setting_view.py` |
| 下载管理 | ✅ | `view/download/` |
| 本地阅读 | ✅ | `view/nas/` |
| 搜索历史 | ✅ | SQLite本地存储 |
| 骑士榜 | ✅ | `server/req.py` |

## 移动端已有功能列表 (Flutter)

| 功能模块 | 状态 | 文件 |
|---------|------|------|
| 首页推荐 | ✅ | `features/comic/presentation/comic_list_screen.dart` |
| 漫画详情 | ✅ | `features/comic/presentation/comic_detail_screen.dart` |
| 阅读器 | ✅ | `features/reader/presentation/reader_screen.dart` |
| 搜索 | ✅ | `features/comic/presentation/search_screen.dart` |
| 登录注册 | ✅ | `features/auth/` |
| 设置页面 | ✅ | `features/settings/presentation/settings_screen.dart` |
| 下载页面 | ⚠️ | `features/download/presentation/download_screen.dart` (空壳) |
| 数据库 | ✅ | `core/db/database.dart` |
| API Client | ✅ | `core/api/api_client.dart` |

## 功能差距对比 (Gap Analysis)

### P0 - 关键功能 (缺失)

| 功能 | 优先级 | 桌面端对应 | 说明 |
|-----|-------|-----------|------|
| 分类浏览 | P0 | `view/category/category_view.py` | 分类筛选看漫画 |
| 排行榜 | P0 | `view/category/rank_view.py` | 各种榜单 |
| 收藏功能 | P0 | API `/comics/{id}/favourite` | 收藏/取消收藏 |
| 追漫功能 | P0 | API `/comics/{id}/follow` | 追漫/取消追漫 |
| 点赞功能 | P0 | API `/comics/{id}/like` | 点赞漫画 |

### P1 - 重要功能 (部分实现)

| 功能 | 优先级 | 桌面端对应 | 说明 |
|-----|-------|-----------|------|
| 评论功能 | P1 | `view/comment/` | 查看/发送评论 |
| 阅读历史 | P1 | SQLite | 记录阅读历史 |
| 高级搜索 | P1 | `view/search/search_view.py` | 分类+关键词搜索 |
| 我的收藏 | P1 | API `/my/favourites` | 收藏列表 |
| 我的追漫 | P1 | API `/my/follows` | 追漫列表 |
| 搜索历史 | P1 | SQLite | 本地搜索历史 |

### P2 - 增强功能 (暂不需要)

| 功能 | 优先级 | 说明 |
|-----|-------|------|
| 骑士榜 | P2 | 排行榜特殊榜单 |
| 本地阅读 | P2 | NAS/本地漫画 |
| Waifu2x | P2 | 图片放大 |
| 多阅读模式 | P2 | 双页/滚动等 |

## API Endpoints 差异

### 桌面端使用的 API (req.py):
- `POST /auth/sign-in` - 登录
- `POST /auth/register` - 注册
- `GET /categories` - 获取分类
- `GET /comics` - 漫画列表 (支持 `?s=dd&page=1`)
- `GET /comics/leaderboard` - 排行榜
- `POST /comics/advanced-search` - 高级搜索
- `GET /comics/{id}` - 漫画详情
- `GET /comics/{id}/eps` - 章节列表
- `GET /comics/{id}/eps/{epsId}/pages` - 章节图片
- `POST /comics/{id}/favourite` - 收藏
- `POST /comics/{id}/follow` - 追漫
- `POST /comics/{id}/like` - 点赞
- `GET /comics/{id}/comments` - 评论
- `GET /users/favourite` - 我的收藏
- `GET /users/my-comments` - 我的评论

### 移动端已有 API (api_constants.dart):
大部分已定义，需要检查实现是否正确。

## 迁移计划

### Phase 1: P0 功能迁移
1. 添加分类浏览页面
2. 添加排行榜页面
3. 实现收藏/追漫/点赞功能
4. 实现我的收藏页面
5. 实现我的追漫页面

### Phase 2: P1 功能迁移
1. 添加评论功能
2. 添加阅读历史
3. 完善高级搜索
4. 完善设置页面

### Phase 3: P2 功能迁移
1. 本地阅读功能
2. 高级阅读模式

## CI/CD 状态

- ✅ `flutter pub get` 正常
- ✅ `dart run build_runner build` 正常
- ⚠️ `flutter build apk` 需要 Android SDK (CI环境已配置)
- ⚠️ 本地编译失败是因为 `sqlite3_flutter_libs` 使用 FFI，web平台不支持
  - 解决方案: 条件导入或等待 `package:sqlite3_wasm` 支持
  - CI环境使用 Android 构建，不受影响
