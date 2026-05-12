import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/download_provider.dart';
import '../theme/kodair_theme.dart';

class DownloadOverlay extends StatelessWidget {
  const DownloadOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, downloads, _) {
        if (!downloads.isVisible) {
          return const SizedBox.shrink();
        }

        final isCompleted = downloads.status == DownloadStatus.completed;
        final isFailed = downloads.status == DownloadStatus.failed;
        final progressValue = downloads.progress;
        final statusText = isFailed
            ? 'Download failed'
            : isCompleted
                ? 'Download complete'
                : 'Downloading';

        return Positioned(
          right: 16,
          bottom: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF121826).withAlpha(245),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isFailed
                              ? Colors.redAccent.withAlpha(50)
                              : isCompleted
                                  ? Colors.greenAccent.withAlpha(50)
                                  : KodairTheme.primaryBlue.withAlpha(45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isFailed
                              ? Icons.error_outline
                              : isCompleted
                                  ? Icons.check_circle_outline
                                  : Icons.file_download_outlined,
                          color: isFailed
                              ? Colors.redAccent
                              : isCompleted
                                  ? Colors.greenAccent
                                  : KodairTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              downloads.fileName.isEmpty ? downloads.sourceUrl : downloads.fileName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: downloads.dismiss,
                        icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        splashRadius: 18,
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!isFailed)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: progressValue,
                        backgroundColor: Colors.white.withAlpha(30),
                        color: isCompleted ? Colors.greenAccent : KodairTheme.primaryBlue,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isFailed
                            ? (downloads.errorMessage ?? 'Unknown error')
                            : isCompleted
                                ? 'Saved locally'
                                : downloads.hasProgress
                                    ? _formatProgress(downloads.downloadedBytes, downloads.totalBytes!)
                                    : 'Preparing download',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      if (progressValue != null)
                        Text(
                          '${(progressValue * 100).clamp(0, 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatProgress(int downloadedBytes, int totalBytes) {
    return '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}';
  }

  static String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(value >= 10 || unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }
}
