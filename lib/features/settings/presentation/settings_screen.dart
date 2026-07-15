import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../core/storage/settings_storage.dart';
import '../../../core/utils/proxy_selector.dart';

/// 设置 Provider
final settingsScreenProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.read(settingsStorageProvider));
});

class SettingsState {
  final String? apiBaseUrl;
  final ProxyType proxyType;
  final String? proxyHost;
  final int proxyPort;
  final ThemeMode themeMode;

  const SettingsState({
    this.apiBaseUrl,
    this.proxyType = ProxyType.none,
    this.proxyHost,
    this.proxyPort = 1080,
    this.themeMode = ThemeMode.system,
  });

  SettingsState copyWith({
    String? apiBaseUrl,
    ProxyType? proxyType,
    String? proxyHost,
    int? proxyPort,
    ThemeMode? themeMode,
  }) =>
      SettingsState(
        apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
        proxyType: proxyType ?? this.proxyType,
        proxyHost: proxyHost ?? this.proxyHost,
        proxyPort: proxyPort ?? this.proxyPort,
        themeMode: themeMode ?? this.themeMode,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsStorage _storage;

  SettingsNotifier(this._storage) : super(const SettingsState());

  Future<void> load() async {
    final url = await _storage.getApiBaseUrl();
    final proxy = await _storage.getProxyConfig();
    final theme = await _storage.getThemeMode();

    state = SettingsState(
      apiBaseUrl: url,
      proxyType: proxy?.type ?? ProxyType.none,
      proxyHost: proxy?.host,
      proxyPort: proxy?.port ?? 1080,
      themeMode: theme,
    );
  }

  Future<void> setApiBaseUrl(String url) async {
    // 第二十五批：保存前必须经过合法性与规范化校验，
    // 非法值直接抛 ArgumentError，避免下游 ApiClient 收到空串/格式错误字符串。
    if (!ApiEndpoints.isValidBaseUrl(url)) {
      throw ArgumentError.value(
        url,
        'url',
        'API 地址必须为 http:// 或 https:// 开头的合法 URL',
      );
    }
    final normalized = ApiEndpoints.normalizeBaseUrl(url);
    await _storage.setApiBaseUrl(normalized);
    state = state.copyWith(apiBaseUrl: normalized);
  }

  Future<void> setProxy(ProxyType type, String? host, int port) async {
    if (type == ProxyType.none) {
      await _storage.clearProxyConfig();
    } else {
      await _storage.setProxyConfig(ProxyConfig(
        type: type,
        host: host ?? '',
        port: port,
      ));
    }
    state = state.copyWith(
      proxyType: type,
      proxyHost: host,
      proxyPort: port,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _storage.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> clearCache() async {
    await DefaultCacheManager().emptyCache();
  }
}

/// 设置页面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // 加载设置
    Future.microtask(() => ref.read(settingsScreenProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsScreenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: ListView(
        children: [
          // 服务器设置
          const _SectionHeader(title: '服务器'),
          ListTile(
            leading: const Icon(Icons.dns),
            title: const Text('API 地址'),
            subtitle: Text(settings.apiBaseUrl ?? '默认'),
            onTap: () => _showApiUrlDialog(context),
          ),

          const Divider(),

          // 代理设置
          const _SectionHeader(title: AppStrings.proxySettings),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text(AppStrings.proxyType),
            subtitle: Text(_proxyTypeLabel(settings.proxyType)),
            onTap: () => _showProxyTypeDialog(context),
          ),
          if (settings.proxyType != ProxyType.none) ...[
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text(AppStrings.proxyHost),
              subtitle: Text(settings.proxyHost ?? ''),
              onTap: () => _showProxyHostDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings_ethernet),
              title: const Text(AppStrings.proxyPort),
              subtitle: Text('${settings.proxyPort}'),
              onTap: () => _showProxyPortDialog(context),
            ),
          ],

          const Divider(),

          // 主题
          const _SectionHeader(title: AppStrings.theme),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题模式'),
            subtitle: Text(_themeModeLabel(settings.themeMode)),
            onTap: () => _showThemeDialog(context),
          ),

          const Divider(),

          // 存储
          const _SectionHeader(title: '存储'),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text(AppStrings.clearCache),
            subtitle: const Text('清理图片缓存'),
            onTap: () async {
              // 提前捕获 messenger，避免 await 后使用 BuildContext
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(settingsScreenProvider.notifier).clearCache();
              messenger.showSnackBar(
                const SnackBar(content: Text(AppStrings.cacheCleared)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('本地阅读（NAS）'),
            subtitle: const Text('浏览应用沙箱 / 准备接入 SFTP / WebDAV'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pushNamed('/nas-local');
            },
          ),

          const Divider(),

          // 网络测速
          const _SectionHeader(title: '网络'),
          ListTile(
            leading: const Icon(Icons.network_check),
            title: const Text(AppStrings.speedTest),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pushNamed('/speed-test');
            },
          ),

          const Divider(),

          // 搜索
          const _SectionHeader(title: '搜索'),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('搜索屏蔽词'),
            subtitle: const Text('配置不想看到的标题 / 分类 / Tag'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pushNamed('/forbid-words');
            },
          ),
          ListTile(
            leading: const Icon(Icons.find_in_page),
            title: const Text('批量搜索工具'),
            subtitle: const Text('对一组关键词逐一搜索并保存结果'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pushNamed('/batch-search');
            },
          ),

          // 关于
          const _SectionHeader(title: AppStrings.about),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('帮助 / 关于'),
            subtitle: const Text('版本信息 / 项目链接 / 日志目录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pushNamed('/help');
            },
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppStrings.version),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  String _proxyTypeLabel(ProxyType type) {
    switch (type) {
      case ProxyType.none:
        return AppStrings.proxyNone;
      case ProxyType.socks5:
        return AppStrings.proxyTypeSocks5;
      case ProxyType.http:
        return AppStrings.proxyTypeHttp;
    }
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return AppStrings.themeLight;
      case ThemeMode.dark:
        return AppStrings.themeDark;
      case ThemeMode.system:
        return AppStrings.themeSystem;
    }
  }

  void _showApiUrlDialog(BuildContext context) {
    final controller = TextEditingController(
      text: ref.read(settingsScreenProvider).apiBaseUrl ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 地址'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://api.example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(settingsScreenProvider.notifier)
                  .setApiBaseUrl(controller.text);
              Navigator.pop(context);
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  void _showProxyTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text(AppStrings.proxyType),
        children: [
          RadioGroup<ProxyType>(
            groupValue: ref.read(settingsScreenProvider).proxyType,
            onChanged: (value) {
              ref.read(settingsScreenProvider.notifier).setProxy(
                    value!,
                    ref.read(settingsScreenProvider).proxyHost,
                    ref.read(settingsScreenProvider).proxyPort,
                  );
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ProxyType.values.map((type) {
                return RadioListTile<ProxyType>(
                  value: type,
                  title: Text(_proxyTypeLabel(type)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showProxyHostDialog(BuildContext context) {
    final controller = TextEditingController(
      text: ref.read(settingsScreenProvider).proxyHost ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.proxyHost),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '127.0.0.1'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsScreenProvider.notifier).setProxy(
                    ref.read(settingsScreenProvider).proxyType,
                    controller.text,
                    ref.read(settingsScreenProvider).proxyPort,
                  );
              Navigator.pop(context);
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  void _showProxyPortDialog(BuildContext context) {
    final controller = TextEditingController(
      text: ref.read(settingsScreenProvider).proxyPort.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.proxyPort),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '1080'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              final port = int.tryParse(controller.text) ?? 1080;
              ref.read(settingsScreenProvider.notifier).setProxy(
                    ref.read(settingsScreenProvider).proxyType,
                    ref.read(settingsScreenProvider).proxyHost,
                    port,
                  );
              Navigator.pop(context);
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text(AppStrings.theme),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: ref.read(settingsScreenProvider).themeMode,
            onChanged: (value) {
              ref.read(settingsScreenProvider.notifier).setThemeMode(value!);
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ThemeMode.values.map((mode) {
                return RadioListTile<ThemeMode>(
                  value: mode,
                  title: Text(_themeModeLabel(mode)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
