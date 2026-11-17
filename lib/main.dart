// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/notes_provider.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final provider = NotesProvider();

        // Initialize the database and load the initial data.
        // Errors are retained by NotesProvider for the UI to display.
        unawaited(provider.initialize().catchError((Object error) {}));

        return provider;
      },
      child: const Wl11NoteApp(),
    ),
  );
}

class Wl11NoteApp extends StatelessWidget {
  const Wl11NoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'wl11_note',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
