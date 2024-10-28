import 'package:flutter/material.dart';
import 'package:safe_circle/chat_comunity.dart';
import 'package:safe_circle/child/bottom_screens/chat_page.dart';
import 'package:safe_circle/child/bottom_screens/contact_page.dart';
import 'package:safe_circle/child/bottom_screens/first_contact.dart';
import 'package:safe_circle/child/bottom_screens/profile_page.dart';
import 'package:safe_circle/home_screen.dart';

class BottomPage extends StatefulWidget {
  const BottomPage({super.key});

  @override
  State<BottomPage> createState() => _BottomPageState();
}

class _BottomPageState extends State<BottomPage> {
  @override
  int _currentIndex = 0; // Initialize the current index to 0

  final List<Widget> _pages = [
    HomeScreen(),
    FirstContact(),
    ChildChat(),
    ProfilePage(),
    ChatCommunity(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex =
        0; // Explicitly reset the index when BottomPage is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.pink, // Color for selected icon
        unselectedItemColor: Colors.grey, // Color for unselected icons
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.contact_page), label: "Contact"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(
              icon: Icon(Icons.rate_review), label: "Review"),
        ],
      ),
    );
  }
}
