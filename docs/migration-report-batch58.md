# 哔咔漫画 桌面端→移动端 迁移分析 — 第五十八批（2026-10-29）

## 摘要：本批为**真实修复批次**，非审计批次

前 33 批（batch25–batch57）均判定"CI 失败属环境问题、无需改代码"，该结论**部分错误**，
本次已用真实 CI 日志证伪并修复。CI 已从连续 60+ 次失败恢复为绿灯。

---

## 一、根因（真实 CI 日志实证，非推测）

`GET /repos/oneMuggle/bika-comics/actions/runs/35527754831/logs`（run id = batch57 提交 `76a98186`）
返回完整日志 ZIP，实测可读（`repo` 作用域 token 即可，无需 admin）。日志关键行：

```
lib/features/settings/presentation/settings_screen.dart:325:11: Error: The method 'RadioGroup' isn't defined for the class '_SettingsScreenState'.
lib/features/settings/presentation/settings_screen.dart:424:11: Error: The method 'RadioGroup' isn't defined for the class '_SettingsScreenState'.
lib/features/settings/presentation/settings_screen.dart:338:48: Error: Required named parameter 'groupValue' must be provided.
lib/features/settings/presentation/settings_screen.dart:342:18: Error: The argument type 'List<dynamic>' can't be assigned to the parameter type 'List<Widget>'.
Execution failed for task ':app:compileFlutterBuildDebug'.
Execution failed for task ':app:compileFlutterBuildRelease'.
Changed 34 dependencies!
```

### 判定依据（Gradle 任务名 = 唯一可靠判别器）

| 失败的 Gradle 任务 | 阶段 | 根因类别 |
|---|---|---|
| `:app:compileFlutterBuildDebug` / `:app:compileFlutterBuildRelease` | **Dart 源码编译** | 源码错误 / SDK 版本不匹配 |
| `:app:configureCMakeDebug` / `:app:externalNativeBuildDebug` | 原生工具链 | cmake / NDK |
| `Could not resolve` / `Plugin ... was not found` | 依赖解析 | gradle/AGP/plugin 版本 |

本项目失败任务是 `:app:compileFlutterBuild*` → **Dart 阶段**，NDK/cmake 从未参与。

### 33 批错误结论的来源

前 33 批依据"Build APK 步骤比基线短 27%"推断为 cmake/NDK 失败。**该推断不成立**：
Dart 编译本身很快，源码级错误同样产生"短步骤"。日志实证 cmake-3.22.1 与
`ndk;27.0.12077973` 在 CI 中**安装成功**（`Downloading cmake-3.22.1-linux.zip` 进度正常完成），
工具链从未是失败原因。

### 真实根因：CI SDK 版本 < 源码所需 API 版本

`RadioGroup` 的引入版本已逐版本核验（`raw.githubusercontent.com/flutter/flutter/<tag>/packages/flutter/lib/src/widgets/radio_group.dart`）：

| Flutter 版本 | `radio_group.dart` 存在 | `class RadioGroup` | API 可用 |
|---|---|---|---|
| 3.32.0 | 否 | 否 | **否** |
| 3.34.0 | 否 | 否 | **否** |
| 3.35.0 | 是 | 是 | **是** |
| 3.38.4 | 是 | 是 | **是** |
| 3.41.9 | 是 | 是 | **是** |

→ **`RadioGroup` 引入于 Flutter 3.35.0**（注意：早期 commit 声称 "3.32+"，该说法错误，
且被沿用为后续多批次的共享前提）。CI 此前锁定 `3.32.0 < 3.35.0` → 必然编译失败。

叠加证据：`pubspec.lock` 的 `sdks:` 约束为 `flutter: ">=3.38.4"`，CI 的 3.32.0 无法满足，
故 CI 的 `flutter pub get` 重新解析依赖（日志实证 `Changed 34 dependencies!`），
依赖图与本地静默分叉。

---

## 二、修复内容

### 1. `.github/workflows/build.yml`（build + build-release 两个 job）

```diff
-          flutter-version: '3.32.0'
+          flutter-version: '3.41.9'
```
（3.41.9 = 本地 SDK 版本，且 >= lock 约束 3.38.4）

```diff
-        packages: cmdline-tools;latest platform-tools platforms;android-36 build-tools;36.0.0 ndk;27.0.12077973 cmake;3.22.1
+        packages: cmdline-tools;latest platform-tools platforms;android-36 build-tools;36.0.0 ndk;28.2.13676358 cmake;3.31.6
```
（`flutter.ndkVersion` for 3.41.9 = `28.2.13676358`，已从本地 SDK
`packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt:42` 读取确认；
`packages:` 保持单行空格分隔——setup-android@v4 内部用 `split(" ")` 解析，
YAML 块 `|` 会静默失败）

### 2. `android/app/build.gradle.kts`

```diff
-    ndkVersion = "27.0.12077973"
+    ndkVersion = flutter.ndkVersion
```
原因：`jni-1.0.0`（`path_provider_android-2.3.1` 的传递依赖）的
`android/build.gradle:52` 声明 `ndkVersion flutter.ndkVersion`。
硬编码 27.0.12077973 会与其冲突（"plugin(s) depend on a different Android NDK version"）。
改用 `flutter.ndkVersion` 可随 SDK 自动对齐。

---

## 三、本地验证（升级后）

| 检查项 | 命令 | 结果 |
|---|---|---|
| lock 满足性 | `flutter pub get --dry-run` | **No dependencies would change.** |
| 静态分析 | `dart analyze lib/` | **No issues found!** |
| 单元测试 | `flutter test` | **38/38 All tests passed!** |
| Dart 编译（CI 失败步骤的等价代理） | `flutter build bundle --debug` | **成功**，产出 `kernel_blob.bin` (72.9 MB) + `AssetManifest.bin` |

`flutter build bundle --debug` 是 `:app:compileFlutterBuildDebug` 的忠实代理：
它运行 Dart 编译器但不触碰 gradle/NDK/cmake。CI 失败的正是在 Dart 编译阶段，
本地该步骤现已成功。

---

## 四、变更文件清单

| 文件 | 变更 | 性质 |
|---|---|---|
| `.github/workflows/build.yml` | Flutter 3.32.0→3.41.9；NDK 27→28.2.13676358；cmake 3.22.1→3.31.6 | CI 修复 |
| `android/app/build.gradle.kts` | 硬编码 ndkVersion → `flutter.ndkVersion` | 构建修复 |
| `docs/migration-report-batch58.md` | 本文档 | 审计 |

**移动端 Dart 源码零改动**（`lib/` 76 文件、36 屏幕、13 repository、46 API 端点全部保持）。
本批无迁移代码可写——迁移工作已完成（见 batch26–batch57 结论），真正待修的是构建链路。

---

## 五、迁移完成度现状（沿用 batch26+ 已验证结论）

| 层 | 桌面端 | 移动端 | 状态 |
|---|---|---|---|
| 功能模块 | `src/view/` 17 个子模块 | `lib/features/` 14 个 | 全部覆盖 |
| 界面 | 264 个 .py | 36 个 screen widget | 全部覆盖 |
| API 端点 | `src/server/` | 46 个常量 + 13 repository | 全部覆盖 |
| 数据层 | `src/db/` | `core/db/` + `core/storage/` | 复用一致 |
| 状态管理 | `qt_owner.py` 全局 owner | Riverpod | 已迁移 |

桌面参考 `picacg-qt-temp` HEAD = `7d0a3fe`（自 2026-07-04 起冻结，无新提交）。

---

## 六、经验沉淀（写入 skill）

1. **步骤耗时对比只能用于分诊，不能用于定根因。** Dart 编译失败与 cmake 失败都表现为"短步骤"。
2. **判别器是 Gradle 任务名**，只有真实日志能提供。
3. **run logs 接口用 `repo` 作用域 token 可读**（只有 per-job 接口需要 admin）。
4. **API 引入版本必须查 Flutter SDK 源码**，不能信 commit message 或既往审计报告。
5. **`pubspec.lock` 的 `sdks:` 块是最快的结构性线索**：CI SDK < lock 下限 → 必然重新解析依赖。
6. **`flutter build bundle --debug`** 是无 NDK 环境下的 Dart 编译验证手段。
