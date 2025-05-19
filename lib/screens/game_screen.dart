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
  final _team1BidController = TextEditingController();
  final _team2BidController = TextEditingController();

  // Add state to track if bids have been set for the current round
  bool _bidsSet = false;
  int? _currentRound;
  // New: Track if each team met their bid (for post-bid UI)
  bool? _team1MetBid;
  bool? _team2MetBid;

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
  void dispose() {
    _team1PointsController.dispose();
    _team2PointsController.dispose();
    _team1BidController.dispose();
    _team2BidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<GameProvider>(
          builder: (context, provider, child) {
            final game = provider.getActiveGame(widget.gameId);
            return Text(game?.name ?? 'Game Progress');
          },
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
          final game = provider.getActiveGame(widget.gameId);
          if (game == null) return const Center(child: CircularProgressIndicator());

          final isFirstRound = game.scores.isEmpty;
          final round = game.scores.length + 1;
          // Only one form visible: bids for round >=2 and not set, else met-bid buttons or score form
          Widget formWidget;
          if (!isFirstRound && (!_bidsSet || _currentRound != round)) {
            formWidget = _buildBidsForm(game);
          } else if (!isFirstRound && _bidsSet && (_team1MetBid == null || _team2MetBid == null)) {
            formWidget = _buildMetBidButtons(context, game);
          } else {
            formWidget = _buildScoreForm(context, game);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGameStatus(game),
                const SizedBox(height: 16),
                if (!game.isComplete) formWidget,
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

  Widget _buildBidsForm(Game game) {
    final isFirstRound = game.scores.isEmpty;
    final round = game.scores.length + 1;
    if (isFirstRound) return const SizedBox.shrink();
    // Only show bid entry if not set for this round
    if (!_bidsSet || _currentRound != round) {
      _currentRound = round;
      // Reset met-bid state for new round
      _team1MetBid = null;
      _team2MetBid = null;
      return Card(
        margin: const EdgeInsets.only(top: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Bids', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _team1BidController,
                      decoration: InputDecoration(
                        labelText: 'Team 1 Bid',
                        border: const OutlineInputBorder(),
                        helperText: game.team1Name,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _team2BidController,
                      decoration: InputDecoration(
                        labelText: 'Team 2 Bid',
                        border: const OutlineInputBorder(),
                        helperText: game.team2Name,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _bidsSet = true;
                    _team1MetBid = null;
                    _team2MetBid = null;
                  });
                },
                icon: const Icon(Icons.check),
                label: const Text('Bid'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Show the entered bids in a summary card
      return Card(
        margin: const EdgeInsets.only(top: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Bids', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(game.team1Name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(_team1BidController.text.isEmpty ? '-' : _team1BidController.text),
                    ],
                  ),
                  Column(
                    children: [
                      Text(game.team2Name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(_team2BidController.text.isEmpty ? '-' : _team2BidController.text),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  // New: After bids, show buttons to select if each team met their bid
  Widget _buildMetBidButtons(BuildContext context, Game game) {
    final team1Bid = int.tryParse(_team1BidController.text);
    final team2Bid = int.tryParse(_team2BidController.text);
    final round = game.scores.length + 1;
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Round #$round',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text("Team 1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Bid: $team1Bid", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _team1MetBid == true
                                ? null
                                : () {
                                    setState(() {
                                      _team1MetBid = true;
                                    });
                                    _trySubmitMetBid(context, game, team1Bid, team2Bid);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _team1MetBid == true ? Colors.green : null,
                              minimumSize: const Size(40, 40), // Smaller size
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: const Text('+', style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _team1MetBid == false
                                ? null
                                : () {
                                    setState(() {
                                      _team1MetBid = false;
                                    });
                                    _trySubmitMetBid(context, game, team1Bid, team2Bid);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _team1MetBid == false ? Colors.red : null,
                              minimumSize: const Size(40, 40), // Smaller size
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: const Text('-', style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      const Text("Team 2", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Bid: $team2Bid", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _team2MetBid == true
                                ? null
                                : () {
                                    setState(() {
                                      _team2MetBid = true;
                                    });
                                    _trySubmitMetBid(context, game, team1Bid, team2Bid);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _team2MetBid == true ? Colors.green : null,
                              minimumSize: const Size(40, 40), // Smaller size
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: const Text('+', style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _team2MetBid == false
                                ? null
                                : () {
                                    setState(() {
                                      _team2MetBid = false;
                                    });
                                    _trySubmitMetBid(context, game, team1Bid, team2Bid);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _team2MetBid == false ? Colors.red : null,
                              minimumSize: const Size(40, 40), // Smaller size
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: const Text('-', style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper: When both teams have selected, apply logic and update score
  void _trySubmitMetBid(BuildContext context, Game game, int? team1Bid, int? team2Bid) {
    if (_team1MetBid != null && _team2MetBid != null) {
      int t1Score = 0;
      int t2Score = 0;
      if (team1Bid != null) {
        t1Score = _team1MetBid! ? team1Bid : -team1Bid;
      }
      if (team2Bid != null) {
        t2Score = _team2MetBid! ? team2Bid : -team2Bid;
      }
      context.read<GameProvider>().addScore(
        gameId: game.id,
        team1Points: t1Score,
        team2Points: t2Score,
      );
      setState(() {
        _bidsSet = false;
        _team1MetBid = null;
        _team2MetBid = null;
        _team1BidController.clear();
        _team2BidController.clear();
      });
    }
  }

  Widget _buildScoreForm(BuildContext context, Game game) {
    final isFirstRound = game.scores.isEmpty;
    final round = game.scores.length + 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Round $round',
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
                    final team1Points = int.parse(_team1PointsController.text);
                    final team2Points = int.parse(_team2PointsController.text);
                    final isFirstRound = game.scores.isEmpty;
                    int? team1Bid;
                    int? team2Bid;
                    if (!isFirstRound) {
                      team1Bid = int.tryParse(_team1BidController.text);
                      team2Bid = int.tryParse(_team2BidController.text);
                    }
                    if (isFirstRound) {
                      context.read<GameProvider>().addScore(
                        gameId: game.id,
                        team1Points: team1Points,
                        team2Points: team2Points,
                      );
                    } else {
                      int t1Score = 0;
                      int t2Score = 0;
                      if (team1Bid != null) {
                        t1Score = (team1Points >= team1Bid) ? team1Bid : -team1Bid;
                      }
                      if (team2Bid != null) {
                        t2Score = (team2Points >= team2Bid) ? team2Bid : -team2Bid;
                      }
                      context.read<GameProvider>().addScore(
                        gameId: game.id,
                        team1Points: t1Score,
                        team2Points: t2Score,
                      );
                      setState(() {
                        _bidsSet = false;
                      });
                    }
                    _team1PointsController.clear();
                    _team2PointsController.clear();
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(isFirstRound ? 'Add Score' : 'Add Score'),
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
            padding: const EdgeInsets.all(12),
            child: Text(
              'Scoreboard',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 46,
                    dataRowMinHeight: 28,
                    dataRowMaxHeight: 32,
                    headingRowHeight: 32,
                    horizontalMargin: 8,
                    columns: const [
                      DataColumn(label: Text('Round', style: TextStyle(fontSize: 13))),
                      DataColumn(label: Text('Team 1', style: TextStyle(fontSize: 13))),
                      DataColumn(label: Text('Team 2', style: TextStyle(fontSize: 13))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontSize: 13))),
                    ],
                    rows: game.scores.map((score) {
                      return DataRow(
                        cells: [
                          DataCell(Center(child: Text(score.round.toString(), style: const TextStyle(fontSize: 13)))),
                          DataCell(Center(child: Text(score.team1Points.toString(), style: const TextStyle(fontSize: 13)))),
                          DataCell(Center(child: Text(score.team2Points.toString(), style: const TextStyle(fontSize: 13)))),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
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
              );
            },
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
}