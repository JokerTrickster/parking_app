import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  bool login(UserEntity user) {
    // Simulate a login check
    return user.username == 'admin' && user.password == '1234';
  }
}
