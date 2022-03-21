import React from 'react';
import { SafeAreaView, StyleSheet, View } from 'react-native';
import Header from './src/Header';
import VideoPlayer from './src/VideoPlayer';

const App = () => {
  return (
    <SafeAreaView style={styles.appContainer}>
      <Header title='Brightcove Player SDK for iOS' subtitle='React Native' />
      <View style={styles.container}>
        <VideoPlayer
          style={styles.videoContainer}
          options={{
            playbackService: {
              accountId: '5434391461001',
              policyKey: 'BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L',
              videoId: '6140448705001',
            },
            playbackController: {
              autoAdvance: false,
              autoPlay: false,
            }
          }} />
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  appContainer: {
    flex: 1,
  },
  container: {
    flex: 1,
    justifyContent: 'center',
  },
  videoContainer: {
    aspectRatio: 16 / 9,
  },
});

export default App;
