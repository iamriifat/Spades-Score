import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bridge_scorer/providers/game_provider.dart';
import 'package:bridge_scorer/screens/history_screen.dart';
import 'package:bridge_scorer/models/game.dart';

class GameScreen extends StatefulWidget {
  final int gameId;

  const GameScreen({
    super.key,
    required this.gameId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _team1PointsController = TextEditingController();
  final _team2PointsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().loadGame(widget.gameId);
    });
  }

  String? _validatePoints(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final points = int.tryParse(value);
    if (points == null) {
      return 'Must be a number';
    }
    if (points < 0) {
      return 'Cannot be negative';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Game Progress',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          final game = provider.currentGame;
          if (game == null) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGameStatus(game),
                const SizedBox(height: 16),
                if (!game.isComplete) _buildScoreForm(context, game),
                const SizedBox(height: 16),
                _buildScoreboard(game),
                if (!game.isComplete && game.hasWinner)
                  _buildCompleteGameButton(context, game),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameStatus(Game game) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target: ${game.targetPoints} points',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (game.hasWinner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${game.winningTeam} Wins!',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(),
            ListTile(
              title: Text(
                'Team 1: ${game.team1Name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                'Score: ${game.team1Total}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            ListTile(
              title: Text(
                'Team 2: ${game.team2Name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                'Score: ${game.team2Total}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreForm(BuildContext context, Game game) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Round ${game.scores.length + 1}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _team1PointsController,
                      decoration: InputDecoration(
                        labelText: 'Team 1 Points',
                        border: const OutlineInputBorder(),
                        helperText: game.team1Name,
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validatePoints,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _team2PointsController,
                      decoration: InputDecoration(
                        labelText: 'Team 2 Points',
                        border: const OutlineInputBorder(),
                        helperText: game.team2Name,
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validatePoints,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<GameProvider>().addScore(
                      gameId: game.id,
                      team1Points: int.parse(_team1PointsController.text),
                      team2Points: int.parse(_team2PointsController.text),
                    );
                    _team1PointsController.clear();
                    _team2PointsController.clear();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Score'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreboard(Game game) {
    if (game.scores.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No scores yet. Add your first round score above.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Scoreboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Round')),
                DataColumn(label: Text('Team 1')),
                DataColumn(label: Text('Team 2')),
                DataColumn(label: Text('Actions')),
              ],
              rows: game.scores.map((score) {
                return DataRow(
                  cells: [
                    DataCell(Text(score.round.toString())),
                    DataCell(Text(score.team1Points.toString())),
                    DataCell(Text(score.team2Points.toString())),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Score'),
                              content: const Text(
                                'Are you sure you want to delete this round\'s score?'
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context
                                        .read<GameProvider>()
                                        .deleteScore(score.id);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteGameButton(BuildContext context, Game game) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<GameProvider>().completeGame(game.id);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HistoryScreen()),
          );
        },
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Complete Game'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _team1PointsController.dispose();
    _team2PointsController.dispose();
    super.dispose();
  }
}