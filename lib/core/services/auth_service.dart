import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase/firestore_collections.dart';
import 'slam_firestore_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  User? get currentUser => Firebase.apps.isEmpty ? null : _auth.currentUser;
  Stream<User?> get authStateChanges => Firebase.apps.isEmpty
      ? Stream<User?>.value(null)
      : _auth.authStateChanges();

  bool requiresEmailVerification(User user) {
    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    );
    final hasGoogleProvider = user.providerData.any(
      (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    );

    return hasPasswordProvider && !hasGoogleProvider && !user.emailVerified;
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user case final user?
        when !requiresEmailVerification(user)) {
      await _upsertUserProfile(user);
    }
    return credential;
  }

  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user?.updateDisplayName(name.trim());
    await credential.user?.sendEmailVerification();

    return credential;
  }

  Future<UserCredential> loginWithGoogle() async {
    await _googleSignIn.initialize();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-token',
        message: 'Google sign in did not return a valid token.',
      );
    }

    final credential = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );

    await _upsertUserProfile(credential.user);
    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendCurrentUserVerificationEmail() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No signed in user found.');
    }

    if (!requiresEmailVerification(user)) {
      return;
    }

    await user.sendEmailVerification();
  }

  Future<User?> reloadCurrentUser() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    await user.reload();
    return _auth.currentUser;
  }

  Future<void> ensureCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No signed in user found.');
    }

    await _upsertUserProfile(user);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No signed in user found.');
    }

    return _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> currentUserProfileStream() {
    final user = currentUser;
    if (user == null || Firebase.apps.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .snapshots();
  }

  Future<void> updateUserProfile({
    required String name,
    required String username,
    required String phone,
    String? localPhotoPath,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No signed in user found.');
    }

    final cleanName = name.trim();
    final cleanUsername = _buildUsername(null, username);
    final cleanPhone = phone.trim();
    final photoUrl = localPhotoPath == null
        ? user.photoURL ?? ''
        : await _uploadProfilePhoto(user.uid, localPhotoPath);

    await user.updateDisplayName(cleanName);
    if (photoUrl.isNotEmpty) {
      await user.updatePhotoURL(photoUrl);
    }
    await _firestore.collection(FirestoreCollections.users).doc(user.uid).set({
      'id': user.uid,
      'name': cleanName,
      'email': user.email ?? '',
      'phone': cleanPhone,
      'photoUrl': photoUrl,
      'username': cleanUsername,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> logout() async {
    if (Firebase.apps.isEmpty) {
      return;
    }

    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    if (Firebase.apps.isEmpty) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final userId = user.uid;
    final slams = await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.slams)
        .get();

    for (final slam in slams.docs) {
      await SlamFirestoreService.instance.deleteSlam(
        ownerUserId: userId,
        slamId: slam.id,
      );
    }

    await _deleteUserDocumentIfAllowed(userId);
    await _googleSignIn.signOut();
    await user.delete();
  }

  Future<void> _upsertUserProfile(User? user, {String? fallbackName}) async {
    if (user == null) {
      return;
    }

    final now = FieldValue.serverTimestamp();
    final userRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid);

    final snapshot = await userRef.get();
    final profileData = <String, Object?>{
      'id': user.uid,
      'name': user.displayName ?? fallbackName ?? '',
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
      'photoUrl': user.photoURL ?? '',
      'username': _buildUsername(user.email, user.displayName ?? fallbackName),
      'updatedAt': now,
    };

    if (!snapshot.exists) {
      profileData['createdAt'] = now;
    }

    await userRef.set(profileData, SetOptions(merge: true));
  }

  Future<void> _deleteUserDocumentIfAllowed(String userId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .delete();
    } on FirebaseException catch (error) {
      const nonBlockingCodes = {'permission-denied', 'not-found'};
      if (!nonBlockingCodes.contains(error.code)) {
        rethrow;
      }
    }
  }

  Future<String> _uploadProfilePhoto(String userId, String localPath) async {
    final ref = FirebaseStorage.instance.ref(
      'users/$userId/slams/_profile/profile.jpg',
    );
    final snapshot = await ref.putFile(
      File(localPath),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return snapshot.ref.getDownloadURL();
  }

  String _buildUsername(String? email, String? name) {
    final source = email?.split('@').first ?? name ?? 'slamora_user';
    return source
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }
}
