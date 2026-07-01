import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_colors.dart';
import '../data/forbid_words_repository.dart';

/// 搜索屏蔽词管理页面
///
/// 对应桌面端 `view/tool/forbid_words_view.py`。
/// - 上半部分：勾选"按标题/Tag/分类"过滤
/// - 下半部分：当前已选屏蔽词列表（点击 X 删除）+ 添加新词输入框
class ForbidWordsScreen extends ConsumerStatefulWidget {
  const ForbidWordsScreen({super.key});

  @override
  ConsumerState<ForbidWordsScreen> createState() => _ForbidWordsScreenState();
}

class _ForbidWordsScreenState extends ConsumerState<ForbidWordsScreen> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final value = _input.text.trim();
    if (value.isEmpty) return;
    await ref.read(forbidWordsProvider.notifier).addWord(value);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forbidWordsProvider);
    final notifier = ref.read(forbidWordsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索屏蔽词'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ============== 过滤维度 ==============
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('按标题屏蔽'),
                    subtitle: const Text('标题中包含屏蔽词则隐藏'),
                    value: state.forbidTitle,
                    onChanged: notifier.setForbidTitle,
                  ),
                  SwitchListTile(
                    title: const Text('按 Tag 屏蔽'),
                    subtitle: const Text('标签命中屏蔽词则隐藏'),
                    value: state.forbidTag,
                    onChanged: notifier.setForbidTag,
                  ),
                  SwitchListTile(
                    title: const Text('按分类屏蔽'),
                    subtitle: const Text('分类命中屏蔽词则隐藏'),
                    value: state.forbidCategory,
                    onChanged: notifier.setForbidCategory,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ============== 添加新词 ==============
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        labelText: '添加屏蔽词',
                        hintText: '例如：调教、純愛、CG雜圖…',
                        prefixIcon: Icon(Icons.block),
                      ),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: const Text('添加'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ============== 屏蔽词列表 ==============
          Text(
            '已添加 ${state.customWords.length} 个屏蔽词',
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (state.customWords.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '暂无屏蔽词',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < state.customWords.length; i++) ...[
                    ListTile(
                      leading: const Icon(Icons.block, color: Colors.redAccent),
                      title: Text(state.customWords[i]),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: '删除',
                        onPressed: () => notifier.removeWord(
                          state.customWords[i],
                        ),
                      ),
                    ),
                    if (i < state.customWords.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (state.selected.isNotEmpty)
            Center(
              child: Text(
                '当前有 ${state.selected.length} 个屏蔽词生效中',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
