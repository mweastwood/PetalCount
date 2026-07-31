import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'logic/logic.dart';
import 'screens/login_screen.dart';
import 'screens/chart_selection_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Services.init();
  mainCommon();
}

void mainCommon() {
  runApp(const PetalCountApp());
}

class PetalCountApp extends StatelessWidget {
  const PetalCountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightScheme = lightDynamic;
          darkScheme = darkDynamic;
        } else {
          lightScheme = ColorScheme.fromSeed(
            seedColor: Colors.pink,
            primary: const Color(0xFFD81B60),
            secondary: const Color(0xFF8E24AA),
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: Colors.pink,
            primary: const Color(0xFFF48FB1),
            secondary: const Color(0xFFCE93D8),
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Petal Count',
          theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
          darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
          home: const AuthGate(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Services.db.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        final chartId = Services.db.currentChartId;
        if (chartId == null) {
          return const ChartSelectionScreen();
        }

        return const DashboardScreen();
      },
    );
  }
}
