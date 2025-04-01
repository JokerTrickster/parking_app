import '../entities/user_entity.dart';

abstract class AuthRepository {
  bool login(UserEntity user);
}
