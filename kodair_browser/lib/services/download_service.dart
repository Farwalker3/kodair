import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../providers/download_provider.dart';

class DownloadService {
  Future<void> download({
    required BuildContext context,
    required DownloadStartRequest request,
  }) async {
    final provider = context.read<DownloadProvider>();
    final sourceUrl = request.url.toString();
    final fileName = _resolveFileName(sourceUrl, request.suggestedFilename);
    provider.begin(fileName: fileName, sourceUrl: sourceUrl);

    final client = http.Client();
    try {
      final targetDirectory = await _resolveDownloadDirectory();
      final targetPath = '${targetDirectory.path}${Platform.pathSeparator}$fileName';
      final targetFile = File(targetPath);

      final response = await client.send(http.Request('GET', Uri.parse(sourceUrl)));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Download failed with status ${response.statusCode}', uri: Uri.parse(sourceUrl));
      }

      final totalBytes = response.contentLength;
      if (totalBytes != null && totalBytes > 0) {
        provider.updateProgress(downloadedBytes: 0, totalBytes: totalBytes);
      }

      final sink = targetFile.openWrite();
      var receivedBytes = 0;
      await for (final chunk in response.stream) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        provider.updateProgress(downloadedBytes: receivedBytes, totalBytes: totalBytes);
      }
      await sink.flush();
      await sink.close();
      provider.complete(savedPath: targetPath);
    } catch (error) {
      provider.fail(error.toString());
    } finally {
      client.close();
    }
  }

  Future<Directory> _resolveDownloadDirectory() async {
    Directory? directory;
    try {
      directory = await getDownloadsDirectory();
    } catch (_) {
      directory = null;
    }
    directory ??= await getApplicationDocumentsDirectory();
    final downloads = Directory('${directory.path}${Platform.pathSeparator}Kodair Downloads');
    if (!await downloads.exists()) {
      await downloads.create(recursive: true);
    }
    return downloads;
  }

  String _resolveFileName(String sourceUrl, String? suggestedFilename) {
    final fallback = _fileNameFromUrl(sourceUrl);
    final raw = (suggestedFilename != null && suggestedFilename.trim().isNotEmpty)
        ? suggestedFilename.trim()
        : fallback;
    final sanitized = raw.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    return sanitized.isEmpty ? 'download' : sanitized;
  }

  String _fileNameFromUrl(String sourceUrl) {
    try {
      final uri = Uri.parse(sourceUrl);
      if (uri.pathSegments.isNotEmpty) {
        final candidate = uri.pathSegments.last;
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
    } catch (_) {
      // Ignore malformed URLs and fall through.
    }
    return 'download';
  }
}
