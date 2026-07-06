import 'dart:typed_data';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  Future<String?> saveScanImage(Uint8List imageBytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final captureDirectory = Directory(p.join(directory.path, 'captures'));
    if (!captureDirectory.existsSync()) {
      captureDirectory.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final savedPath = p.join(captureDirectory.path, 'leaf_$timestamp.jpg');
    await File(savedPath).writeAsBytes(imageBytes, flush: true);
    return savedPath;
  }
}
