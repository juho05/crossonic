import 'dart:math';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:flutter/material.dart';

class SongPlayingIndicator extends StatelessWidget {
  final PlaybackStatus playbackStatus;
  final void Function()? onPlay;
  final void Function()? onPause;
  final Color? color;

  const SongPlayingIndicator({
    super.key,
    required this.playbackStatus,
    this.onPlay,
    this.onPause,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return IconButton(
      onPressed:
          (playbackStatus == PlaybackStatus.playing && onPause != null) ||
              (playbackStatus == PlaybackStatus.paused && onPlay != null)
          ? () {
              if (playbackStatus == PlaybackStatus.playing) {
                onPause!();
                return;
              }
              onPlay!();
            }
          : null,
      icon: SizedBox(
        height: 24,
        width: 24,
        child: playbackStatus == PlaybackStatus.playing
            ? _AnimatedBars(color: c)
            : Icon(
                playbackStatus == PlaybackStatus.loading
                    ? Icons.hourglass_empty
                    : Icons.play_arrow,
                color: c,
              ),
      ),
    );
  }
}

class _AnimatedBars extends StatefulWidget {
  final Color color;

  const _AnimatedBars({required this.color});
  @override
  State<_AnimatedBars> createState() => _AnimatedBarsState();
}

class _AnimatedBarsState extends State<_AnimatedBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_BarAnimation> _animations = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    )..repeat();

    for (int i = 0; i < 3; i++) {
      _animations.add(
        _BarAnimation(
          controller: _controller,
          delay: Duration(milliseconds: i * 500),
          period: const Duration(milliseconds: 1250),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 3,
            children: List.generate(
              _animations.length,
              (index) => Container(
                width: 3.5,
                height: _animations[index].height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: widget.color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BarAnimation {
  final AnimationController controller;
  final Duration delay;
  final Duration period;

  double get height {
    // <b>Create a sine wave animation that moves continuously</b>
    double elapsedTime =
        (controller.value * period.inMilliseconds + delay.inMilliseconds) /
        period.inMilliseconds;
    return 10 + sin(elapsedTime * 2 * pi) * 12 / 2;
  }

  _BarAnimation({
    required this.controller,
    required this.delay,
    required this.period,
  });
}
