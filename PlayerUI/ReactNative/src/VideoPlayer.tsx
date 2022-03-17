import React, { useRef, useState } from 'react';
import { findNodeHandle, NativeModules, View } from 'react-native';
import BCOVVideoPlayer from './BCOVVideoPlayer';
import BCOVControls from './Controls';

type Props = {
  options: {
    playbackService: {
      accountId: string;
      videoId: string;
      policyKey?: string;
      authToken?: string;
      parameters?: object;
    },
    playbackController: {
      autoAdvance: boolean;
      autoPlay: boolean;
    },
  };
  style?: object;
};

const VideoPlayer: React.FC<Props> = (props) => {
  
  const playerRef = useRef(null);

  const { autoPlay } = props.options.playbackController;

  const [isPlaying, setIsPlaying] = useState(autoPlay);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);

  const onPressPlayPause = () => {
    const player = NativeModules.BCOVVideoPlayer;
    player.playPause(findNodeHandle(playerRef.current), isPlaying);
    setIsPlaying(value => !value);
  };

  const onReady = (event: any) => {
    const { duration } = event.nativeEvent;
    if (duration) {
      setDuration(duration / 1000);
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
        progress={currentTime}
        duration={duration}
        onPress={onPressPlayPause} />
    </View>
  );
};

export default VideoPlayer;
function ReactNative(ReactNative: any) {
  throw new Error('Function not implemented.');
}

