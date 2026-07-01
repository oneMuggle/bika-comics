import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_colors.dart';
import '../data/speed_test_service.dart';

/// 网络测速页面
///
/// 对应桌面端: view/setting/setting_view.py 中的网络测速功能
class SpeedTestScreen extends ConsumerWidget {
  const SpeedTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResult = ref.watch(speedTestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('网络测速'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新测速',
            onPressed: () => ref.invalidate(speedTestProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.network_check,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              asyncResult.when(
                loading: () => const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在测速...'),
                    ],
                  ),
                ),
                error: (e, st) => Column(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('测速失败: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(speedTestProvider),
                      child: const Text('重试'),
                    ),
                  ],
                ),
                data: (result) => Column(
                  children: [
                    if (result.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '警告: ${result.error}',
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    _MetricCard(
                      icon: Icons.speed,
                      label: '下载速度',
                      value: result.speedKBps <= 0
                          ? '— KB/s'
                          : '${result.speedKBps.toStringAsFixed(1)} KB/s',
                    ),
                    const SizedBox(height: 12),
                    _MetricCard(
                      icon: Icons.network_ping,
                      label: 'Ping 延迟',
                      value: result.pingMs < 0
                          ? '— ms'
                          : '${result.pingMs} ms',
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.invalidate(speedTestProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新测速'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.secondaryText, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
