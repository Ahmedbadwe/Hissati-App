import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

/// Singleton service that handles authentication-related Firestore reads/writes
/// and Firebase Auth sign-out.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Reads the user profile document from the 'users' collection by [uid].
  /// Returns `null` if the document does not exist.
  Future<AppUser?> fetchExistingProfile(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) return null;

    return AppUser.fromDoc(doc);
  }

  /// Creates a new user profile document in the 'users' collection.
  /// The document ID is set to [user.uid].
  Future<void> createProfile(AppUser user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap());
  }

  /// Signs the current user out of Firebase Auth.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
