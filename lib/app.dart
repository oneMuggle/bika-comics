import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/settings_storage.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/comic/presentation/comic_list_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'shared/constants/app_colors.dart';

/// 全局导航 key
final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

/// 应用主题 provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.read(settingsStorageProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsStorage _storage;
  ThemeModeNotifier(this._storage) : super(ThemeMode.system);

  Future<void> load() async {
    final mode = await _storage.getThemeMode();
    state = mode;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _storage.setThemeMode(mode);
  }
}

class PicacgApp extends ConsumerStatefulWidget {
  const PicacgApp({super.key});

  @override
  ConsumerState<PicacgApp> createState() => _PicacgAppState();
}

class _PicacgAppState extends ConsumerState<PicacgApp> {
  @override
  void initState() {
    super.initState();
    // 加载主题设置
    ref.read(themeModeProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: '哔咔漫画',
      debugShowCheckedModeBanner: false,
      theme: AppColors.lightTheme,
      darkTheme: AppColors.darkTheme,
      themeMode: themeMode,
      navigatorKey: rootNavigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainShell(),
        '/login': (context) => const LoginScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

/// 主框架（底部导航）
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        children: const [
          ComicListScreen(),
          SearchScreen(),
          DownloadsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          // TODO: 切换页面
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '搜索',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: '下载',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
