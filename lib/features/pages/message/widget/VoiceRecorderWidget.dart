import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(File audioFile) onSend;
  final VoidCallback onCancel;

  const VoiceRecorderWidget({
    super.key,
    required this.onSend,
    required this.onCancel,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String _recordDuration = "00:00";
  Timer? _timer;
  int _recordSeconds = 0;
  String? _audioPath;

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String filePath =
            '${appDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _audioPath = filePath;
        });

        _startTimer();
      } else {
        widget.onCancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần quyền ghi âm để sử dụng tính năng này')),
          );
        }
      }
    } catch (e) {
      widget.onCancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi ghi âm: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordSeconds++;
        _recordDuration = _formatDuration(_recordSeconds);
      });
    });
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _stopAndSend() async {
    try {
      final path = await _recorder.stop();
      _timer?.cancel();

      if (path != null) {
        final audioFile = File(path);
        widget.onSend(audioFile);
      } else {
        widget.onCancel();
      }
    } catch (e) {
      widget.onCancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu audio: $e')),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _recorder.stop();
      _timer?.cancel();

      // Xóa file audio nếu có
      if (_audioPath != null) {
        final file = File(_audioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      widget.onCancel();
    } catch (e) {
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel Button
          IconButton(
            icon: Icon(Icons.close, color: Colors.red, size: 28.sp),
            onPressed: _cancelRecording,
          ),

          SizedBox(width: 8.w),

          // Recording Indicator & Wave Animation
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEEEEEE), Color(0xFFF5F5F5)],
                ),
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Row(
                children: [
                  // Pulsing Mic Icon
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(width: 12.w),

                  // Recording Time
                  Text(
                    _recordDuration,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Wave Animation
                  Expanded(child: _buildWaveAnimation()),
                ],
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // Send Button
          GestureDetector(
            onTap: _stopAndSend,
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9D50FF), Color(0xFF5856EC)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF9D50FF).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Wave Animation Widget
  Widget _buildWaveAnimation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(20, (index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // Tạo độ cao khác nhau cho mỗi thanh
            final double height = 3.h +
                (20.h *
                    (0.5 +
                        0.5 *
                            (index % 2 == 0
                                ? _animationController.value
                                : 1 - _animationController.value)));

            return Container(
              width: 2.w,
              height: height,
              decoration: BoxDecoration(
                color: Color(0xFF9D50FF).withOpacity(0.6),
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          },
        );
      }),
    );
  }
}