import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter_bcov/src/player_controller.dart';
import 'package:flutter_bcov/src/viewmodel.dart';

/// The entrypoint for the flutter module.
void main() {
  // This call ensures the Flutter binding has been set up before creating the
  // MethodChannel-based model.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider.value(
      value: BCOVViewModel(),
      child: const MyApp(),
    ),
  );
}

/// The "app" displayed by this module.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
        darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: const SafeArea(child: BCOVVideoPlayer()));
  }
}
