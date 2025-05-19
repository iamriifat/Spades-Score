import 'package:bridge_scorer/models/game.dart';
import 'package:bridge_scorer/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bridge_scorer/providers/game_provider.dart';
import 'package:bridge_scorer/providers/user_provider.dart';
import 'package:bridge_scorer/screens/game_screen.dart';
import 'package:bridge_scorer/screens/auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _signOut(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isUsingDummyAuth) {
      await userProvider.setDummyUserForTesting(null);
    } else {
      await FirebaseAuth.instance.signOut();
    }
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spades Score'),
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Consumer2<UserProvider, GameProvider>(
        builder: (context, userProvider, gameProvider, _) {
          final userProfile = userProvider.userProfile;
          final activeGames = gameProvider.activeGames.values.toList();
          final completedGames = gameProvider.games
              .where((game) => game.isComplete)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userProfile != null)
                Text(
                  'Active Games',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (activeGames.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No active games'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeGames.length,
                    itemBuilder: (context, index) {
                      final game = activeGames[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(game.name),
                          subtitle: Text('${game.team1Name} vs ${game.team2Name}'),
                          trailing: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(gameId: game.id),
                                ),
                              );
                            },
                            child: const Text('Continue'),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Text(
                  'Completed Games',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (completedGames.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No completed games'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completedGames.length,
                    itemBuilder: (context, index) {
                      final game = completedGames[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(game.name),
                          subtitle: Text(
                            '${game.team1Name} vs ${game.team2Name}\n'
                            'Winner: ${game.winningTeam}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const Padding(
              padding: EdgeInsets.all(16),
              child: NewGameForm(),
            ),
          );
        },
        label: const Text('New Game'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class NewGameForm extends StatefulWidget {
  const NewGameForm({super.key});

  @override
  State<NewGameForm> createState() => _NewGameFormState();
}

class _NewGameFormState extends State<NewGameForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetPointsController = TextEditingController(text: '100');
  final _player1Controller = TextEditingController();
  final _player2Controller = TextEditingController();
  final _player3Controller = TextEditingController();
  final _player4Controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Spades Score',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Game Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a game name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetPointsController,
              decoration: const InputDecoration(
                labelText: 'Target Points',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter target points';
                }
                final points = int.tryParse(value);
                if (points == null || points < 50 || points > 500) {
                  return 'Points must be between 50 and 500';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Team 1',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _player1Controller,
              decoration: const InputDecoration(
                labelText: 'Player 1',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter player name';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _player2Controller,
              decoration: const InputDecoration(
                labelText: 'Player 2',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter player name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Team 2',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _player3Controller,
              decoration: const InputDecoration(
                labelText: 'Player 3',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter player name';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _player4Controller,
              decoration: const InputDecoration(
                labelText: 'Player 4',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter player name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final provider = context.read<GameProvider>();
                  final game = await provider.createGame(
                    name: _nameController.text.trim(),
                    targetPoints: int.parse(_targetPointsController.text),
                    player1: _player1Controller.text.trim(),
                    player2: _player2Controller.text.trim(),
                    player3: _player3Controller.text.trim(),
                    player4: _player4Controller.text.trim(),
                  );
                  Navigator.of(context).pop(); // Close the bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(gameId: game.id),
                    ),
                  );
                }
              },
              child: const Text('Start Game'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetPointsController.dispose();
    _player1Controller.dispose();
    _player2Controller.dispose();
    _player3Controller.dispose();
    _player4Controller.dispose();
    super.dispose();
  }
}
