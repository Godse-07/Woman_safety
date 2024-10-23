import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safe_circle/child/bottom_screens/contact_page.dart';
import 'package:url_launcher/url_launcher.dart';

class FirstContact extends StatefulWidget {
  const FirstContact({Key? key}) : super(key: key);

  @override
  State<FirstContact> createState() => _FirstContactState();
}

class _FirstContactState extends State<FirstContact> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> favoriteContacts = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteContacts();
  }

  Future<void> _loadFavoriteContacts() async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        favoriteContacts = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    }
  }

  Future<void> _removeFromFavorites(String contactId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(contactId)
          .delete();

      setState(() {
        favoriteContacts.removeWhere((contact) => contact['id'] == contactId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact removed from favorites')),
      );
    }
  }

  Future<void> _callNumber(String number) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Unable to make phone call. ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Favorite Contacts",
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: favoriteContacts.length,
                itemBuilder: (context, index) {
                  final contact = favoriteContacts[index];
                  return ListTile(
                    title: Text(contact['name']),
                    subtitle: Text(contact['phone']),
                    leading: CircleAvatar(
                      backgroundColor: Colors.pinkAccent,
                      child: Text(
                        contact['name'].isNotEmpty ? contact['name'][0] : '',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => _callNumber(contact['phone']),
                            icon: const Icon(Icons.call, color: Colors.green),
                          ),
                          IconButton(
                            icon: const Icon(Icons.star, color: Colors.yellow),
                            onPressed: () => _removeFromFavorites(contact['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactPage()),
            );
            _loadFavoriteContacts();
          },
          child: const Icon(Icons.add),
          backgroundColor: Colors.pink,
        ),
      ),
    );
  }
}