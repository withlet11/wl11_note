# wl11_note

A lightweight, local-first note-taking application for Linux and Android.

## Overview

`wl11_note` is a Markdown-based note-taking application designed to keep note management simple and practical.

### Features

- Create, edit, and delete notes
- Markdown editing and preview
- Organize notes with tags
- Search notes and tags
- Filter notes by tags
- Local storage with SQLite
- Offline-first operation

## Supported Platforms

- Linux
- Android

## Technology Stack

- Flutter
- Dart
- Provider
- SQLite (`sqflite`)

## Development

### Requirements

- Flutter SDK
- Dart SDK
- Android development environment (for Android builds)
- Linux desktop development dependencies (for Linux builds)

### Setup

Clone the repository:

```bash
git clone https://github.com/withlet11/wl11_note.git
cd wl11_note
```

Install dependencies:

```bash
flutter pub get
```

Run the application on Linux:

```bash
flutter run -d linux
```

To run on an Android device:

```bash
flutter devices
flutter run -d <device-id>
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.