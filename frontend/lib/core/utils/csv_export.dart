import 'csv_export_io.dart' if (dart.library.html) 'csv_export_web.dart' as impl;

/// Exporte un CSV : téléchargement navigateur sur Web, fichier temporaire + partage ailleurs.
Future<void> exportCsvFile(
  String filename,
  String content, {
  String? shareSubject,
}) =>
    impl.exportCsvFile(filename, content, shareSubject: shareSubject);
