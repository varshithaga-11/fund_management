// Web-only export helpers — imported only when dart.library.html is present.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

void downloadFileWeb(String filename, List<int> bytes) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void downloadTextWeb(String filename, String content) {
  final mimeType = filename.endsWith('.csv')
      ? 'text/csv'
      : filename.endsWith('.xlsx')
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : filename.endsWith('.doc')
              ? 'application/msword'
              : 'text/plain';
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void printWeb() {
  html.window.print();
}

// Stubs for native-only functions (no-op on web)
Future<void> saveAndOpenNative(String filename, List<int> bytes) async {}
Future<void> saveTextAndOpenNative(String filename, String content) async {}
