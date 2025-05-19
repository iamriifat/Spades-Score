import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final int gamesPlayed;
  final int gamesWon;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      email: map['email'],
      displayName: map['displayName'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      gamesPlayed: map['gamesPlayed'] ?? 0,
      gamesWon: map['gamesWon'] ?? 0,
    );
  }
}
