import 'package:flutter/material.dart';
import 'package:safe_circle/parent/parents_contact.dart';

class FirstContact extends StatefulWidget {
  const FirstContact({super.key});

  @override
  State<FirstContact> createState() => _FirstContactState();
}

class _FirstContactState extends State<FirstContact> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              'User Contact',
              style: TextStyle(
                color: Colors.pink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Favorite Contacts",
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            // Add your list of contacts here
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to ParentsContact page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ParentsContact()),
            );
          },
          child: Icon(Icons.add),
          backgroundColor: const Color.fromARGB(255, 221, 39, 100),
        ),
      ),
    );
  }
}
