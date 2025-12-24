import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:just_3/firebase_options.dart';

import 'features/screens/home_screen.dart';
import 'features/screens/intro_screen.dart';
import 'features/screens/settings_screen.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

const bool isWasm = !bool.fromEnvironment('dart.library.js_util');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    // Web-specific initialization
    await Hive.initFlutter();
  } else {
    // Mobile/Desktop initialization
    await Hive.initFlutter();
  }

  if (isWasm) {
    print('Running on Flutter Web (WASM)');
  } else {
    print('Running on Flutter Web (JavaScript)');
  }

  await Hive.openBox('My_Box');
  await Hive.openBox('settingsBox');

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late Box _settingsBox;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settingsBox');
    _loadThemeMode();
  }

  void _loadThemeMode() {
    String? savedTheme = _settingsBox.get('themeMode', defaultValue: 'dark');
    setState(() {
      _themeMode = _getThemeModeFromString(savedTheme);
    });
  }

  ThemeMode _getThemeModeFromString(String? theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void updateTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });

    String themeString = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';
    _settingsBox.put('themeMode', themeString);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      // Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        cardColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
        ),
        cardColor: Colors.grey[850],
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),
      // initialRoute: '/home',
      // routes: {
      //   '/': (context) => IntroScreen(onThemeChanged: updateTheme),
      //   '/home': (context) =>
      //       IntroScreen(onThemeChanged: updateTheme, initialIndex: 0),
      //   '/history': (context) =>
      //       IntroScreen(onThemeChanged: updateTheme, initialIndex: 1),
      //   '/settings': (context) =>
      //       IntroScreen(onThemeChanged: updateTheme, initialIndex: 2),
      // },
      home: HomeScreen(onThemeChanged: updateTheme),
    );
  }
}
