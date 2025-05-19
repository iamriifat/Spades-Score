class Game {
  final int id;
  final String name;
  final int targetPoints;
  final String player1;
  final String player2;
  final String player3; 
  final String player4;
  final DateTime createdAt;
  final bool isComplete;
  final List<Score> scores;

  Game({
    required this.id,
    required this.name,
    required this.targetPoints,
    required this.player1,
    required this.player2,
    required this.player3,
    required this.player4,
    required this.createdAt,
    this.isComplete = false,
    this.scores = const [],
  });

  String get team1Name => "$player1 & $player2";
  String get team2Name => "$player3 & $player4";

  int get team1Total => scores.fold(0, (sum, score) => sum + score.team1Points);
  int get team2Total => scores.fold(0, (sum, score) => sum + score.team2Points);

  bool get hasWinner => team1Total >= targetPoints || team2Total >= targetPoints;
  String? get winningTeam {
    if (!hasWinner) return null;
    return team1Total > team2Total ? team1Name : team2Name;
  }

  Game copyWith({
    int? id,
    String? name,
    int? targetPoints,
    String? player1,
    String? player2,
    String? player3,
    String? player4,
    DateTime? createdAt,
    bool? isComplete,
    List<Score>? scores,
  }) {
    return Game(
      id: id ?? this.id,
      name: name ?? this.name,
      targetPoints: targetPoints ?? this.targetPoints,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      player3: player3 ?? this.player3,
      player4: player4 ?? this.player4,
      createdAt: createdAt ?? this.createdAt,
      isComplete: isComplete ?? this.isComplete,
      scores: scores ?? this.scores,
    );
  }
}

class Score {
  final int id;
  final int round;
  final int team1Points;
  final int team2Points;
  final int? team1Call;
  final int? team2Call;

  Score({
    required this.id,
    required this.round,
    required this.team1Points,
    required this.team2Points,
    this.team1Call,
    this.team2Call,
  });

  int get totalPoints => team1Points + team2Points;
}
