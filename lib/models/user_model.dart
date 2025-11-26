// lib/models/user_model.dart

enum UserRole {
  Buyer,
  SellerAgent,
}

// A simple model to hold user data retrieved from Firestore
class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });
}