import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BCOVViewModel extends ChangeNotifier {
  late EventChannel _eventChannel;
  late MethodChannel _methodChannel;

  bool _isPlaying = false;
  bool _inAdSequence = false;
  Duration _currentTime = const Duration();
  Duration _totalTime = const Duration();

  bool get isPlaying => _isPlaying;
  bool get inAdSequence => _inAdSequence;
  Duration get currentTime => _currentTime;
  Duration get totalTime => _totalTime;

  Future<void> loadData() async {
    _currentTime = const Duration(seconds: 0);
    _totalTime = const Duration(seconds: 0);
  }

  Future<void> onPlatformViewCreated(int viewId) async {
    _eventChannel =
        const EventChannel('bcov.flutter/event_channel', JSONMethodCodec());
    _eventChannel.receiveBroadcastStream().listen(_processEvent);

    _methodChannel = const MethodChannel('bcov.flutter/method_channel');

    notifyListeners();
  }

  Future<void> onHandle(MethodCall call) async {
    switch (call.method) {
      case 'playPause':
        _methodChannel.invokeMethod(call.method, !call.arguments[0]);
        _isPlaying = !_isPlaying;
        break;

      case 'seek':
        _methodChannel.invokeMethod(call.method, call.arguments[0]);
        break;
    }

    notifyListeners();
  }

  void _processEvent(dynamic event) async {
    String? eventName = event['name'];

    switch (eventName) {
      case 'didAdvanceToPlaybackSession':
        int milliseconds = event['duration'].toInt();
        bool isPlaying = event['isAutoPlay'];
        _totalTime = Duration(milliseconds: milliseconds);
        _isPlaying = isPlaying;
        break;

      case 'didProgressTo':
        int seconds = event['progress'].toInt();
        _currentTime = Duration(seconds: seconds);
        break;

      case 'eventEnd':
        _currentTime = const Duration(seconds: 0);
        _isPlaying = false;
        break;

      case 'onError':
        break;

      case 'eventAdSequenceExit':
        _inAdSequence = false;
        break;

      case 'eventAdSequenceEnter':
        _inAdSequence = true;
        break;
    }

    notifyListeners();
  }
}
