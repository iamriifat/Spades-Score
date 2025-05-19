import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bridge_scorer/models/user_profile.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  final _firestore = FirebaseFirestore.instance;
  // This is for development testing only when reCAPTCHA fails
  bool _isUsingDummyAuth = false;

  UserProfile? get userProfile => _userProfile;
  bool get isUsingDummyAuth => _isUsingDummyAuth;

  // This method will be used when Firebase Auth fails due to reCAPTCHA issues
  Future<void> setDummyUserForTesting(UserProfile? userProfile) async {
    _userProfile = userProfile;
    _isUsingDummyAuth = userProfile != null;
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    // If we're using the dummy auth for testing, don't try to load from Firebase
    if (_isUsingDummyAuth) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _userProfile = UserProfile.fromMap(doc.data()!);
      } else {
        // Create new profile if it doesn't exist
        final newProfile = UserProfile(
          id: user.uid,
          email: user.email!,
          displayName: user.displayName ?? user.email!.split('@')[0],
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(user.uid).set(newProfile.toMap());
        _userProfile = newProfile;
      }
      notifyListeners();
    } catch (e) {
      print('Error loading user profile: $e');
      // Handle any Firestore errors here
    }
  }

  Future<void> updateProfile({String? displayName}) async {
    if (_userProfile == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;

    await _firestore.collection('users').doc(_userProfile!.id).update(updates);
    await loadUserProfile(); // Reload profile
  }

  Future<void> incrementGamesPlayed({bool won = false}) async {
    if (_userProfile == null) return;

    final updates = {
      'gamesPlayed': FieldValue.increment(1),
      if (won) 'gamesWon': FieldValue.increment(1),
    };

    await _firestore.collection('users').doc(_userProfile!.id).update(updates);
    await loadUserProfile(); // Reload profile
  }
}
