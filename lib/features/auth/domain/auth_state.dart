import 'package:flutter/foundation.dart';

/// 认证用户模型
@immutable
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String? birthday;
  final int level;
  final String gender;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    this.birthday,
    required this.level,
    required this.gender,
  });

  AuthUser copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? birthday,
    int? level,
    String? gender,
  }) =>
      AuthUser(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        avatar: avatar ?? this.avatar,
        birthday: birthday ?? this.birthday,
        level: level ?? this.level,
        gender: gender ?? this.gender,
      );
}

/// 认证状态
@immutable
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? token;
  final AuthUser? user;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.token,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? token,
    AuthUser? user,
    String? error,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        isLoading: isLoading ?? this.isLoading,
        token: token ?? this.token,
        user: user ?? this.user,
        error: error,
      );
}
