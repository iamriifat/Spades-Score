import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bridge_scorer/screens/auth_screen.dart';
import 'package:bridge_scorer/screens/home_screen.dart';
import 'package:bridge_scorer/providers/game_provider.dart';
import 'package:bridge_scorer/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Spades Score',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3F51B5), // Royal blue from card.jpg
            primary: const Color(0xFF3F51B5),
            secondary: const Color(0xFF5C6BC0), // Lighter shade of royal blue
            tertiary: const Color(0xFF303F9F), // Darker shade of royal blue
            background: Colors.white,
          ),
          useMaterial3: true,
          cardTheme: CardTheme(
            elevation: 12,
            shadowColor: const Color(0xFF3F51B5).withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF3F51B5).withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF3F51B5).withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3F51B5),
                width: 2,
              ),
            ),
            prefixIconColor: Color(0xFF3F51B5),
            labelStyle: const TextStyle(color: Color(0xFF3F51B5)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 8,
              backgroundColor: const Color(0xFF3F51B5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3F51B5),
            ),
          ),
        ),
        home: Builder(
          builder: (context) {
            // Check if we're using our custom auth for testing
            final userProvider = context.watch<UserProvider>();
            if (userProvider.isUsingDummyAuth && userProvider.userProfile != null) {
              return const HomeScreen();
            }
            
            // Otherwise use the standard Firebase Auth
            return StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3F51B5),
                    ),
                  );
                }
                if (snapshot.hasData) {
                  // Load user profile and games when authenticated
                  final userProvider = context.read<UserProvider>();
                  final gameProvider = context.read<GameProvider>();
                  if (userProvider.userProfile == null) {
                    userProvider.loadUserProfile();
                  }
                  gameProvider.loadUserGames();
                  return const HomeScreen();
                }
                return const AuthScreen();
              },
            );
          },
        ),
      ),
    );
  }
}