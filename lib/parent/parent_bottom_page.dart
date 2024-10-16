import 'package:flutter/material.dart';
import 'package:safe_circle/parent/parent_home_screen.dart';
import 'package:safe_circle/parent/parent_profile.dart';
import 'package:safe_circle/parent/parents_chat.dart';
import 'package:safe_circle/parent/parents_contact.dart';
import 'package:safe_circle/parent/parents_review.dart';

class ParentsBottomPage extends StatefulWidget {
  const ParentsBottomPage({super.key});

  @override
  State<ParentsBottomPage> createState() => _BottomPageState();
}

class _BottomPageState extends State<ParentsBottomPage> {
  @override
  int _currentIndex = 0; // Initialize the current index to 0

  final List<Widget> _pages = [
    ParentHomeScreen(),
    ParentsContact(),
    ParentsChat(),
    ParentProfile(),
    ParentsReview(),
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
