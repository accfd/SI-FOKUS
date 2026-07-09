import '../../../data/models/user_model.dart';

abstract class AuthEvent {
  const AuthEvent();
}

class SignUpRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;
  final String? parentAccessCode;

  const SignUpRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.parentAccessCode,
  });
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class GetUserDataRequested extends AuthEvent {
  const GetUserDataRequested();
}

class AuthStatusChanged extends AuthEvent {
  final UserModel? user;

  const AuthStatusChanged(this.user);
}
