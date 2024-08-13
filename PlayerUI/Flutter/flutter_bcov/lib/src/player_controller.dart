import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'package:flutter_bcov/src/player_view_widget.dart';
import 'package:flutter_bcov/src/viewmodel.dart';

class BCOVVideoPlayer extends StatelessWidget {
  const BCOVVideoPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<BCOVViewModel>.reactive(
      viewModelBuilder: () => BCOVViewModel(),
      onViewModelReady: (model) => model.loadData(),
      builder: (context, model, child) => PlayerView(
        isPlaying: model.isPlaying,
        totalTime: model.totalTime,
        currentTime: model.currentTime,
        inAdSequence: model.inAdSequence,
        onPlatformViewCreated: (viewId) => model.onPlatformViewCreated(viewId),
        onHandle: (args) => model.onHandle(args),
      ),
    );
  }
}
