// Native (non-web) platform export helpers.
// Used via: import 'export_stub.dart' if (dart.library.html) 'export_web.dart';

import 'dart:io';
import 'dart:convert';

// --- Web-only stubs (no-ops on native) ---

void downloadFileWeb(String filename, List<int> bytes) {
  // No-op on native — use saveAndOpenNative instead
}

void downloadTextWeb(String filename, String content) {
  // No-op on native — use saveAndOpenNative instead
}

void printWeb() {
  // No-op on native
}

// --- Native file I/O helpers ---

Future<void> saveAndOpenNative(String filename, List<int> bytes) async {
  try {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    // open_filex is not available via stub — open via process if possible
    // For now, just write the file (works for desktop/mobile via file managers)
  } catch (_) {}
}

Future<void> saveTextAndOpenNative(String filename, String content) async {
  try {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
  } catch (_) {}
}
