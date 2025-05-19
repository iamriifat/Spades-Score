import 'package:flutter/foundation.dart';
import 'package:bridge_scorer/models/game.dart';

class GameProvider extends ChangeNotifier {
  List<Game> _games = [];
  Game? _currentGame;

  List<Game> get games => _games;
  Game? get currentGame => _currentGame;

  void createGame({
    required int targetPoints,
    required String player1,
    required String player2,
    required String player3,
    required String player4,
  }) {
    final game = Game(
      id: _games.length + 1,
      targetPoints: targetPoints,
      player1: player1,
      player2: player2,
      player3: player3,
      player4: player4,
      createdAt: DateTime.now(),
    );
    _games.add(game);
    _currentGame = game;
    notifyListeners();
  }

  void addScore({
    required int gameId,
    required int team1Points,
    required int team2Points,
  }) {
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
    _currentGame = updatedGame;
    notifyListeners();
  }

  void deleteScore(int scoreId) {
    final gameIndex = _games.indexWhere((g) => g.scores.any((s) => s.id == scoreId));
    if (gameIndex == -1) return;

    final game = _games[gameIndex];
    final updatedScores = game.scores.where((s) => s.id != scoreId).toList();

    // Update the round numbers after deletion
    for (var i = 0; i < updatedScores.length; i++) {
      updatedScores[i] = Score(
        id: updatedScores[i].id,
        round: i + 1,
        team1Points: updatedScores[i].team1Points,
        team2Points: updatedScores[i].team2Points,
      );
    }

    final updatedGame = game.copyWith(scores: updatedScores);
    _games[gameIndex] = updatedGame;
    _currentGame = updatedGame;
    notifyListeners();
  }

  void completeGame(int gameId) {
    final gameIndex = _games.indexWhere((g) => g.id == gameId);
    if (gameIndex == -1) return;

    _games[gameIndex] = _games[gameIndex].copyWith(isComplete: true);
    notifyListeners();
  }

  void loadGame(int gameId) {
    _currentGame = _games.firstWhere((g) => g.id == gameId);
    notifyListeners();
  }
}