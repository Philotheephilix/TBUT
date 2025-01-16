import 'package:eyetear/pages/history_page.dart';
import 'package:eyetear/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(),  // Set MainPage as the home of the app
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _page = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  final List<Widget> _pages = [
    const HomePage(),      // The main capturing page
    HistoryPage(),   // The history page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text('AGARWAL EYE HOSPTIAL',style: TextStyle(color: Color(0xFFF7EFE5),fontWeight:FontWeight.w300)),
        backgroundColor: const Color(0xFF6B4389), // Purple color matching the design
      ),
      body: _pages[_page], // Display the current page
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: 0,
        height: 75.0,
items: <Widget>[
          Icon(Icons.radio_button_checked_rounded, size: 40, color: _page == 0 ? const Color(0xFF674188): const Color(0xFFF7EFE5)),
          Icon(Icons.history, size: 40, color: _page == 1 ? const Color(0xFF674188) : const Color(0xFFF7EFE5)),
        ],        color: const Color(0xFF674188), 
        buttonBackgroundColor: const Color(0xFFF7EFE5), 
        backgroundColor: const Color(0xFFF7EFE5), 
        animationCurve: Curves.easeInOutSine,
        animationDuration: const Duration(milliseconds: 200),
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
      ),
    );
  }
}
