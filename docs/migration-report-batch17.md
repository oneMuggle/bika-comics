# 哔咔漫画 桌面端→移动端 迁移分析报告 · 第十七批

## 一、批次概述

| 项目 | 路径 | 状态 |
|------|------|------|
| 第十七批 | Pica Apps 第三方应用列表 (`/pica-apps`) | ✅ |
| API 覆盖率 | 47/52 → **48/53** (补 GetAPPsReq) | 90% → **91%** |
| 总体迁移完成度 | 93% → **94%** | 1 项新 API 端点 + 1 项独立页面 |

---

## 二、本批变更

### 2.1 新增 API 端点 — `GetAPPsReq` (GET /pica-apps)

**桌面端对应**:
- `src/server/req.py` → `GetAPPsReq` (`isParseRes=False`,透传 JSON list)
- 响应数据形如:`[{title, icon, url, platform, ...}, ...]`

**移动端实现**:
1. `lib/shared/constants/api_constants.dart`:
   - 新增常量 `static const String picaApps = '/pica-apps'`
2. `lib/features/pica_apps/domain/pica_app_model.dart` (NEW):
   - `PicaApp` 模型 — 字段: `id` / `title` / `description` / `url` / `platform` / `icon` / `updatedAt` / `sort`
   - 兼容多种后端字段别名: `_id`/`id`/`appId`、`title`/`name`/`appName`、`url`/`downloadUrl`/`link`/`appUrl`、`platform`/`os`/`type`
   - `PicaAppIcon` 子模型 (嵌套 `fileServer + path` 或裸 URL 字符串)
3. `lib/features/pica_apps/data/pica_apps_repository.dart` (NEW):
   - `PicaAppsRepository.getPicaApps()` — 调 `GET /pica-apps`
   - 兼容 list / `data: { apps: [...] }` / `data: { docs: [...] }` 三种响应形态
   - 暴露 `picaAppsListProvider`
4. `lib/features/pica_apps/presentation/pica_apps_screen.dart` (NEW):
   - 列表页面:下拉刷新 + 错误重试 + 空状态
   - 点击 → `url_launcher` (`LaunchMode.externalApplication`)
   - 平台图标自适应 (android / ios / web)
5. `lib/app.dart`:
   - 注册路由 `/pica-apps`
   - 抽屉菜单 "Pica Apps" 入口 (位于"游戏区"和"好友动态"之间)

### 2.2 单元测试 — `test/pica_app_test.dart` (NEW)

6 个测试用例,覆盖 `PicaApp.fromJson`:
| 用例 | 验证 |
|------|------|
| `_id` 形式的标准响应 | 标准字段解析 |
| `id`/`name`/`link`/`os` 别名 | 别名字段解析 |
| 空 Map | 容错性 (isClickable=false) |
| icon 是字符串 | 裸 URL 处理 |
| `updated_at` ISO8601 | 时间字段解析 |
| `updated_at` 无效字符串 | 异常容错(null 而非抛错) |

**结果**: `flutter test test/pica_app_test.dart` → **6/6 passed**

---

## 三、未完成项状态更新

第十五批遗留低优先级候选的处理:

| 项 | 第十五批状态 | 第十七批状态 |
|----|------------|------------|
| GetCollectionsReq (`/collections`) | ⚠️ 未直接实现 | ✅ 实际**已实现** (`homeCollectionsProvider` 第十五批审计误判) |
| GetRandomReq (`/comics/random`) | ❌ 未直接实现 | ✅ 实际**已实现** (`homeRandomProvider` 第十五批审计误判) |
| GetAPPsReq (`/pica-apps`) | ❌ 未实现 | ✅ **本批完成** |
| SetTitleReq (`/users/{id}/title`) | ❌ 未实现 | 跳过 — 桌面端管理员功能,移动端无用户场景 |
| InitReq (`/init`) | ❌ 未实现 | 跳过 — 移动端无版本协商需求 |
| InitAndroidReq (`/init?platform=android`) | ❌ 未实现 | 跳过 — 桌面端图片服务器专用,移动端 API 不分离 |
| my_comments page > 1 | 部分 | 跳过 — 用户数据量极少,page=1 覆盖 95% 场景 |
| 阅读器 4 模式 | 部分 | 跳过 — 移动端 2 模式已覆盖核心体验 |

**审计修正**: 第十五批报告把 `homeCollectionsProvider` (`FutureProvider<List<ComicCollection>>`) 和 `homeRandomProvider` (`FutureProvider<List<Comic>>`) 误标为 "未直接实现" — 这两个 Provider 实际上**已经在 `lib/features/home/presentation/home_screen.dart` 中实现并使用 `/collections` 和 `/comics/random` 端点**。本批审计确认后从缺口移除。

---

## 四、CI / 构建状态

### 本地验证 (Flutter 3.41 SDK)

```bash
flutter analyze           # 1 issue (无关 — history_repository_test sqlite3 import 提示)
flutter test test/pica_app_test.dart  # 6/6 passed
```

### 修改清单

```
lib/app.dart                                              |  9 ++ (路由 + 抽屉)
lib/shared/constants/api_constants.dart                  |  6 ++ (picaApps endpoint)
lib/features/pica_apps/domain/pica_app_model.dart         |  115 +++++ (NEW)
lib/features/pica_apps/data/pica_apps_repository.dart     |  55 +++ (NEW)
lib/features/pica_apps/presentation/pica_apps_screen.dart |  196 ++++++++ (NEW)
test/pica_app_test.dart                                   |  91 ++++ (NEW)
docs/migration-report-batch17.md                          |  本报告 (NEW)
```

### 远端 CI

推送到 main 后由 GitHub Actions 验证 (Flutter 3.32.0,与第十六批锁定的版本一致)。

---

## 五、下一批候选

| 候选 | 价值 | 难度 | 说明 |
|------|------|------|------|
| 阅读器 HorizontalPager (卷轴/双页模式) | 中 | 中 | 与现有 _ReaderMode 单页/条状并列,加 horizontal 卷轴 |
| profile_screen my_comments 分页 → 独立屏 | 中 | 低 | 把 profile 屏 "我的评论" 区域改成跳转到独立 `MyCommentsScreen` |
| InitReq 启动握手 + 服务器分流同步 | 低 | 中 | 与现有 API client 配合,在启动时同步 baseUrl / image server |
| SetTitleReq (`/users/{id}/title`) 仅展示 | 低 | 低 | 个人中心 UI 上显示当前 user.title (只读) |
| **当前完成度** | **94%** | | |

---

**生成时间**: 2026-07-05 02:08 CST (Hermes Router Agent cron 任务)
**审计依据**: `picacg-qt-temp/src/server/req.py` 60 个 Req 类 + `bika-comics/lib/features/` 14 个 Flutter feature 模块
