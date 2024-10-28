import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safe_circle/constant.dart';
import 'parents_contact.dart';

class FirstContact extends StatefulWidget {
  const FirstContact({super.key});

  @override
  State<FirstContact> createState() => _FirstContactState();
}

class _FirstContactState extends State<FirstContact> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> favoriteContacts = [];
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _loadFavoriteContacts();
  }

  Future<void> _loadFavoriteContacts() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy('timestamp', descending: true)
            .get();

        setState(() {
          favoriteContacts = querySnapshot.docs
              .map((doc) =>
                  {...doc.data() as Map<String, dynamic>, 'id': doc.id})
              .toList();
          isLoading = false; // Update loading state
        });
      } catch (e) {
        // Handle errors if necessary
        setState(() {
          isLoading = false; // Ensure loading is false on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: ${e.toString()}')),
        );
      }
    } else {
      setState(() {
        isLoading = false; // Ensure loading is false if no user is logged in
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
        SnackBar(content: Text('Contact removed from favorites')),
      );
    }
  }

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
            Expanded(
              child: isLoading // Check if loading
                  ? Center(
                      child: Progress(), // Show loading indicator
                    )
                  : ListView.builder(
                      itemCount: favoriteContacts.length,
                      itemBuilder: (context, index) {
                        final contact = favoriteContacts[index];
                        return ListTile(
                          title: Text(contact['name']),
                          subtitle: Text(contact['phone']),
                          leading: CircleAvatar(
                            backgroundColor: Colors.pinkAccent,
                            child: Text(
                              contact['name'].isNotEmpty
                                  ? contact['name'][0]
                                  : '',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.star, color: Colors.yellow),
                            onPressed: () =>
                                _removeFromFavorites(contact['id']),
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
              MaterialPageRoute(builder: (context) => ParentsContact()),
            );
            _loadFavoriteContacts(); // Reload favorites after returning from ParentsContact
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.pink,
        ),
      ),
    );
  }
}
