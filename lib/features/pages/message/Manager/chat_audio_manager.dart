// managers/chat_audio_manager.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class ChatAudioManager {
  final Map<String, AudioPlayer> _audioPlayers = {};
  final Map<String, bool> _isPlayingAudio = {};
  final Map<String, Duration> _audioDurations = {};
  final Map<String, Duration> _audioPositions = {};
  final Map<String, StreamSubscription> _audioSubscriptions = {};

  bool isPlaying(String messageId) => _isPlayingAudio[messageId] ?? false;
  Duration? getDuration(String messageId) => _audioDurations[messageId];
  Duration getPosition(String messageId) => _audioPositions[messageId] ?? Duration.zero;

  Future<void> togglePlayback(
      String messageId,
      String audioUrl,
      Function onStateChanged,
      ) async {
    try {
      AudioPlayer? player = _audioPlayers[messageId];

      if (player == null) {
        print('🎵 Tạo player mới cho $messageId');
        player = AudioPlayer();
        _audioPlayers[messageId] = player;
        _isPlayingAudio[messageId] = false;

        _setupListeners(player, messageId, onStateChanged);

        try {
          if (audioUrl.startsWith('http')) {
            await player.setSourceUrl(audioUrl);
          } else {
            await player.setSourceDeviceFile(audioUrl);
          }
        } catch (e) {
          print('❌ Lỗi set audio source: $e');
          throw Exception('Không thể load file audio: $e');
        }
      }

      final isPlaying = _isPlayingAudio[messageId] ?? false;
      final playerState = player.state;

      if (isPlaying) {
        print('⏸️ Pausing audio: $messageId');
        await player.pause();
        _isPlayingAudio[messageId] = false;
        onStateChanged();
      } else {
        _pauseOtherPlayers(messageId, onStateChanged);

        if (playerState == PlayerState.completed) {
          print('🔄 Player completed, resetting...');
          if (audioUrl.startsWith('http')) {
            await player.setSourceUrl(audioUrl);
          } else {
            await player.setSourceDeviceFile(audioUrl);
          }
          await player.seek(Duration.zero);
        }

        print('▶️ Playing audio: $messageId');
        await player.resume();
        _isPlayingAudio[messageId] = true;
        onStateChanged();
      }
    } catch (e) {
      print('❌ Lỗi phát audio: $e');
      _disposePlayer(messageId);
      rethrow;
    }
  }

  void _setupListeners(
      AudioPlayer player,
      String messageId,
      Function onStateChanged,
      ) {
    _audioSubscriptions['${messageId}_complete'] =
        player.onPlayerComplete.listen((_) async {
          print('✅ Audio completed: $messageId');
          _isPlayingAudio[messageId] = false;
          _audioPositions[messageId] = Duration.zero;
          onStateChanged();
        });

    _audioSubscriptions['${messageId}_duration'] =
        player.onDurationChanged.listen((duration) {
          _audioDurations[messageId] = duration;
          onStateChanged();
        });

    _audioSubscriptions['${messageId}_position'] =
        player.onPositionChanged.listen((position) {
          _audioPositions[messageId] = position;
          onStateChanged();
        });
  }

  void _pauseOtherPlayers(String currentMessageId, Function onStateChanged) {
    for (var entry in _audioPlayers.entries) {
      if (entry.key != currentMessageId && (_isPlayingAudio[entry.key] ?? false)) {
        entry.value.pause();
        _isPlayingAudio[entry.key] = false;
      }
    }
    onStateChanged();
  }

  void _disposePlayer(String messageId) {
    print('🗑️ Disposing audio player: $messageId');
    _audioSubscriptions['${messageId}_duration']?.cancel();
    _audioSubscriptions['${messageId}_position']?.cancel();
    _audioSubscriptions['${messageId}_complete']?.cancel();
    _audioSubscriptions.remove('${messageId}_duration');
    _audioSubscriptions.remove('${messageId}_position');
    _audioSubscriptions.remove('${messageId}_complete');

    _audioPlayers[messageId]?.dispose();
    _audioPlayers.remove(messageId);
    _isPlayingAudio.remove(messageId);
    _audioDurations.remove(messageId);
    _audioPositions.remove(messageId);
  }

  void disposeAll() {
    print('🗑️ Disposing all audio players');
    for (var messageId in _audioPlayers.keys.toList()) {
      _disposePlayer(messageId);
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}