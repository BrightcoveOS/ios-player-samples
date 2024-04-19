import React, { useRef, useState } from 'react';
import { findNodeHandle, NativeModules, View } from 'react-native';
import BCOVVideoPlayer from './BCOVVideoPlayer';
import BCOVControls from './Controls';

type Props = {
  style?: object;
};

const VideoPlayer: React.FC<Props> = (props) => {
  
  const playerRef = useRef(null);

  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);

  const onPressPlayPause = () => {
    const player = NativeModules.BCOVVideoPlayer;
    player.playPause(findNodeHandle(playerRef.current), isPlaying);
    setIsPlaying(value => !value);
  };

  const onReady = (event: any) => {
    const { duration, isAutoPlay } = event.nativeEvent;
    if (duration) {
      setDuration(duration / 1000);
    }

    if (isAutoPlay) {
      setIsPlaying(isAutoPlay);
    }
  };

  const onProgress = (event: any) => {
    const { progress } = event.nativeEvent;
    if (progress) {
      setCurrentTime(progress);
    }
  };

  const nativeProps = {
    ...props,
    onReady,
    onProgress,
  };

  return (
    <View>
      <BCOVVideoPlayer
        ref={playerRef}
        {...nativeProps}
      />
      <BCOVControls
        isPlaying={isPlaying}
        duration={duration}
        progress={currentTime}
        onPress={onPressPlayPause} />
    </View>
  );
};

export default VideoPlayer;