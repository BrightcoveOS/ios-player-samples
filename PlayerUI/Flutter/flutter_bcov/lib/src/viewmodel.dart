import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bcov/src/player_controller.dart';

class BCOVViewModel extends ChangeNotifier {
  late EventChannel _eventChannel;
  late MethodChannel _methodChannel;

  bool _isPlaying = false;
  Duration _currentTime = const Duration();
  Duration _totalTime = const Duration();

  bool get isPlaying => _isPlaying;
  Duration get currentTime => _currentTime;
  Duration get totalTime => _totalTime;

  Future<void> loadData() async {
    _currentTime = const Duration(seconds: 0);
    _totalTime = const Duration(seconds: 0);
  }

  Future<void> onPlatformViewCreated(int viewId) async {
    _eventChannel = EventChannel(
        'bcov.flutter/event_channel_$viewId', const JSONMethodCodec());
    _eventChannel.receiveBroadcastStream().listen(_processEvent);

    _methodChannel = MethodChannel('bcov.flutter/method_channel_$viewId');

    notifyListeners();
  }

  Future<void> onSetVideo(PlaybackService playbackService) async {
    await _methodChannel.invokeMethod('setVideo', playbackService.toJson());
  }

  Future<void> onPlayStateChanged(bool isPlaying) async {
    if (isPlaying) {
      _methodChannel.invokeMapMethod('play');
    } else {
      _methodChannel.invokeListMethod('pause');
    }
    _isPlaying = isPlaying;
    notifyListeners();
  }

  void _processEvent(dynamic event) async {
    String? eventName = event['name'];

    switch (eventName) {
      case 'didAdvanceToPlaybackSession':
        int milliseconds = event['duration'].toInt();
        bool isPlaying = event['isPlaying'];
        _totalTime = Duration(milliseconds: milliseconds);
        _isPlaying = isPlaying;
        notifyListeners();
        break;

      case 'didProgressTo':
        int milliseconds = event['progress'].toInt();
        _currentTime = Duration(milliseconds: milliseconds);
        notifyListeners();
        break;

      case 'onError':
        print('error');
        break;
    }
  }
}
