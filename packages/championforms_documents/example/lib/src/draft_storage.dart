import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Where Save / Load keep the draft. Injected so tests can use memory.
abstract class DraftStorage {
  /// Human-readable location, shown after a save.
  String get location;

  Future<void> write(String json);

  /// The saved JSON, or null when nothing was saved.
  Future<String?> read();
}

/// Keeps the draft in memory (tests, and the web build, which has no file
/// system).
class MemoryDraftStorage implements DraftStorage {
  String? _json;

  @override
  String get location => 'memory';

  @override
  Future<void> write(String json) async => _json = json;

  @override
  Future<String?> read() async => _json;
}

/// Writes `agreement_draft.json` to the app documents directory
/// (`path_provider`).
class FileDraftStorage implements DraftStorage {
  FileDraftStorage({this.fileName = 'agreement_draft.json'});

  final String fileName;
  String? _path;

  @override
  String get location => _path ?? fileName;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    _path = file.path;
    return file;
  }

  @override
  Future<void> write(String json) async {
    final file = await _file();
    await file.create(recursive: true);
    await file.writeAsString(json, flush: true);
  }

  @override
  Future<String?> read() async {
    final file = await _file();
    if (!await file.exists()) return null;
    return file.readAsString();
  }
}

/// The storage for this platform: a file where there is a file system,
/// memory on the web.
DraftStorage defaultDraftStorage() =>
    kIsWeb ? MemoryDraftStorage() : FileDraftStorage();
