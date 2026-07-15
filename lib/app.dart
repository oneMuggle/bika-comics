import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/settings_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/change_password_screen.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/profile_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/comic/presentation/advanced_search_screen.dart';
import 'features/comic/presentation/batch_search_screen.dart';
import 'features/comic/presentation/categories_screen.dart';
import 'features/comic/presentation/comic_list_screen.dart';
import 'features/comic/presentation/forbid_words_screen.dart';
import 'features/comic/presentation/leaderboard_screen.dart';
import 'features/comic/presentation/my_favourites_screen.dart';
import 'features/comic/presentation/my_follows_screen.dart';
import 'features/comic/presentation/pica_share_resolver_screen.dart';
import 'features/comic/presentation/search_screen.dart';
import 'features/download/presentation/download_screen.dart';
import 'features/friend/presentation/friend_post_detail_screen.dart';
import 'features/friend/presentation/friend_posts_screen.dart';
import 'features/game/presentation/game_list_screen.dart';
import 'features/help/presentation/help_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/nas/presentation/nas_local_screen.dart';
import 'features/chat/presentation/chat_room_screen.dart';
import 'features/chat/presentation/chat_rooms_screen.dart';
import 'features/pica_apps/presentation/pica_apps_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/settings/presentation/speed_test_screen.dart';
import 'shared/constants/app_colors.dart';

/// 全局导航 key
final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

/// 应用主题 provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
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
    // 尝试恢复登录状态
    ref.read(authStateProvider.notifier).restore();
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
        '/register': (context) => const RegisterScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/favourites': (context) => const MyFavouritesScreen(),
        '/follows': (context) => const MyFollowsScreen(),
        '/history': (context) => const HistoryScreen(),
        '/home': (context) => const HomeScreen(),
        '/comics': (context) => const ComicListScreen(),
        '/pica-share': (context) => const PicaShareResolverScreen(),
        '/speed-test': (context) => const SpeedTestScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/advanced-search': (context) => const AdvancedSearchScreen(),
        '/games': (context) => const GameListScreen(),
        '/forbid-words': (context) => const ForbidWordsScreen(),
        '/batch-search': (context) => const BatchSearchScreen(),
        '/friend-posts': (context) => const FriendPostsScreen(),
        '/friend-post-detail': (context) {
          final postId = ModalRoute.of(context)?.settings.arguments as String?;
          return FriendPostDetailScreen(postId: postId ?? '');
        },
        '/chat-rooms': (context) => const ChatRoomsScreen(),
        '/chat-room': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, String>?;
          return ChatRoomScreen(
            roomId: args?['roomId'] ?? '',
            roomName: args?['roomName'] ?? '聊天室',
          );
        },
        '/nas-local': (context) => const NasLocalScreen(),
        '/help': (context) => const HelpScreen(),
        '/pica-apps': (context) => const PicaAppsScreen(),
      },
    );
  }
}

/// 主框架（底部导航）
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _screens = [
    HomeScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
    const SearchScreen(),
    const DownloadsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.menu_book, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    '哔咔漫画',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('全部漫画'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/comics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('分类浏览'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/categories');
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('高级搜索'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/advanced-search');
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('排行榜'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/leaderboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.tag),
              title: const Text('Pica 号解析'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/pica-share');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videogame_asset),
              title: const Text('游戏区'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/games');
              },
            ),
            ListTile(
              leading: const Icon(Icons.apps),
              title: const Text('Pica Apps'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/pica-apps');
              },
            ),
            ListTile(
              leading: const Icon(Icons.forum),
              title: const Text('好友动态'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/friend-posts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble),
              title: const Text('聊天室'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chat-rooms');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('我的收藏'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/favourites');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('我的追漫'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/follows');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('个人中心'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('设置'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
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
