// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/notes_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = NotesProvider();

            // Initialize the database and load the initial data.
            // Errors are retained by NotesProvider for the UI to display.
            unawaited(provider.initialize().catchError((Object error) {}));

            return provider;
          },
        ),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const Wl11NoteApp(),
    ),
  );
}

class Wl11NoteApp extends StatelessWidget {
  const Wl11NoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'WL11note',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: provider.themeMode,
          home: const MainScreen(),
        );
      },
    );
  }
}
