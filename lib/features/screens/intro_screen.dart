// import 'package:flutter/material.dart';
// import 'package:just_3/features/screens/home_screen.dart';
// import 'package:just_3/features/screens/settings_screen.dart';

// import 'history_screen.dart';

// class IntroScreen extends StatefulWidget {
//   final Function(ThemeMode) onThemeChanged;
//   final int initialIndex;
//   const IntroScreen({
//     super.key,
//     required this.onThemeChanged,
//     this.initialIndex = 0,
//   });

//   @override
//   State<IntroScreen> createState() => _IntroScreenState();
// }

// class _IntroScreenState extends State<IntroScreen> {
//   late int _selectedIndex;

//   // late final List<Widget> _widgetOptions;

//   @override
//   void initState() {
//     super.initState();
//     _selectedIndex = widget.initialIndex;
//     // _widgetOptions = [
//     //   HomeScreen(),
//     //   HistoryScreen(),
//     //   SettingsScreen(onThemeChanged: widget.onThemeChanged),
//     // ];
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });

//     // Update browser URL when tab changes
//     String route = '/';
//     switch (index) {
//       case 0:
//         route = '/home';
//         break;
//       case 1:
//         route = '/history';
//         break;
//       case 2:
//         route = '/settings';
//         break;
//     }

//     // Push the route to update browser history
//     Navigator.pushNamed(context, route);
//   }

//   @override
//   Widget build(BuildContext context) {
//     Widget currentScreen;
//     switch (_selectedIndex) {
//       case 0:
//         currentScreen = HomeScreen();
//         break;
//       case 1:
//         currentScreen = HistoryScreen();
//         break;
//       case 2:
//         currentScreen = SettingsScreen(onThemeChanged: widget.onThemeChanged);
//         break;
//       default:
//         currentScreen = HomeScreen();
//     }
//     return WillPopScope(
//       onWillPop: () async {
//         // Handle back button
//         if (_selectedIndex != 0) {
//           setState(() {
//             _selectedIndex = 0;
//           });
//           return false; // Don't exit app
//         }
//         return true; // Exit app if already on home
//       },
//       child: Scaffold(
//         body: IndexedStack(
//           index: _selectedIndex,
//           children: [
//             HomeScreen(key: ValueKey('home')), // Add unique keys
//             HistoryScreen(key: ValueKey('history')),
//             SettingsScreen(
//               key: ValueKey('settings'),
//               onThemeChanged: widget.onThemeChanged,
//             ),
//           ],
//         ),
//         bottomNavigationBar: BottomNavigationBar(
//           items: const <BottomNavigationBarItem>[
//             BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.history),
//               label: 'History',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.settings),
//               label: 'Settings',
//             ),
//           ],
//           currentIndex: _selectedIndex,
//           selectedItemColor: Colors.blueAccent,
//           onTap: _onItemTapped,
//         ),
//       ),
//     );
//   }
// }
