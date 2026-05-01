import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
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
    await _storage.setApiBaseUrl(url);
    state = state.copyWith(apiBaseUrl: url);
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
          _SectionHeader(title: '服务器'),
          ListTile(
            leading: const Icon(Icons.dns),
            title: const Text('API 地址'),
            subtitle: Text(settings.apiBaseUrl ?? '默认'),
            onTap: () => _showApiUrlDialog(context),
          ),

          const Divider(),

          // 代理设置
          _SectionHeader(title: AppStrings.proxySettings),
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
          _SectionHeader(title: AppStrings.theme),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题模式'),
            subtitle: Text(_themeModeLabel(settings.themeMode)),
            onTap: () => _showThemeDialog(context),
          ),

          const Divider(),

          // 缓存
          _SectionHeader(title: '存储'),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text(AppStrings.clearCache),
            subtitle: const Text('清理图片缓存'),
            onTap: () async {
              await ref.read(settingsScreenProvider.notifier).clearCache();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.cacheCleared)),
                );
              }
            },
          ),

          const Divider(),

          // 关于
          _SectionHeader(title: AppStrings.about),
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
        children: ProxyType.values.map((type) {
          return RadioListTile<ProxyType>(
            value: type,
            groupValue: ref.read(settingsScreenProvider).proxyType,
            title: Text(_proxyTypeLabel(type)),
            onChanged: (value) {
              ref.read(settingsScreenProvider.notifier).setProxy(
                    value!,
                    ref.read(settingsScreenProvider).proxyHost,
                    ref.read(settingsScreenProvider).proxyPort,
                  );
              Navigator.pop(context);
            },
          );
        }).toList(),
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
        children: ThemeMode.values.map((mode) {
          return RadioListTile<ThemeMode>(
            value: mode,
            groupValue: ref.read(settingsScreenProvider).themeMode,
            title: Text(_themeModeLabel(mode)),
            onChanged: (value) {
              ref.read(settingsScreenProvider.notifier).setThemeMode(value!);
              Navigator.pop(context);
            },
          );
        }).toList(),
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
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
