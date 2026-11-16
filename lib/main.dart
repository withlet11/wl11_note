// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/notes_provider.dart';

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
      home: const InitializationScreen(),
    );
  }
}

class InitializationScreen extends StatelessWidget {
  const InitializationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('wl11_note')),
      body: Consumer<NotesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text('Initialization failed'),
                    const SizedBox(height: 8),
                    Text(
                      provider.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        unawaited(
                          provider.initialize().catchError((Object error) {}),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initialization successful',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 16),
                Text('Active notes: ${provider.activeNotes.length}'),
                Text('Deleted notes: ${provider.deletedNotes.length}'),
                Text('Tags: ${provider.tags.length}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
