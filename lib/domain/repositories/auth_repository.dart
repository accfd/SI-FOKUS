import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get onAuthStateChanged;
  
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String? parentAccessCode, // Wajib diisi jika role == 'orang_tua'
  });

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<UserModel?> getCurrentUserData();
}
