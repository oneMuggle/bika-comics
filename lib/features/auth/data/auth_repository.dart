import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/constants/api_constants.dart';
import '../domain/auth_state.dart';

/// 认证状态 Provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _api = ApiClient.instance;

  /// 登录
  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data['data'];
      final token = data['token'];
      final user = data['user'];

      // 保存登录凭证用于自动登录
      await SecureStorageHolder.instance.setCredentials(
        email: email,
        password: password,
      );

      // 保存用户信息和 Token
      await SecureStorageHolder.instance.setUser(
        id: user['_id'] ?? user['id'] ?? '',
        name: user['name'] ?? '',
        email: email,
        avatar: user['avatar']?['path'] ?? '',
      );
      await SecureStorageHolder.instance.setApiToken(token);

      state = AuthState(
        isLoggedIn: true,
        token: token,
        user: AuthUser(
          id: user['_id'] ?? user['id'] ?? '',
          name: user['name'] ?? '',
          email: email,
          avatar: user['avatar']?['path'] ?? '',
          birthday: user['birthday'],
          level: user['level'] ?? 0,
          gender: user['gender'] ?? 'm',
        ),
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  /// 注册
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? birthday,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
          if (birthday != null) 'birthday': birthday,
        },
      );

      final data = response.data['data'];
      final token = data['token'];
      final user = data['user'];

      state = AuthState(
        isLoggedIn: true,
        token: token,
        user: AuthUser(
          id: user['_id'] ?? user['id'] ?? '',
          name: user['name'] ?? '',
          email: email,
          avatar: user['avatar']?['path'] ?? '',
          birthday: user['birthday'],
          level: user['level'] ?? 0,
          gender: user['gender'] ?? 'm',
        ),
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {}

    // 清除存储的凭证和用户信息
    await SecureStorageHolder.instance.clearCredentials();
    await SecureStorageHolder.instance.clearUser();
    await SecureStorageHolder.instance.clearTokens();

    state = const AuthState();
  }

  /// 从存储恢复登录状态
  Future<bool> restore() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final secureStorage = SecureStorageHolder.instance;

      // 获取保存的邮箱和密码
      final email = await secureStorage.getSavedEmail();
      final password = await secureStorage.getSavedPassword();

      if (email == null || password == null) {
        // 没有保存的凭证，无需恢复
        state = const AuthState(isLoggedIn: false);
        return false;
      }

      // 调用登录 API 重新验证
      final response = await _api.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data['data'];
      final token = data['token'];
      final user = data['user'];

      // 更新存储的 token（可能已过期被刷新）
      await secureStorage.setApiToken(token);
      await secureStorage.setUser(
        id: user['_id'] ?? user['id'] ?? '',
        name: user['name'] ?? '',
        email: email,
        avatar: user['avatar']?['path'] ?? '',
      );

      state = AuthState(
        isLoggedIn: true,
        token: token,
        user: AuthUser(
          id: user['_id'] ?? user['id'] ?? '',
          name: user['name'] ?? '',
          email: email,
          avatar: user['avatar']?['path'] ?? '',
          birthday: user['birthday'],
          level: user['level'] ?? 0,
          gender: user['gender'] ?? 'm',
        ),
      );

      return true;
    } catch (e) {
      // 恢复失败，清除过期凭证
      await SecureStorageHolder.instance.clearCredentials();
      await SecureStorageHolder.instance.clearTokens();

      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('401')) return '邮箱或密码错误';
      if (msg.contains('connection')) return '网络连接失败';
    }
    return '登录失败，请稍后重试';
  }

  // ================== 签到 / 用户资料 ==================

  /// 每日签到 (POST /users/punch-in)
  /// 返回服务器返回的签到状态描述（例如 "签到成功" / "已签到"）
  Future<String> punchIn() async {
    final response = await _api.post(ApiEndpoints.punchIn);
    final data = response.data['data'] ?? {};
    // Picac API 返回 {"status": "ok"} 或类似结构，提取可能的消息字段
    return (data['message'] ?? data['msg'] ?? data['status'] ?? '签到成功')
        .toString();
  }

  /// 拉取最新用户资料 (GET /users/profile)，刷新 AuthState.user
  Future<void> refreshProfile() async {
    try {
      final response = await _api.get(ApiEndpoints.userProfile);
      final user = response.data['data']?['user'] ?? response.data['data'];
      if (user is! Map) return;
      final updated = AuthUser(
        id: user['_id'] ?? user['id'] ?? state.user?.id ?? '',
        name: user['name'] ?? state.user?.name ?? '',
        email: user['email'] ?? state.user?.email ?? '',
        avatar: user['avatar']?['path'] ?? state.user?.avatar ?? '',
        birthday: user['birthday'] ?? state.user?.birthday,
        level: user['level'] ?? state.user?.level ?? 0,
        gender: user['gender'] ?? state.user?.gender ?? 'm',
      );
      state = state.copyWith(user: updated);
    } catch (_) {
      // 拉取失败保留旧值
    }
  }
}
