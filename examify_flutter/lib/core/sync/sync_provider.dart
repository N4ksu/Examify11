import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import 'package:camera/camera.dart';

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});

class SyncState {
  final bool isOnline;
  final int pendingCount;
  final int pendingSnapshotsCount;
  final bool isSyncing;
  final bool isSessionLocked;

  SyncState({
    this.isOnline = true,
    this.pendingCount = 0,
    this.pendingSnapshotsCount = 0,
    this.isSyncing = false,
    this.isSessionLocked = false,
  });

  SyncState copyWith({
    bool? isOnline,
    int? pendingCount,
    int? pendingSnapshotsCount,
    bool? isSyncing,
    bool? isSessionLocked,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      pendingSnapshotsCount:
          pendingSnapshotsCount ?? this.pendingSnapshotsCount,
      isSyncing: isSyncing ?? this.isSyncing,
      isSessionLocked: isSessionLocked ?? this.isSessionLocked,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  static const String _storageKeyPrefix = 'pending_answers_';
  bool _isForcedOffline = false;
  Timer? _captureTimer;
  CameraController? _cameraController;

  void startCapture(CameraController? cameraController, int attemptId) async {
    _captureTimer?.cancel();
    _cameraController = cameraController;

    _captureTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      await captureSnapshot(attemptId, isViolation: false);
    });
  }

  Future<void> captureSnapshot(
    int attemptId, {
    bool isViolation = false,
    String? customCaption,
  }) async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return;
      }

      final XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      final caption =
          customCaption ?? (isViolation ? "⚠️ TAB SWITCH DETECTED" : null);
      await saveSnapshotLocally(attemptId, base64String, caption: caption);
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  void stopCapture() {
    _captureTimer?.cancel();
    _captureTimer = null;
    _cameraController = null;
  }

  @override
  SyncState build() {
    Future.microtask(_checkPending);
    return SyncState();
  }

  void toggleForcedOffline(bool offline) {
    _isForcedOffline = offline;
    if (offline) {
      state = state.copyWith(isOnline: false);
    } else {
      state = state.copyWith(isOnline: true);
    }
  }

  String _getKey(int attemptId) => '$_storageKeyPrefix$attemptId';

  static const String _snapshotStorageKeyPrefix = 'pending_snapshots_';
  String _getSnapshotKey(int attemptId) =>
      '$_snapshotStorageKeyPrefix$attemptId';

  Future<void> _checkPending() async {
    // Check constraints here
  }

  Future<void> saveSnapshotLocally(
    int attemptId,
    String base64Image, {
    String? caption,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = _getSnapshotKey(attemptId);

    final storedStr = prefs.getString(key);
    List<dynamic> pending = storedStr != null ? jsonDecode(storedStr) : [];

    final timestamp = DateTime.now().toIso8601String();
    pending.add({
      'image': base64Image,
      'captured_at': timestamp,
      'caption': caption,
    });

    await prefs.setString(key, jsonEncode(pending));
    state = state.copyWith(pendingSnapshotsCount: pending.length);

    _syncSnapshots(attemptId);
  }

  Future<void> saveAnswerLocally(
    int attemptId,
    int questionId,
    List<Map<String, dynamic>> answerData,
  ) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = _getKey(attemptId);

    final storedStr = prefs.getString(key);
    List<dynamic> pending = storedStr != null ? jsonDecode(storedStr) : [];

    // Remove existing answer for this question
    pending.removeWhere((p) => p['question_id'] == questionId);

    // Append timestamp
    final timestamp = DateTime.now().toIso8601String();
    for (var ans in answerData) {
      ans['client_timestamp'] = timestamp;
    }

    // Add new
    pending.addAll(answerData);

    await prefs.setString(key, jsonEncode(pending));
    state = state.copyWith(pendingCount: pending.length);

    // Attempt to sync immediately
    _syncAttempt(attemptId);
  }

  Future<void> _syncAttempt(int attemptId) async {
    if (state.isSyncing) return;
    if (_isForcedOffline) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final key = _getKey(attemptId);
    final storedStr = prefs.getString(key);

    if (storedStr == null) return;

    final List<dynamic> pending = jsonDecode(storedStr);
    if (pending.isEmpty) return;

    state = state.copyWith(isSyncing: true);

    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/attempts/$attemptId/save-answer',
        data: {'answers': pending},
      );

      // Clear on success
      await prefs.remove(key);
      state = state.copyWith(isOnline: true, pendingCount: 0, isSyncing: false);
    } catch (e) {
      if (e.toString().contains('403') ||
          e.toString().contains('Session Hijacking')) {
        state = state.copyWith(isSessionLocked: true, isSyncing: false);
      } else {
        // Keep stored on failure
        state = state.copyWith(
          isOnline: false,
          pendingCount: pending.length,
          isSyncing: false,
        );
      }
    }
  }

  static const String _discordWebhookUrl = 'bleee'; // Example placeholder

  Future<void> _syncSnapshots(int attemptId) async {
    if (_isForcedOffline) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final key = _getSnapshotKey(attemptId);
    final storedStr = prefs.getString(key);

    if (storedStr == null) return;

    final List<dynamic> pending = jsonDecode(storedStr);
    if (pending.isEmpty) return;

    final api = ref.read(apiClientProvider);
    final discordDio = Dio(); // Clean Dio for Discord

    List<dynamic> remaining = List.from(pending);
    bool anySuccess = false;

    for (var snap in pending) {
      try {
        // 1. Upload to Discord
        final String base64Image = snap['image'];
        final String capturedAt = snap['captured_at'];

        // Remove metadata prefix if exists
        String pureBase64 = base64Image;
        if (base64Image.startsWith('data:image')) {
          pureBase64 = base64Image.substring(base64Image.indexOf(',') + 1);
        }
        final List<int> imageBytes = base64Decode(pureBase64);

        final String? caption = snap['caption'];
        String content =
            'Proctoring Snapshot - Attempt $attemptId - Captured at $capturedAt';
        if (caption != null) {
          content = '$caption\n$content';
        }

        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            imageBytes,
            filename:
                'snapshot_${attemptId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
          'content': content,
        });

        // Use ?wait=true to ensure Discord returns the JSON representation of the uploaded message
        final discordResponse = await discordDio.post(
          '$_discordWebhookUrl?wait=true',
          data: formData,
        );

        if (discordResponse.statusCode == 200) {
          final attachments = discordResponse.data['attachments'] as List;
          if (attachments.isNotEmpty) {
            final String discordUrl = attachments[0]['url'];

            // 2. Send URL to Laravel
            await api.post(
              '/attempts/$attemptId/proctor-snapshots',
              data: {'image_url': discordUrl, 'captured_at': capturedAt},
            );

            remaining.remove(snap);
            anySuccess = true;
          }
        }
      } catch (e) {
        debugPrint('Snapshot sync error: $e');
        if (e.toString().contains('403') ||
            e.toString().contains('Session Hijacking')) {
          state = state.copyWith(isSessionLocked: true);
        }
        break; // Stop syncing on error to try again later
      }
    }

    if (anySuccess || remaining.length != pending.length) {
      if (remaining.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, jsonEncode(remaining));
      }
      state = state.copyWith(pendingSnapshotsCount: remaining.length);
    }
  }

  void markSessionLocked() {
    state = state.copyWith(isSessionLocked: true);
  }

  void markOnline() {
    if (!state.isOnline) {
      state = state.copyWith(isOnline: true);
      // We could trigger sync for the active attempt here if we knew it
    }
  }

  Future<void> forceSync(int attemptId) async {
    await _syncAttempt(attemptId);
    await _syncSnapshots(attemptId);
  }

  Future<void> clearAttempt(int attemptId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_getKey(attemptId));
    state = state.copyWith(pendingCount: 0);
  }
}
