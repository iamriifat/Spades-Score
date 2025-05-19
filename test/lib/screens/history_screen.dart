import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bridge_scorer/providers/game_provider.dart';
import 'package:bridge_scorer/screens/game_screen.dart';
import 'package:bridge_scorer/models/game.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Game History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          final games = provider.games;

          if (games.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_esports_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No games yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Start New Game'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return GameHistoryCard(game: game);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GameHistoryCard extends StatelessWidget {
  final Game game;

  const GameHistoryCard({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: !game.isComplete
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(gameId: game.id),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Game #${game.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: game.isComplete
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      game.isComplete ? 'Completed' : 'In Progress',
                      style: TextStyle(
                        color: game.isComplete
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${dateFormat.format(game.createdAt)} at ${timeFormat.format(game.createdAt)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Team 1',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(game.team1Name),
                        const SizedBox(height: 4),
                        Text(
                          'Score: ${game.team1Total}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Team 2',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(game.team2Name),
                          const SizedBox(height: 4),
                          Text(
                            'Score: ${game.team2Total}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (game.hasWinner) ...[
                const Divider(),
                Text(
                  '🏆 Winner: ${game.winningTeam}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
              if (!game.isComplete) ...[
                const Divider(),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(gameId: game.id),
                        ),
                      );
                    },
                    child: const Text('Continue Game'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}