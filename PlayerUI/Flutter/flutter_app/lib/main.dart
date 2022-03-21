import 'package:flutter/material.dart';
import 'package:flutter_bcov/flutter_bcov.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      darkTheme: ThemeData.dark(),
      home: const MyHomePage(title: 'Brightcove Player SDK for iOS'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: BCOVVideoPlayer(
              playbackController: PlaybackController(
                autoPlay: false,
                autoAdvance: true,
              ),
              playbackService: PlaybackService(
                accountId: '5434391461001',
                policyKey:
                    'BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L',
                videoId: '6140448705001',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
