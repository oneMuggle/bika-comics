import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_colors.dart';
import '../data/pica_share_service.dart';
import 'comic_detail_screen.dart';

/// Pica 号解析页面
///
/// 用户输入 Pica 号（推荐位编码），解析回漫画 ID 后跳转到详情页
/// 对应桌面端: GetIdByShareIdReq (src/server/req.py)
class PicaShareResolverScreen extends ConsumerStatefulWidget {
  const PicaShareResolverScreen({super.key});

  @override
  ConsumerState<PicaShareResolverScreen> createState() =>
      _PicaShareResolverScreenState();
}

class _PicaShareResolverScreenState
    extends ConsumerState<PicaShareResolverScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _lastResult;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _lastResult = null;
    });
    try {
      final service = ref.read(picaShareServiceProvider);
      final id = await service.resolveShareId(raw);
      if (!mounted) return;
      if (id == null || id.isEmpty) {
        setState(() => _error = '解析失败，Pica 号无效或网络异常');
      } else {
        setState(() => _lastResult = id);
        // 自动跳转到漫画详情
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ComicDetailScreen(comicId: id),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = '异常: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pica 号解析')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '输入 Pica 号（推荐位编号），解析为漫画 ID 后打开详情。',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                enabled: !_busy,
                keyboardType: TextInputType.text,
                inputFormatters: [LengthLimitingTextInputFormatter(64)],
                decoration: InputDecoration(
                  labelText: 'Pica 号',
                  hintText: '例如：abc123',
                  prefixIcon: const Icon(Icons.tag),
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
                onSubmitted: (_) => _resolve(),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _resolve,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_busy ? '解析中...' : '解析'),
              ),
              if (_lastResult != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('已解析为: $_lastResult',
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
