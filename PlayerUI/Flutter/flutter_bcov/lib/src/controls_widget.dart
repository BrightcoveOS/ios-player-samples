import 'dart:ui';

import 'package:flutter/material.dart';

class Controls extends StatefulWidget {
  const Controls({
    Key? key,
    required this.isPlaying,
    required this.totalTime,
    required this.currentTime,
    required this.onUserInteractControls,
    required this.onPlayStateChanged,
  }) : super(key: key);

  /// When [isPlaying] is `true`, the play button displays a pause icon. When
  /// it is `false`, the button shows a play icon.
  final bool isPlaying;

  /// This is the total time length of the audio track that is being played.
  final Duration totalTime;

  /// The [currentTime] is displayed between the play/pause button and the seek
  /// bar. This value also affects the current position of the seek bar in
  /// relation to the total time.
  final Duration currentTime;

  final Function() onUserInteractControls;

  /// This is called when a user has pressed the play/pause button.
  final ValueChanged<bool> onPlayStateChanged;

  @override
  _ControlsState createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = _getSliderValue();
  }

  @override
  Widget build(BuildContext context) {
     _sliderValue = _getSliderValue();

    return Container(
      color: Theme.of(context).backgroundColor.withOpacity(0.75),
      height: 60,
      child: Row(
        children: [
          _buildPlayPauseButton(context),
          _buildCurrentTimeLabel(),
          _buildSeekBar(context),
          _buildTotalTimeLabel(),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  IconButton _buildPlayPauseButton(BuildContext context) {
    return IconButton(
      icon: (widget.isPlaying)
          ? const Icon(Icons.pause)
          : const Icon(Icons.play_arrow),
      color: Theme.of(context).textTheme.bodyText1!.color,
      onPressed: () {
        widget.onUserInteractControls();
        widget.onPlayStateChanged(!widget.isPlaying);
      },
    );
  }

  Text _buildCurrentTimeLabel() {
    return Text(
      _getTimeString(_sliderValue),
      style: const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  Expanded _buildSeekBar(BuildContext context) {
    return Expanded(
      child: Slider(
        value: _sliderValue,
        activeColor: Theme.of(context).textTheme.bodyText2!.color,
        inactiveColor: Theme.of(context).disabledColor,
        onChanged: null,
      ),
    );
  }

  Text _buildTotalTimeLabel() {
    return Text(
      _getTimeString(1.0 - _sliderValue),
      style: const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  double _getSliderValue() {
    return (widget.totalTime.inSeconds > 0
        ? widget.currentTime.inSeconds / widget.totalTime.inSeconds
        : 0);
  }

  Duration _getDuration(double sliderValue) {
    final seconds = widget.totalTime.inSeconds * sliderValue;
    return Duration(seconds: seconds.toInt());
  }

  String _getTimeString(double sliderValue) {
    final time = _getDuration(sliderValue);

    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    final minutes =
        twoDigits(time.inMinutes.remainder(Duration.minutesPerHour));
    final seconds =
        twoDigits(time.inSeconds.remainder(Duration.secondsPerMinute));
    final hours = widget.totalTime.inHours > 0 ? '${time.inHours}:' : '';

    return "$hours$minutes:$seconds";
  }
}
