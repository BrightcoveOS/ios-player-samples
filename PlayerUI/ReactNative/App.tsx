import React from 'react';
import { SafeAreaView, StyleSheet, View } from 'react-native';
import VideoPlayer from './src/VideoPlayer';

const App = () => {
  return (
    <SafeAreaView  style={ styles.appContainer }>
      <VideoPlayer style={ styles.videoContainer } />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  appContainer: {
    flex: 1,
  },
  videoContainer: {
    width: '100%', 
    height: '100%',
  }
});

export default App;
