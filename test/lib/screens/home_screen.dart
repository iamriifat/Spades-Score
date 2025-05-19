import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bridge_scorer/providers/game_provider.dart';
import 'package:bridge_scorer/providers/user_provider.dart';
import 'package:bridge_scorer/screens/game_screen.dart';
import 'package:bridge_scorer/screens/history_screen.dart';
import 'package:bridge_scorer/screens/auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _signOut(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // If we're using the dummy auth, just clear the user profile
    if (userProvider.isUsingDummyAuth) {
      await userProvider.setDummyUserForTesting(null);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
      return;
    }
    
    // Otherwise use Firebase Auth signOut
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userProfile = userProvider.userProfile;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spades Score',
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // User profile card
          if (userProfile != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        radius: 30,
                        child: Text(
                          userProfile.displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile.displayName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userProfile.email,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _StatBox(
                                  label: 'Games Played', 
                                  value: userProfile.gamesPlayed.toString(),
                                ),
                                const SizedBox(width: 16),
                                _StatBox(
                                  label: 'Games Won', 
                                  value: userProfile.gamesWon.toString(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Expanded(
            child: NewGameForm(),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  
  const _StatBox({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
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
  final _targetPointsController = TextEditingController(text: '100');
  final _player1Controller = TextEditingController();
  final _player2Controller = TextEditingController();
  final _player3Controller = TextEditingController();
  final _player4Controller = TextEditingController();

  String? _validatePlayerName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter player name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateTargetPoints(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter target points';
    }
    final points = int.tryParse(value);
    if (points == null) {
      return 'Must be a number';
    }
    if (points < 50) {
      return 'Minimum 50 points';
    }
    if (points > 500) {
      return 'Maximum 500 points';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetPointsController,
                      decoration: const InputDecoration(
                        labelText: 'Target Points',
                        helperText: 'Points needed to win (50-500)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validateTargetPoints,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team 1',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _player1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Player 1',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: _validatePlayerName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _player2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Player 2',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: _validatePlayerName,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team 2',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _player3Controller,
                      decoration: const InputDecoration(
                        labelText: 'Player 3',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: _validatePlayerName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _player4Controller,
                      decoration: const InputDecoration(
                        labelText: 'Player 4',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: _validatePlayerName,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final provider = context.read<GameProvider>();
                  provider.createGame(
                    targetPoints: int.parse(_targetPointsController.text),
                    player1: _player1Controller.text.trim(),
                    player2: _player2Controller.text.trim(),
                    player3: _player3Controller.text.trim(),
                    player4: _player4Controller.text.trim(),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameScreen(
                        gameId: provider.currentGame!.id,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Start Game',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _targetPointsController.dispose();
    _player1Controller.dispose();
    _player2Controller.dispose();
    _player3Controller.dispose();
    _player4Controller.dispose();
    super.dispose();
  }
}