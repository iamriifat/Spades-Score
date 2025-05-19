
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bridge_scorer/models/game.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  List<Game> _games = [];
  Map<int, Game> _activeGames = {};

  List<Game> get games => _games;
  Map<int, Game> get activeGames => _activeGames;
  Game? getActiveGame(int id) => _activeGames[id];

  Future<void> loadUserGames() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('games')
        .orderBy('createdAt', descending: true)
        .get();

    _games = snapshot.docs.map((doc) {
      final data = doc.data();
      return Game(
        id: data['id'] as int,
        name: data['name'] as String,
        targetPoints: data['targetPoints'] as int,
        player1: data['player1'] as String,
        player2: data['player2'] as String,
        player3: data['player3'] as String,
        player4: data['player4'] as String,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        isComplete: data['isComplete'] ?? false,
        scores: (data['scores'] as List?)?.map((s) => Score(
          id: s['id'] as int,
          round: s['round'] as int,
          team1Points: s['team1Points'] as int,
          team2Points: s['team2Points'] as int,
        )).toList() ?? [],
      );
    }).toList();

    _activeGames = {
      for (var game in _games.where((g) => !g.isComplete))
        game.id: game
    };
    
    notifyListeners();
  }

  Future<Game> createGame({
    required String name,
    required int targetPoints,
    required String player1,
    required String player2,
    required String player3,
    required String player4,
  }) async {
    final gameId = DateTime.now().millisecondsSinceEpoch;
    final game = Game(
      id: gameId,
      name: name,
      targetPoints: targetPoints,
      player1: player1,
      player2: player2,
      player3: player3,
      player4: player4,
      createdAt: DateTime.now(),
    );
    
    _games.add(game);
    _activeGames[gameId] = game;
    await _saveGameToFirebase(game);
    notifyListeners();
    return game;
  }

  Future<void> _saveGameToFirebase(Game game) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('games')
        .doc(game.id.toString())
        .set({
          'id': game.id,
          'name': game.name,
          'targetPoints': game.targetPoints,
          'player1': game.player1,
          'player2': game.player2,
          'player3': game.player3,
          'player4': game.player4,
          'createdAt': game.createdAt,
          'isComplete': game.isComplete,
          'scores': game.scores.map((s) => {
            'id': s.id,
            'round': s.round,
            'team1Points': s.team1Points,
            'team2Points': s.team2Points,
          }).toList(),
        });
  }

  Future<void> addScore({
    required int gameId,
    required int team1Points,
    required int team2Points,
  }) async {
    final gameIndex = _games.indexWhere((g) => g.id == gameId);
    if (gameIndex == -1) return;

    final game = _games[gameIndex];
    final newScore = Score(
      id: game.scores.length + 1,
      round: game.scores.length + 1,
      team1Points: team1Points,
      team2Points: team2Points,
    );

    final updatedGame = game.copyWith(
      scores: [...game.scores, newScore],
    );
    _games[gameIndex] = updatedGame;
    _activeGames[gameId] = updatedGame;
    await _saveGameToFirebase(updatedGame);
    notifyListeners();
  }

  Future<void> deleteScore(int scoreId) async {
    final gameIndex = _games.indexWhere((g) => g.scores.any((s) => s.id == scoreId));
    if (gameIndex == -1) return;

    final game = _games[gameIndex];
    final updatedScores = game.scores.where((s) => s.id != scoreId).toList();

    for (var i = 0; i < updatedScores.length; i++) {
      updatedScores[i] = Score(
        id: i + 1,
        round: i + 1,
        team1Points: updatedScores[i].team1Points,
        team2Points: updatedScores[i].team2Points,
      );
    }

    final updatedGame = game.copyWith(scores: updatedScores);
    _games[gameIndex] = updatedGame;
    _activeGames[game.id] = updatedGame;
    await _saveGameToFirebase(updatedGame);
    notifyListeners();
  }

  Future<void> completeGame(int gameId) async {
    final gameIndex = _games.indexWhere((g) => g.id == gameId);
    if (gameIndex == -1) return;

    final updatedGame = _games[gameIndex].copyWith(isComplete: true);
    _games[gameIndex] = updatedGame;
    _activeGames.remove(gameId);
    await _saveGameToFirebase(updatedGame);
    notifyListeners();
  }

  void loadGame(int gameId) {
    final game = _games.firstWhere((g) => g.id == gameId);
    if (!game.isComplete) {
      _activeGames[gameId] = game;
    }
    notifyListeners();
  }
}
