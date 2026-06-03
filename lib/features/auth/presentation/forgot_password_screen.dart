import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_colors.dart';
import '../data/auth_repository.dart';

/// 忘记密码 - 重置密码页面
/// 流程：
/// 1. 输入邮箱 -> 服务器返回安全问题列表
/// 2. 选择/回答其中一个问题
/// 3. 输入新密码 -> 重置成功，跳转登录
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

enum _Step { enterEmail, answerQuestion, success }

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _Step _step = _Step.enterEmail;
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  List<Map<String, dynamic>> _questions = [];
  int? _selectedQuestionNo;
  String? _selectedQuestionText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _answerCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _showError('请输入邮箱');
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final questions = await ref
          .read(authStateProvider.notifier)
          .forgotPassword(_emailCtrl.text.trim());
      if (questions.isEmpty) {
        _showError('该邮箱未注册或无安全问题');
        return;
      }
      setState(() {
        _questions = questions;
        _selectedQuestionNo =
            questions.first['questionNo'] as int? ?? questions.first['no'] as int?;
        _selectedQuestionText =
            questions.first['question'] as String? ?? '安全问题';
        _step = _Step.answerQuestion;
      });
    } catch (e) {
      _showError('获取安全问题失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitReset() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuestionNo == null) {
      _showError('请选择安全问题');
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).resetPassword(
            email: _emailCtrl.text.trim(),
            questionNo: _selectedQuestionNo!,
            answer: _answerCtrl.text.trim(),
            newPassword: _newPasswordCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() => _step = _Step.success);
    } catch (e) {
      _showError('重置失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('找回密码')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: switch (_step) {
            _Step.enterEmail => _buildEnterEmailStep(),
            _Step.answerQuestion => _buildAnswerStep(),
            _Step.success => _buildSuccessStep(),
          },
        ),
      ),
    );
  }

  Widget _buildEnterEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '请输入注册时使用的邮箱，我们会向您返回安全问题。',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: '邮箱',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _submitEmail,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('下一步'),
        ),
      ],
    );
  }

  Widget _buildAnswerStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _emailCtrl.text.trim(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('选择安全问题', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_questions.length > 1)
            Wrap(
              spacing: 8,
              children: _questions.map((q) {
                final no = q['questionNo'] as int? ?? q['no'] as int?;
                final text = q['question'] as String? ?? '问题 $no';
                final selected = _selectedQuestionNo == no;
                return ChoiceChip(
                  label: Text(text),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedQuestionNo = no;
                      _selectedQuestionText = text;
                    });
                  },
                );
              }).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedQuestionText ?? '',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _answerCtrl,
            decoration: const InputDecoration(
              labelText: '答案',
              prefixIcon: Icon(Icons.question_answer_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? '请输入答案' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordCtrl,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: '新密码',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureNew ? Icons.visibility : Icons.visibility_off),
                onPressed: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return '请输入新密码';
              if (v.length < 6) return '密码长度不能少于 6 位';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: '确认新密码',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureConfirm ? Icons.visibility : Icons.visibility_off),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return '请再次输入新密码';
              if (v != _newPasswordCtrl.text) return '两次输入的密码不一致';
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submitReset,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('重置密码'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle, color: Colors.green, size: 80),
        const SizedBox(height: 16),
        const Text(
          '密码重置成功',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          '请使用新密码登录',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 40),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('返回登录'),
        ),
      ],
    );
  }
}
