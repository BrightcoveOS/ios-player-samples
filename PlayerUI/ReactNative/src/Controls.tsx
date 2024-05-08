import React, { useEffect, useState } from 'react';
import { Animated, StyleSheet, Text, TouchableOpacity, TouchableWithoutFeedback, View } from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import Slider from '@react-native-community/slider';

type PlayPauseProps = {
    isPlaying: boolean;
    onPress: () => void;
};

const PlayPauseButton: React.FC<PlayPauseProps> = (props) => {

    const { isPlaying, onPress } = props;

    return (
        <Icon name={isPlaying ? 'pause' : 'play-arrow'} size={42} onPress={onPress} />
    )
};

type ControlsProps = {
    isPlaying: boolean;
    duration: number;
    progress: number;
    onPress: () => void;
}

const Controls: React.FC<ControlsProps> = (props) => {

    const { isPlaying, duration, progress, onPress } = props;

    const [opacity] = useState(new Animated.Value(1));
    const [isVisible, setIsVisible] = useState(true);
    const [icon, setIcon] = useState();

    useEffect(() => {
        Icon.getImageSource('circle', 12, 'white').then(setIcon);
        fadeOutControls();
    }, []);

    const fadeInControls = () => {
        setIsVisible(true);
        Animated.timing(opacity, {
            toValue: 1,
            duration: 300,
            useNativeDriver: false,
        }).start(() => {
            fadeOutControls();
        });
    };

    const fadeOutControls = () => {
        Animated.timing(opacity, {
            toValue: 0,
            duration: 300,
            delay: 3000,
            useNativeDriver: false,
        }).start(() => {
            setIsVisible(false);
        });
    };

    const toggleControls = () => {
        opacity.stopAnimation((value) => {
            setIsVisible(!!value);
            return value ? fadeOutControls() : fadeInControls();
        });
    };

    const timeString = (time: number) => {
        const hours = time >= 3600 ? `${String(Math.floor(time / 3600)).padStart(2, '0')}:` : '';
        time %= 3600;
        const minutes = String(Math.floor(time / 60)).padStart(2, '0');
        const seconds = String(Math.floor(time % 60)).padStart(2, '0');

        return `${hours}${minutes}:${seconds}`;
    };

    return (
        <TouchableWithoutFeedback onPress={toggleControls}>
            <Animated.View style={[styles.container, { opacity }]}>
                {isVisible &&
                    (<View style={[styles.mediaControlsContainer, styles.progressContainer]}>
                        <TouchableOpacity>
                            <PlayPauseButton isPlaying={isPlaying} onPress={onPress} />
                        </TouchableOpacity>
                        <View style={styles.progressColumnContainer}>
                            <View style={styles.timerLabelsContainer}>
                                <Text style={styles.timerLabel}>
                                    {timeString(progress)}
                                </Text>
                                <Slider
                                    style={styles.slider}
                                    disabled={true}
                                    value={progress}
                                    maximumValue={duration}
                                    thumbImage={icon}
                                    thumbTintColor={'rgba(218, 223, 225, 1)'}
                                    maximumTrackTintColor={'rgba(0, 0, 0, 0.5)'}
                                    minimumTrackTintColor={'rgba(0, 0, 0, 0.95)'}
                                />
                                <Text style={styles.timerLabel}>
                                    {timeString(duration-progress)}
                                </Text>
                            </View>
                        </View>
                    </View>)
                }
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
        justifyContent: 'flex-end',
    },
    progressColumnContainer: {
        flex: 1,
        alignItems: 'flex-end',
        alignSelf: 'flex-end',
    },
    timerLabelsContainer: {
        alignSelf: 'stretch',
        alignItems: 'center',
        flexDirection: 'row',
        justifyContent: 'space-between',
    },
    timerLabel: {
        fontWeight: '300',
        fontSize: 18,
        marginStart: 13,
        marginEnd: 13,
        fontVariant: ['tabular-nums'],
    },
    slider: {
        flex: 1,
        marginStart: 13,
        marginEnd: 13,
    },
});

export default Controls;
