import 'dart:convert';
import 'dart:html' as html;

/// Export CSV sur **Web** : déclenche le téléchargement du fichier (pas de path_provider).
Future<void> exportCsvFile(
  String filename,
  String content, {
  String? shareSubject,
}) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final safeName = filename.replaceAll(RegExp(r'[\\/]'), '_');
  html.AnchorElement(href: url)
    ..setAttribute('download', safeName)
    ..style.display = 'none'
    ..click();
  html.Url.revokeObjectUrl(url);
}
