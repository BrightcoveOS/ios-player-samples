import React, {useEffect, useState} from 'react';
import {StyleSheet, Text, TouchableWithoutFeedback, View} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import Slider from '@react-native-community/slider';
import FastImage from 'react-native-fast-image';
import Animated, {
  useSharedValue,
  withTiming,
  Easing,
  useAnimatedStyle,
  withDelay,
  cancelAnimation,
  runOnJS,
  AnimatableValue,
} from 'react-native-reanimated';

export interface thumbnailCallback {
  (thumbnail: string): void;
}

type PlayPauseProps = {
  isPlaying: boolean;
  onPress?: () => void;
};

type ControlsProps = {
  isPlaying: boolean;
  duration: number;
  progress: number;
  onPress?: () => void;
  thumbnailAtTime?: (value: number, thumbnail: thumbnailCallback) => void;
  onSlidingComplete?: (value: number) => void;
};

const PlayPauseButton: React.FC<PlayPauseProps> = props => {
  const {isPlaying, onPress} = props;

  return (
    <Icon
      name={isPlaying ? 'pause' : 'play-arrow'}
      size={45}
      onPress={onPress}
    />
  );
};

export const Controls: React.FC<ControlsProps> = props => {
  const {
    isPlaying,
    duration,
    progress,
    onPress,
    thumbnailAtTime,
    onSlidingComplete,
  } = props;

  const opacity = useSharedValue<number>(1);
  const [thumbnailURL, setThumbnailURL] = useState('');
  const [isScrubbing, setIsScrubbing] = useState(false);
  const [position, setPosition] = useState(0);
  const [icon, setIcon] = useState();

  useEffect(() => {
    Icon.getImageSource('circle', 15, 'white').then(setIcon);
    fadeOutControls(3000);
  }, []);

  const fadeInControls = () => {
    opacity.value = withTiming(
      1,
      {
        duration: 300,
        easing: Easing.linear,
      },
      (finished?: boolean, current?: AnimatableValue) => {
        if (finished) {
          runOnJS(fadeOutControls)(3000);
        }
      },
    );
  };

  const fadeOutControls = (delay: number) => {
    opacity.value = withDelay(
      delay,
      withTiming(0, {
        duration: 300,
        easing: Easing.linear,
      }),
    );
  };

  const animatedStyle = useAnimatedStyle(() => {
    return {
      opacity: opacity.value,
    };
  });

  const toggleControls = () => {
    cancelAnimation(opacity);

    if (opacity.value) {
      fadeOutControls(0);
    } else {
      fadeInControls();
    }
  };

  const timeString = (time: number) => {
    const hours =
      time >= 3600
        ? `${String(Math.floor(time / 3600)).padStart(2, '0')}:`
        : '';
    time %= 3600;
    const minutes = String(Math.floor(time / 60)).padStart(2, '0');
    const seconds = String(Math.floor(time % 60)).padStart(2, '0');

    return `${hours}${minutes}:${seconds}`;
  };

  return (
    <TouchableWithoutFeedback onPress={toggleControls}>
      <Animated.View style={[styles.container, animatedStyle]}>
        {opacity && (
          <View
            style={[styles.mediaControlsContainer, styles.progressContainer]}>
            <PlayPauseButton isPlaying={isPlaying} onPress={onPress} />
            <View style={styles.progressColumnContainer}>
              <View style={styles.timerLabelContainer}>
                <Text style={styles.timerLabel}>{timeString(progress)}</Text>
                <Slider
                  style={styles.slider}
                  value={progress}
                  minimumValue={0}
                  maximumValue={duration}
                  thumbImage={icon}
                  minimumTrackTintColor={'rgba(0, 0, 0, 0.95)'}
                  maximumTrackTintColor={'rgba(0, 0, 0, 0.5)'}
                  onValueChange={(value: number) => {
                    thumbnailAtTime?.(value, (url: string) => {
                      setPosition(Math.round((value * 100) / duration));
                      setThumbnailURL(url);
                    });
                  }}
                  onSlidingStart={() => {
                    cancelAnimation(opacity);
                    setIsScrubbing(true);
                  }}
                  onSlidingComplete={(value: number) => {
                    setIsScrubbing(false);
                    onSlidingComplete?.(value);
                    fadeOutControls(3000);
                  }}>
                  {isScrubbing && (
                    <View
                      style={[
                        styles.thumbnailContainer,
                        {left: `${position}%`},
                      ]}>
                      <FastImage
                        style={styles.thumbnailImage}
                        resizeMode={FastImage.resizeMode.stretch}
                        source={{
                          uri: thumbnailURL,
                          priority: FastImage.priority.high,
                          cache: FastImage.cacheControl.cacheOnly,
                        }}
                      />
                    </View>
                  )}
                </Slider>
                <Text style={styles.timerLabel}>{timeString(duration)}</Text>
              </View>
            </View>
          </View>
        )}
      </Animated.View>
    </TouchableWithoutFeedback>
  );
};

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 0,
    top: 0,
    left: 0,
    right: 0,
  },
  mediaControlsContainer: {
    backgroundColor: 'rgba(179, 157, 219, 0.85)',
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: 10,
  },
  controlsRow: {
    flex: 1,
    alignItems: 'center',
    alignSelf: 'stretch',
    justifyContent: 'center',
  },
  progressContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
  },
  progressColumnContainer: {
    flex: 1,
    alignSelf: 'center',
  },
  timerLabelContainer: {
    alignSelf: 'center',
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'center',
  },
  timerLabel: {
    fontWeight: '300',
    fontSize: 20,
    marginStart: 15,
    marginEnd: 15,
    fontVariant: ['tabular-nums'],
  },
  slider: {
    flex: 1,
  },
  thumbnailContainer: {
    position: 'absolute',
    backgroundColor: 'gray',
    borderColor: 'rgba(179, 157, 219, 0.85)',
    borderWidth: 0.5,
    aspectRatio: 16 / 9,
    width: 100,
    bottom: 40,
    transform: [{translateX: -50}],
  },
  thumbnailImage: {
    flex: 1,
  },
});
