import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Controls extends StatefulWidget {
  const Controls(
      {super.key,
      required this.isPlaying,
      required this.totalTime,
      required this.currentTime,
      required this.onUserInteractControls,
      required this.onHandle});

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

  final ValueChanged<MethodCall> onHandle;

  @override
  State<Controls> createState() => _ControlsState();
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
      color: Theme.of(context).colorScheme.background.withOpacity(0.75),
      height: 60,
      child: Row(
        children: [
          _buildPlayPauseButton(),
          _buildCurrentTimeLabel(),
          _buildSeekBar(),
          _buildTotalTimeLabel(),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  IconButton _buildPlayPauseButton() {
    return IconButton(
      icon: (widget.isPlaying)
          ? const Icon(Icons.pause)
          : const Icon(Icons.play_arrow),
      color: Theme.of(context).textTheme.titleMedium?.color,
      onPressed: () {
        widget.onUserInteractControls();
        widget.onHandle(MethodCall('playPause', [!widget.isPlaying]));
      },
    );
  }

  Text _buildCurrentTimeLabel() {
    return Text(
      _getTimeString(_sliderValue),
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.apply(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }

  Expanded _buildSeekBar() {
    return Expanded(
        child: Material(
            color: Theme.of(context).colorScheme.background.withOpacity(0.0),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.red[700],
                  inactiveTrackColor: Colors.red[100],
                  trackShape: const RectangularSliderTrackShape(),
                  trackHeight: 2.0,
                  thumbColor: Colors.redAccent,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                  overlayColor: Colors.red.withAlpha(32),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 10.0),
                  allowedInteraction: SliderInteraction.slideThumb),
              child: Slider(
                  value: _sliderValue,
                  onChanged: (_) => (),
                  onChangeEnd: (newValue) => widget.onHandle(
                      MethodCall('seek', [_getDuration(newValue).inSeconds]))),
            )));
  }

  Text _buildTotalTimeLabel() {
    return Text(
      _getTimeString(1.0 - _sliderValue),
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.apply(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }

  double _getSliderValue() => (widget.currentTime.inSeconds > 0
      ? (widget.currentTime.inSeconds / widget.totalTime.inSeconds)
      : 0.0);

  Duration _getDuration(double sliderValue) {
    final seconds = widget.totalTime.inSeconds * sliderValue;
    return Duration(seconds: seconds.truncate());
  }

  String _getTimeString(double sliderValue) {
    final time = _getDuration(sliderValue);

    String twoDigits(int n) {
      if (n >= 10) return '$n';
      return '0$n';
    }

    final minutes =
        twoDigits(time.inMinutes.remainder(Duration.minutesPerHour));
    final seconds =
        twoDigits(time.inSeconds.remainder(Duration.secondsPerMinute));
    final hours = widget.totalTime.inHours > 0 ? '${time.inHours}:' : '';

    return '$hours$minutes:$seconds';
  }
}
