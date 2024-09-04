import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef OnUserInteractControls = void Function({bool isScrubbing});

class BCOVControls extends StatefulWidget {
  const BCOVControls(
      {super.key,
      required this.isPlaying,
      this.thumbnailURL,
      required this.totalTime,
      required this.currentTime,
      required this.onUserInteractControls,
      required this.onHandle});

  /// When [isPlaying] is `true`, the play button displays a pause icon. When
  /// it is `false`, the button shows a play icon.
  final bool isPlaying;

  /// The thumbnail URL when the `thumbnailSeekingEnabled` is true in the
  /// playback controller.
  final String? thumbnailURL;

  /// This is the total time length of the video that is being played.
  final Duration totalTime;

  /// The [currentTime] is displayed between the play/pause button and the seek
  /// bar. This value also affects the current position of the seek bar in
  /// relation to the total time.
  final Duration currentTime;

  final OnUserInteractControls onUserInteractControls;

  final ValueChanged<MethodCall> onHandle;

  @override
  State<BCOVControls> createState() => _BCOVControlsState();
}

class _BCOVControlsState extends State<BCOVControls> {
  late double _sliderValue;
  late bool _isScrubbing;

  @override
  void initState() {
    super.initState();
    _sliderValue = _getSliderValue();
    _isScrubbing = false;
  }

  @override
  Container build(BuildContext context) {
    if (!_isScrubbing) {
      _sliderValue = _getSliderValue();
    }

    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.75),
      height: 60,
      child: Row(
        children: [
          _buildPlayPauseButton(),
          _buildCurrentTimeLabel(),
          const SizedBox(width: 16),
          _buildSeekBar(),
          const SizedBox(width: 16),
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
      color: Theme.of(context).textTheme.titleLarge?.color,
      onPressed: () {
        widget.onUserInteractControls(isScrubbing: _isScrubbing);
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

  Future<ui.Image?> _getThumbnailAtTime() async {
    if (_isScrubbing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onHandle(MethodCall(
            'thumbnailAtTime', [_getDuration(_sliderValue).inSeconds]));
      });

      final Completer<ImageInfo> completer = Completer<ImageInfo>();
      final NetworkImage img = NetworkImage(widget.thumbnailURL as String);
      img.resolve(ImageConfiguration.empty).addListener(
        ImageStreamListener((info, _) {
          completer.complete(info);
        }),
      );

      ImageInfo imageInfo = await completer.future;
      return imageInfo.image;
    }

    return Future.value();
  }

  Expanded _buildSeekBar() {
    return Expanded(
        child: FutureBuilder(
            future: _getThumbnailAtTime(),
            builder: (BuildContext context, AsyncSnapshot<ui.Image?> snapshot) {
              return Material(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.0),
                  child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.red[700],
                          inactiveTrackColor: Colors.red[100],
                          trackShape: const RectangularSliderTrackShape(),
                          trackHeight: 2.0,
                          thumbColor: Colors.redAccent,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5.0),
                          overlayColor: Colors.red.withAlpha(32),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 10.0),
                          valueIndicatorShape:
                              _ThumbnailShape(snapshot: snapshot),
                          showValueIndicator: ShowValueIndicator.always,
                          allowedInteraction: SliderInteraction.slideThumb),
                      child: Slider(
                          value: _sliderValue,
                          label: '$_sliderValue',
                          onChangeStart: (_) {
                            setState(() => _isScrubbing = true);
                            widget.onUserInteractControls(isScrubbing: true);
                          },
                          onChanged: (double newValue) =>
                              setState(() => _sliderValue = newValue),
                          onChangeEnd: (double newValue) {
                            setState(() {
                              _sliderValue = newValue;
                              widget.onHandle(MethodCall(
                                  'seek', [_getDuration(newValue).inSeconds]));
                              _isScrubbing = false;
                              widget.onUserInteractControls(isScrubbing: false);
                            });
                          })));
            }));
  }

  Text _buildTotalTimeLabel() {
    return Text(
      _getTimeString(1.0),
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

class _ThumbnailShape extends SliderComponentShape {
  const _ThumbnailShape({required this.snapshot});

  final AsyncSnapshot<ui.Image?> snapshot;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    if (snapshot.hasData) {
      final Canvas canvas = context.canvas;

      final ui.Image image = snapshot.data as ui.Image;

      const double width = 100.0;
      const double height = (9 / 16) * width;
      const double offset = 70.0;

      final borderPaint = Paint()
        ..color = sliderTheme.thumbColor!
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final fillPaint = Paint()
        ..color = Colors.grey
        ..style = PaintingStyle.fill;

      final Rect rect = Rect.fromLTWH(
          center.dx - (width / 2), center.dy - offset, width, height);

      canvas.drawRect(rect, borderPaint);
      canvas.drawRect(rect, fillPaint);

      paintImage(
          canvas: canvas,
          rect: rect,
          image: image,
          fit: BoxFit.scaleDown,
          repeat: ImageRepeat.noRepeat,
          scale: 1.0,
          alignment: Alignment.center,
          flipHorizontally: false,
          filterQuality: FilterQuality.high);
    }
  }
}
