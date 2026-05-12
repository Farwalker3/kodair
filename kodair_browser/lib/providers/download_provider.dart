import 'dart:async';
import 'package:flutter/material.dart';

enum DownloadStatus { idle, downloading, completed, failed }

class DownloadProvider extends ChangeNotifier {
  DownloadStatus _status = DownloadStatus.idle;
  bool _isVisible = false;
  bool _isSuppressed = false;
  String _fileName = '';
  String _sourceUrl = '';
  String? _savedPath;
  String? _errorMessage;
  int _downloadedBytes = 0;
  int? _totalBytes;
  Timer? _dismissTimer;

  DownloadStatus get status => _status;
  bool get isVisible => _isVisible;
  String get fileName => _fileName;
  String get sourceUrl => _sourceUrl;
  String? get savedPath => _savedPath;
  String? get errorMessage => _errorMessage;
  int get downloadedBytes => _downloadedBytes;
  int? get totalBytes => _totalBytes;
  bool get hasProgress => _totalBytes != null && _totalBytes! > 0;
  double? get progress => hasProgress ? (_downloadedBytes / _totalBytes!).clamp(0.0, 1.0) : null;

  void begin({required String fileName, required String sourceUrl}) {
    _dismissTimer?.cancel();
    _status = DownloadStatus.downloading;
    _isVisible = true;
    _isSuppressed = false;
    _fileName = fileName;
    _sourceUrl = sourceUrl;
    _savedPath = null;
    _errorMessage = null;
    _downloadedBytes = 0;
    _totalBytes = null;
    notifyListeners();
  }

  void updateProgress({required int downloadedBytes, int? totalBytes}) {
    _downloadedBytes = downloadedBytes;
    if (totalBytes != null && totalBytes > 0) {
      _totalBytes = totalBytes;
    }
    if (!_isSuppressed) {
      notifyListeners();
    }
  }

  void complete({required String savedPath}) {
    _status = DownloadStatus.completed;
    _savedPath = savedPath;
    if (_totalBytes == null) {
      _totalBytes = _downloadedBytes;
    }
    _downloadedBytes = _totalBytes ?? _downloadedBytes;
    if (_isSuppressed) {
      notifyListeners();
      return;
    }
    _isVisible = true;
    notifyListeners();
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 2), dismiss);
  }

  void fail(String message) {
    _dismissTimer?.cancel();
    _status = DownloadStatus.failed;
    _isVisible = true;
    _isSuppressed = false;
    _errorMessage = message;
    notifyListeners();
  }

  void dismiss() {
    _dismissTimer?.cancel();
    _isVisible = false;
    _isSuppressed = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}
