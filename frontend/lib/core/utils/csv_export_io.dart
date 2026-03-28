import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Export CSV sur mobile / desktop : fichier temporaire + partage système.
Future<void> exportCsvFile(
  String filename,
  String content, {
  String? shareSubject,
}) async {
  final dir = await getTemporaryDirectory();
  final safeName = filename.replaceAll(RegExp(r'[\\/]'), '_');
  final file = File('${dir.path}/$safeName');
  await file.writeAsString(content, flush: true);
  await Share.shareXFiles(
    [XFile(file.path)],
    text: shareSubject ?? safeName,
  );
}
