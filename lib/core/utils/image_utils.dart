import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:pdfx/pdfx.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Persistent directory for bill images so they survive app updates and cache clears.
  static Future<Directory> _billsDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/Expenza/bills');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _normalizeLocalPath(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('file://')) {
      try {
        return Uri.parse(path).toFilePath();
      } catch (_) {
        return path;
      }
    }
    return path;
  }

  static Future<String?> _persistImageBytesToBillsDir(
    Uint8List bytes, {
    String extension = '.jpg',
  }) async {
    if (kIsWeb) return null;
    if (bytes.isEmpty) return null;

    try {
      final dir = await _billsDirectory();
      final safeExt = extension.isNotEmpty ? extension : '.jpg';
      final name =
          'bill_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().toString().substring(0, 8)}$safeExt';
      final dest = File('${dir.path}/$name');
      await dest.writeAsBytes(bytes, flush: true);
      return dest.path;
    } catch (e) {
      debugPrint('Error persisting image bytes to bills dir: $e');
      return null;
    }
  }

  static Future<String?> _persistXFileToBillsDir(XFile xfile) async {
    if (kIsWeb) return xfile.path;
    try {
      final bytes = await xfile.readAsBytes();
      if (bytes.isEmpty) return null;
      // Try to normalize to JPEG for maximum compatibility (PDF export, sharing, etc.)
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final jpgBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
        return await _persistImageBytesToBillsDir(jpgBytes, extension: '.jpg');
      }

      // Fallback: persist raw bytes with best-effort extension.
      final ext = p.extension(xfile.path).toLowerCase();
      return await _persistImageBytesToBillsDir(
        bytes,
        extension: ext.isNotEmpty ? ext : '.jpg',
      );
    } catch (e) {
      debugPrint('Error persisting XFile to bills dir: $e');
      return null;
    }
  }

  /// Copies file paths to the persistent bills directory. Use for shared intents etc.
  static Future<List<String>> copyToBillsDir(List<String> paths) async {
    if (kIsWeb) return paths;
    final List<String> out = [];
    for (final s in paths) {
      if (s.isEmpty) {
        out.add(s);
        continue;
      }
      out.add(await _copyToBillsDir(s));
    }
    return out;
  }

  /// Copies a file to the persistent bills dir. Returns the new path, or [sourcePath] if copy fails.
  /// If the file is already in the persistent directory, returns the existing path without copying.
  static Future<String> _copyToBillsDir(String sourcePath) async {
    if (kIsWeb) return sourcePath;
    try {
      final normalized = _normalizeLocalPath(sourcePath);
      if (normalized.startsWith('content://')) {
        // Can't be read using dart:io File. Keep as-is; callers should prefer XFile persistence.
        debugPrint('Unsupported content URI path (cannot persist): $normalized');
        return sourcePath;
      }

      final f = File(normalized);
      if (!await f.exists()) return sourcePath;
      
      final dir = await _billsDirectory();
      
      // Check if the file is already in the persistent bills directory
      if (normalized.startsWith(dir.path)) {
        // File is already in persistent storage, return as-is
        return normalized;
      }
      
      // File is not in persistent storage; read bytes and (when possible) re-encode to JPEG
      final ext = p.extension(normalized).toLowerCase();
      final rawBytes = await f.readAsBytes();
      if (rawBytes.isEmpty) return sourcePath;

      // Try to decode using the `image` package (supports many formats like PNG/JPEG/WebP).
      // If decoding fails, fall back to raw copy.
      final decoded = img.decodeImage(rawBytes);
      if (decoded != null) {
        final jpgBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
        final destPath = await _persistImageBytesToBillsDir(jpgBytes, extension: '.jpg');
        if (destPath != null) return destPath;
      }

      // Fallback: raw copy with original extension (or .jpg if unknown)
      final name =
          'bill_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().toString().substring(0, 8)}${ext.isNotEmpty ? ext : '.jpg'}';
      final dest = File('${dir.path}/$name');
      await f.copy(dest.path);
      return dest.path;
    } catch (e) {
      debugPrint('Error copying to bills dir: $e');
      return sourcePath;
    }
  }

  /// Pick an image (Gallery) - Works on Web & Mobile. On mobile, files are copied to app storage so they survive updates.
  static Future<List<String>> pickMultipleImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (kIsWeb) return images.map((e) => e.path).toList();
      final List<String> out = [];
      for (final x in images) {
        // Prefer persisting via bytes (more robust than copying temp paths on some platforms)
        final persisted = await _persistXFileToBillsDir(x);
        if (persisted != null && persisted.isNotEmpty) {
          out.add(persisted);
          continue;
        }

        final s = x.path;
        if (s.isEmpty) continue;
        out.add(await _copyToBillsDir(s));
      }
      return out;
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
    return [];
  }

  /// Scan a document (Camera) - Mobile Only. On mobile, files are copied to app storage so they survive updates.
  static Future<List<String>> scanDocument(BuildContext context) async {
    // WEB FALLBACK: Camera Picker (blob path, no copy)
    if (kIsWeb) {
      final x = await _pickImageFromCamera();
      return x != null ? [x.path] : [];
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final x = await _pickImageFromCamera();
      if (x != null) {
        final persisted = await _persistXFileToBillsDir(x);
        if (persisted != null) return [persisted];
        return [await _copyToBillsDir(x.path)];
      }
      return [];
    }

    // MOBILE: ML Kit Scanner – copy each result to persistent storage
    try {
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
        pageLimit: 10,
      );
      final documentScanner = DocumentScanner(options: options);
      final result = await documentScanner.scanDocument();
      final List<String> out = [];
      for (final src in result.images) {
        out.add(await _copyToBillsDir(src));
      }
      return out;
    } catch (e) {
      debugPrint('Error scanning document: $e');
      final x = await _pickImageFromCamera();
      if (x != null) {
        final persisted = await _persistXFileToBillsDir(x);
        if (persisted != null) return [persisted];
        return [await _copyToBillsDir(x.path)];
      }
      return [];
    }
  }

  static Future<List<String>> pickPdfAndConvert() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb,
      );

      if (result != null) {
        if (kIsWeb && result.files.single.bytes != null) {
          return await _convertPdfDataToImages(result.files.single.bytes!);
        } else if (result.files.single.path != null) {
          return await convertPdfToImages(result.files.single.path!);
        }
      }
    } catch (e) {
      debugPrint('Error picking/converting PDF: $e');
    }
    return [];
  }

  static Future<List<String>> _convertPdfDataToImages(Uint8List data) async {
    final List<String> imagePaths = [];
    try {
      final document = await PdfDocument.openData(data);
      const uuid = Uuid();

      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
          quality: 80,
        );

        if (pageImage != null) {
          if (kIsWeb) {
            final xFile = XFile.fromData(
              pageImage.bytes,
              mimeType: 'image/jpeg',
              name: 'pdf_page_${uuid.v4()}_$i.jpg',
            );
            imagePaths.add(xFile.path);
          } else {
            final dir = await _billsDirectory();
            final fileName = 'pdf_page_${uuid.v4()}_$i.jpg';
            final file = File('${dir.path}/$fileName');
            await file.writeAsBytes(pageImage.bytes);
            imagePaths.add(file.path);
          }
        }
        await page.close();
      }
      await document.close();
    } catch (e) {
      debugPrint('Error converting PDF data to images: $e');
    }
    return imagePaths;
  }

  static Future<List<String>> convertPdfToImages(String pdfPath) async {
    final List<String> imagePaths = [];
    try {
      final document = await PdfDocument.openFile(pdfPath);
      final dir = await _billsDirectory();
      const uuid = Uuid();

      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
          quality: 80,
        );

        if (pageImage != null) {
          final fileName = 'pdf_page_${uuid.v4()}_$i.jpg';
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(pageImage.bytes);
          imagePaths.add(file.path);
        }
        await page.close();
      }
      await document.close();
    } catch (e) {
      debugPrint('Error converting PDF to images: $e');
    }
    return imagePaths;
  }

  /// Converts a list of paths to image paths. PDFs are converted to JPG images;
  /// image paths are returned as-is. Use before sending to AI analysis (Gemini).
  static Future<List<String>> convertPdfPathsToImages(List<String> paths) async {
    if (kIsWeb) return paths;
    final List<String> out = [];
    for (final path in paths) {
      if (path.isEmpty) continue;
      final lower = path.toLowerCase();
      if (lower.endsWith('.pdf')) {
        final images = await convertPdfToImages(path);
        out.addAll(images);
      } else {
        out.add(path);
      }
    }
    return out;
  }

  static Future<XFile?> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image;
    } catch (e) {
      debugPrint('Error accessing camera: $e');
      return null;
    }
  }
}
