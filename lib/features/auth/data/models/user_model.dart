import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({required super.uid, required super.email});

  factory UserModel.fromFirebaseUser(fb.User user) {
    return UserModel(uid: user.uid, email: user.email ?? '');
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(uid: json['uid'] as String, email: json['email'] as String);
  }

  Map<String, dynamic> toJson() => {'uid': uid, 'email': email};
}
