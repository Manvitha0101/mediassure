// services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user id
  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user role in firestore
      if (credential.user != null) {
        UserModel userRole = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          role: role,
          patientIds: [],
          profileCompleted: false,
        );

        await _db
            .collection('users')
            .doc(credential.user!.uid)
            .set(userRole.toMap());
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Log in
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await getUserRole(credential.user!.uid);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get user role
  Future<UserModel?> getUserRole(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Log out
  Future<void> logOut() async {
    await _auth.signOut();
  }
}
