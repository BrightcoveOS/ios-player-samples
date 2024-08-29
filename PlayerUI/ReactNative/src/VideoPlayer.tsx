import React, { useRef, useState } from 'react';
import { findNodeHandle, NativeModules, View } from 'react-native';
import BCOVVideoPlayer from './BCOVVideoPlayer';
import { Controls as BCOVControls, thumbnailCallback } from './Controls';
import FastImage from 'react-native-fast-image';

type Props = {
  style?: object;
};

const VideoPlayer: React.FC<Props> = (props) => {
  
  const playerRef = useRef(null);

  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [inAdSequence, setInAdSequence] = useState(false);

  const onPressPlayPause = () => {
    const player = NativeModules.BCOVVideoPlayer;
    player.playPause(findNodeHandle(playerRef.current), isPlaying);
    setIsPlaying(value => !value);
  };

  const onReady = (event: any) => {
    const { duration, isAutoPlay, thumbnails } = event.nativeEvent;
    if (duration) {
      setDuration(duration / 1000);
    }

    if (isAutoPlay) {
      setIsPlaying(isAutoPlay);
    }

    if (thumbnails) {
      FastImage.preload(thumbnails);
    }
  };

  const onProgress = (event: any) => {
    const { progress } = event.nativeEvent;
    if (progress) {
      setCurrentTime(progress);
    }
  };

  const onEvent = (event: any) => {
    const { inAdSequence } = event.nativeEvent;
    setInAdSequence(!!inAdSequence);
  };

  const thumbnailAtTime = (value: number, thumbnail: thumbnailCallback) => {
    const player = NativeModules.BCOVVideoPlayer;
    player.thumbnailAtTime(findNodeHandle(playerRef.current), value, thumbnail);
  };

  const onSlidingComplete = (value: number) => {
    const player = NativeModules.BCOVVideoPlayer;
    player.onSlidingComplete(findNodeHandle(playerRef.current), value);
  };

  const nativeProps = {
    ...props,
    onReady,
    onProgress,
    onEvent,
    thumbnailAtTime,
    onSlidingComplete,
  };

  return (
    <View>
      <BCOVVideoPlayer
        ref={playerRef}
        {...nativeProps}
      />
      { !inAdSequence &&
          <BCOVControls isPlaying={isPlaying}
                        duration={duration}
                        progress={currentTime}
                        onPress={onPressPlayPause}
                        thumbnailAtTime={thumbnailAtTime}
                        onSlidingComplete={onSlidingComplete}/> }
    </View>
  );
};

export default VideoPlayer;
