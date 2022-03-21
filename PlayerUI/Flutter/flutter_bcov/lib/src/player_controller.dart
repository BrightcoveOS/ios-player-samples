import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bcov/src/player_view_widget.dart';
import 'package:flutter_bcov/src/viewmodel.dart';
import 'package:stacked/stacked.dart';

class PlaybackController {
  PlaybackController({this.autoAdvance = false, this.autoPlay = false});

  final bool autoAdvance;
  final bool autoPlay;

  Map<String, dynamic> toJson() => {
        'autoAdvance': autoAdvance,
        'autoPlay': autoPlay,
      };
}

class PlaybackService {
  PlaybackService({
    required this.accountId,
    this.policyKey,
    this.authToken,
    this.parameters,
    required this.videoId,
  });

  final String accountId;
  final String? policyKey;
  final String? authToken;
  final Map<String, dynamic>? parameters;
  final String videoId;

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'policyKey': policyKey,
        'authToken': authToken,
        'parameters': parameters,
        'videoId': videoId,
      };
}

class BCOVVideoPlayer extends StatelessWidget {
  const BCOVVideoPlayer(
      {Key? key,
      required this.playbackController,
      required this.playbackService})
      : super(key: key);

  final PlaybackController playbackController;
  final PlaybackService playbackService;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> _creationsParams = {
      'playbackController': playbackController.toJson(),
      'playbackService': playbackService.toJson(),
    };
    return ViewModelBuilder<BCOVViewModel>.reactive(
      viewModelBuilder: () => BCOVViewModel(),
      onModelReady: (model) => model.loadData(),
      builder: (context, model, child) => PlayerView(
        isPlaying: model.isPlaying,
        totalTime: model.totalTime,
        currentTime: model.currentTime,
        creationParams: _creationsParams,
        onPlatformViewCreated: (int viewId) {
          model.onPlatformViewCreated(viewId);
          model.onSetVideo(playbackService);
        },
        onPlayStateChanged: (bool isPlaying) {
          model.onPlayStateChanged(isPlaying);
        },
      ),
    );
  }
}
