# 第六十二批：桌面端→移动端 迁移审计与在途代码收尾

- 日期：2026-11-28
- 桌面端（参考）：`/home/ubuntu/project/picacg-qt-temp`（Python + Qt，89 个 UI 文件）
- 移动端（目标）：`/home/ubuntu/project/bika-comics`（Flutter + Riverpod，78 个 Dart 文件，36 个界面）
- 本批性质：**在途代码收尾 + 缺陷修复**（非从零迁移）

---

## 一、任务前提核实（3 步法）

本 cron 模板自 2026-07-17 起以"全盘分析 → P0/P1/P2 迁移 → 编译 → 推送"反复触发，
此前 33 批（batch25–57）均为"前提过期"审计。本批核实结果：

| 步骤 | 结果 |
|---|---|
| 1. 读最新批次报告 | `docs/migration-report-batch59.md`：API 签名机制（P0）已补齐，剩余项为环境受限 |
| 2. 盘点代码面 | 移动端 78 个 Dart 文件 / 36 个界面 / 14 个 feature 目录，端点差分显示 **desktop-only = 0** |
| 3. 本地基线检查 | `flutter analyze` 干净；`flutter test` **149 通过 / 2 失败** |

**结论：桌面端已无迁移缺口（desktop-only 端点 = 0）。** 但工作区存在
**batch #62 的未提交在途代码**（8 改 + 30 未跟踪），含 2 个真实缺陷 ——
按 pitfall #36，在途代码本身就是本批的交付物。

---

## 二、端点差分（脚本化，可复跑）

`tool/endpoint_full_diff.py`（对照桌面端 `src/server/req.py` 与移动端 `lib/`）：

- 桌面端端点形态：**39**
- 移动端 URL 形态：**87**
- **desktop-only = 0** → 桌面端的功能面已被移动端完全覆盖
- mobile-only = 48 → 移动端**增强**（`comics/{}/follow`、`my/follows`、`tags`、
  `speed`、`auth/logout`、Pica Apps、批量搜索、NAS 本地浏览器等），非缺失

---

## 三、本批修复的缺陷

### 3.1 继承测试的夹具与真实 API 形态矛盾（2 个失败）

`flutter test` 报 2 失败。**失败的是夹具，不是实现** —— 用桌面端源码求值判定：

| 失败测试 | 夹具假设 | 真实形态（桌面端源码证据） | 判定 |
|---|---|---|---|
| `episode_pagination_test` | API 第 1 页 = **最老**的章 | 第 1 页 = **最新**的章 | 夹具虚构 |
| `episode_order_test` | mock 无条件让第 2 组挂起 | 两个用例共用一个 mock，正常翻页用例被拖死 | 夹具缺陷 |

**证据 1 — 分页标签（`src/view/info/book_info_view.py:448-450`）**

```python
start = info.epsCount - i*info.epsLimit*1
end   = max(1, info.epsCount - (i+1)*info.epsLimit + 1)
```

389 章 / limit 200 → 第 1 个标签 `"389-190"`，即**第 1 页是最新的 200 章**。

**证据 2 — 行章节号（`src/view/info/book_info_view.py:490`）**

```python
epsId = (info.epsCount - index*info.epsLimit) - 1 - i
```

第 1 页（index=0）第一行章节号 = `epsCount` → 最新的一章。

**证据 3 — 存储下标与渲染顺序**

- `src/tools/book.py:183`：`index = epsCount - epsLimit*(page-1) - i - 1` → index 0 = 最老
- `src/view/info/book_eps_view.py:105`：`for index in range(0, info.epsCount)` → **升序渲染**

⇒ API page 1 = 最新；桌面端展示 = **最老在前**。移动端必须按该下标升序排序，
把 page 2..N 直接追加在 page 1 之后会保留"最新在前"，与桌面端相反。

结论已固化为可复跑脚本 **`tool/verify_eps_page_orientation.py`**
（直接读取桌面端源码求值，零样本硬失败），不再是凭印象。

**修复**：
- `test/episode_pagination_test.dart` — mock 改为按"最新在前"构造
- `test/episode_order_test.dart` — 引入 `hangSecondPage` 开关，
  仅取消用例挂起第 2 组；正常用例每组返回**不同**图片（原先每组返回同一张，
  计数断言无区分力）

### 3.2 确认继承实现的正确性（未改动，但已用真实数据复核）

| 断言 | 复核方式 | 结果 |
|---|---|---|
| `sortEpisodesByDesktopOrder` 等价于桌面端公式 | `tool/verify_episode_order_fixed.py` 直接 `eval` 桌面端 `book.py:183` 的表达式 | **6/6 案例全等** |
| 真实数据规模 | `tool/verify_batch62_claims.py` 查 150,574 行真实抓取库 | **4/4 断言 MATCH** |
| `?page=N` 参与签名 | `tool/verify_signature_page_param.py` 跨语言比对 | **签名一致** |
| 章节图片分页真实缺口 | `tool/verify_capture_pagination.py` | 单章漫画 **6,354 部**一章超 200 张，最大 **4,896 张 = 25 组** |
| 章节列表分页真实缺口 | 同上 | **22 部**漫画章节数超 200（epsCount 最高 389） |

### 3.3 死常量复核（pitfall #45：避免误报）

`tool/audit_dead_constants.py` 报 8 个"无消费者"常量。逐个复核后：
- 3 个 → `B_IMPLEMENTED_VIA_HARDCODED`（实现存在，只是路径硬编码）
- 3 个 → `A_DESKTOP_LACKS_TOO`（桌面端也没有）
- **2 个真实缺口**（见 §五）

---

## 四、本批涉及的文件

### 代码（8 个，继承自 batch #62 在途，本批验证后提交）

| 文件 | 变更 |
|---|---|
| `lib/core/utils/media_url.dart` | 新增 `pageDocImageUrl` / `pageDocImageUrls`：从 page doc 的 `media` 子对象取 URL |
| `lib/features/comic/data/comic_repository.dart` | 新增 `getEpisodePage` / `getAllEpisodes` / `getImagePage` / `getAllEpisodeImages` + `sortEpisodesByDesktopOrder` |
| `lib/features/comic/domain/comic_model.dart` | 新增 `EpisodePage` / `ImagePage` |
| `lib/features/comic/presentation/comic_detail_screen.dart` | 章节列表改走 `getAllEpisodes`（自动翻页） |
| `lib/features/download/data/download_repository.dart` | 图片列表改走 `getAllEpisodeImages`，**透传 cancelToken** |
| `lib/features/history/presentation/history_screen.dart` | 历史恢复改走 `getAllEpisodes` |
| `lib/features/reader/presentation/reader_screen.dart` | 阅读器改走 `getAllEpisodeImages`（与下载器共用同一段代码） |
| `lib/shared/constants/api_constants.dart` | `episodes()` 补 `page` 参数 |

**修复的 3 个真实缺陷**：
1. **每章下载 0 张图** — 下载器把整个 page doc 传给 `mediaUrlFrom`，
   而媒体字段嵌套在 `media` 下 → 恒返回空串 → 全被 `if (isEmpty) continue` 跳过。
   阅读器用 `p['media']` 所以"阅读正常、下载全空" —— 同一 API 两个消费点写法分叉。
2. **长篇章节不可见** — 章节列表固定只取第 1 页（真实数据 22 部漫画受影响）
3. **长章节图片截断** — 图片列表固定只取第 1 组（6,354 部单章漫画受影响，
   最多一章 4,896 张只看到前 200 张）

### 测试（4 新增）
- `test/episode_pagination_test.dart`、`test/episode_order_test.dart`、
  `test/image_pagination_test.dart`、`test/probe_signature_page_param_test.dart`

### 工具（27 新增/补交）
- 审计：`audit_dead_constants.py`、`consumer_audit.py`、`endpoint_full_diff.py`
- 探针：`probe_*.py` / `probe_*.dart`（签名、认证、主机、响应头、版本闸门等）
- 验证：`verify_batch62_claims.py`、`verify_capture_pagination.py`、
  `verify_episode_order.py`、`verify_episode_order_fixed.py`、
  **`verify_eps_page_orientation.py`（本批新增）**、`verify_page_media_shape.py`、
  `verify_signature_page_param.py`
- 清单：`desktop_inventory.txt`、`mobile_inventory.txt`

---

## 五、剩余缺口（本批未实施，已定位到具体常量）

| 常量 | 端点 | 桌面端对应 | 状态 |
|---|---|---|---|
| `chatRooms` | `/chat` | `GetChatReq`（`req.py:582`）返回 `data.chatList` | **真实缺口**：桌面端 `chat_new_view.py:49` 同时调 `GetChatReq()` + `GetNewChatReq()`；移动端只调新聊天 `room/list`，缺旧版频道列表 |
| `userComments` | `/users/profile/comments` | 桌面端无此端点（走 `/users/my-comments`） | **真实缺口**：`myComments` 已在用（`user_repository.dart:15`），`userComments` 是被取代的旧常量，属死代码 |
| `speedTestPing` | `/speed/ping` | 桌面端无 | 桌面端也没有，移动端自有增强 |
| `userFavorites` | `/users/{uid}/favourites` | 桌面端无 | 桌面端也没有 |

**未实施原因**：本批预算优先用于收尾在途代码 + 修复 2 个真实缺陷 +
把"第 1 页方向"这一关键契约用脚本固化。`chatRooms` 需要新增旧版聊天 UI
（频道列表 + socket.io 旧协议），是一个独立功能，不适合在缺陷修复批里搭进去。
`userComments` 应**删除**（死常量），属清理项。

---

## 六、验证状态

| 检查 | 结果 |
|---|---|
| `flutter analyze lib test` | ✅ No issues found |
| `flutter test` | ✅ **149 通过 / 0 失败**（修复前 147/2） |
| `flutter build apk --debug` | 见 CI（见 §七） |
| 真实 API 联调 | ❌ 本机出口网络不可达 `picaapi.picacomic.com`（curl exit 7 / 0.04s），改用**桌面端源码求值 + 150,574 行真实抓取库**交叉验证 |
| `tool/verify_eps_page_orientation.py` | ✅ page 1 = 最新，展示 = 最老在前 |
| `tool/verify_episode_order_fixed.py` | ✅ 6/6 案例与桌面端公式全等 |
| `tool/verify_batch62_claims.py` | ✅ 4/4 真实数据断言 MATCH |
| `tool/verify_signature_page_param.py` | ✅ `?page=N` 参与签名，与桌面端一致 |
| `tool/consumer_audit.py` | screens=36 constants=54 orphan_screens=0 stub_hits=0 |

---

## 七、经验沉淀

1. **继承测试失败时，先判定"夹具"还是"实现"错了。** 两次失败都是夹具虚构了
   不存在的 API 形态。判定依据是**桌面端源码求值**，不是"测试看起来对不对"。
2. **"第 1 页方向"是个容易被想当然的契约。** 三处独立证据（分页标签、行章节号、
   存储下标+渲染循环）互相印证后，才能写进代码。已固化为可复跑脚本。
3. **同一个 API 的两个消费点必须共用同一段解析代码。** 本批的"阅读正常、下载全空"
   根因就是两处写法不一致；改成共享 `pageDocImageUrl` 后结构上不可能再分叉。
4. **死常量审计必须按路径片段搜，不能按标识符搜。** 8 个"死"常量里只有 2 个是真缺口。
5. **在途代码要先提交再谈优化。** 8 改 + 30 未跟踪的 diff 若继续漂移，
   下一批要重新验证全部内容。

---

## 八、未完成 / 受限项

| 项 | 原因 |
|---|---|
| 真实 API 联调验证 | 本机出口网络不可达 pica API（与 batch59 同一限制）。已用桌面端源码求值 + 真实抓取库替代 |
| `chatRooms` 旧版聊天频道列表 | 需新增独立 UI 与 socket.io 旧协议接入，超出本批缺陷修复范围 |
| `userComments` 死常量清理 | 属清理项，已定位，留待下一批 |
| `init?platform=android` 等 3 个低优先级端点 | 承 batch59，仍未实施 |
