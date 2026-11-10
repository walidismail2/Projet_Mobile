import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DocumentStorage {
  DocumentStorage._();

  static Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'health_docs'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copie un fichier choisi vers le stockage local de l’app.
  static Future<({String path, String sizeLabel, String fileName})> saveLocal(
    String sourcePath, {
    required bool isPdf,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Fichier introuvable');
    }
    final bytes = await source.length();
    final dir = await _dir();
    final ext = isPdf
        ? '.pdf'
        : p.extension(sourcePath).isEmpty
            ? '.jpg'
            : p.extension(sourcePath).toLowerCase();
    final base = p.basenameWithoutExtension(sourcePath);
    final safe = base
        .replaceAll(RegExp(r'[^\w\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    final name = '${DateTime.now().millisecondsSinceEpoch}_${safe.isEmpty ? 'doc' : safe}$ext';
    final dest = p.join(dir.path, name);
    await source.copy(dest);
    return (path: dest, sizeLabel: formatBytes(bytes), fileName: p.basename(sourcePath));
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(bytes < 10 * 1024 ? 1 : 0)} Ko';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
