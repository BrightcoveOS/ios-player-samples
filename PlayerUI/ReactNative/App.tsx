import React from 'react';
import { SafeAreaView, StyleSheet } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import VideoPlayer from './src/VideoPlayer';

const App = () => {
  return (
    <GestureHandlerRootView style={ styles.container } >
      <SafeAreaView style={ styles.container } >
        <VideoPlayer style={ styles.videoContainer } />
      </SafeAreaView>
    </GestureHandlerRootView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  videoContainer: {
    width: '100%', 
    height: '100%',
  }
});

export default App;
