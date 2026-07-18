import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { tutor, parent }

extension UserRoleExtension on UserRole {
  String toShortString() {
    switch (this) {
      case UserRole.tutor:
        return 'tutor';
      case UserRole.parent:
        return 'parent';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'tutor':
        return UserRole.tutor;
      case 'parent':
        return UserRole.parent;
      default:
        throw ArgumentError('Unknown UserRole: $value');
    }
  }
}

class AppUser {
  final String uid;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      role: UserRoleExtension.fromString(data['role'] ?? 'parent'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role.toShortString(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
