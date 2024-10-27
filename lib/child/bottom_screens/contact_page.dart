import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:safe_circle/constant.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({Key? key}) : super(key: key);

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  TextEditingController searchController = TextEditingController();
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  bool isLoading = true;
  bool permissionDenied = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _askPermission();
    searchController.addListener(filterContacts);
  }

  Future<void> _askPermission() async {
    PermissionStatus status = await _getContactsPermission();
    if (status.isGranted) {
      await _getAllContacts();
    } else {
      setState(() {
        permissionDenied = true;
        isLoading = false;
      });
    }
  }

  Future<PermissionStatus> _getContactsPermission() async {
    PermissionStatus status = await Permission.contacts.status;
    if (!status.isGranted || status.isPermanentlyDenied) {
      status = await Permission.contacts.request();
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
    }
    return status;
  }

  Future<void> _getAllContacts() async {
    try {
      final fetchedContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      setState(() {
        contacts = fetchedContacts;
        filteredContacts = fetchedContacts;
        isLoading = false;
        permissionDenied = false;
      });
    } catch (e) {
      print('Error fetching contacts: $e');
      setState(() {
        permissionDenied = true;
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(Contact contact) async {
    final user = _auth.currentUser;
    if (user != null) {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(contact.id);
      final doc = await docRef.get();

      if (doc.exists) {
        // If the contact is already a favorite, remove it
        await docRef.delete();
      } else {
        // If the contact is not a favorite, add it
        await docRef.set({
          'name': contact.displayName,
          'phone': contact.phones.isNotEmpty
              ? contact.phones.first.number
              : "No Phone",
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Refresh the UI
      setState(() {});
    }
  }

  Future<bool> _isFavorite(String contactId) async {
    final user = _auth.currentUser;
    if (user != null) {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(contactId);
      final doc = await docRef.get();
      return doc.exists;
    }
    return false;
  }

  void filterContacts() {
    List<Contact> _filteredContacts = [];
    _filteredContacts.addAll(contacts);
    if (searchController.text.isNotEmpty) {
      _filteredContacts.retainWhere((contact) {
        String search = searchController.text.toLowerCase();
        String name = contact.displayName.toLowerCase();
        return name.contains(search);
      });
    }
    setState(() {
      filteredContacts = _filteredContacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = searchController.text.isNotEmpty;
    bool listItemExists =
        isSearching ? filteredContacts.isNotEmpty : contacts.isNotEmpty;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Contact list'),
        ),
        body: isLoading
            ? Center(child: Progress())
            : permissionDenied
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Permission denied'),
                        ElevatedButton(
                          onPressed: _askPermission,
                          child: const Text('Request Permission'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          autocorrect: true,
                          decoration: InputDecoration(
                            hintText: "Search Contacts",
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon:
                                Icon(Icons.search, color: Colors.pinkAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 10.0),
                          ),
                          controller: searchController,
                        ),
                      ),
                      listItemExists
                          ? Expanded(
                              child: ListView.builder(
                                itemCount: isSearching
                                    ? filteredContacts.length
                                    : contacts.length,
                                itemBuilder: (context, index) {
                                  Contact contact = isSearching
                                      ? filteredContacts[index]
                                      : contacts[index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    elevation: 5,
                                    child: ListTile(
                                      title: Text(
                                        contact.displayName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        contact.phones.isNotEmpty
                                            ? contact.phones.first.number
                                            : "No Phone",
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.pinkAccent,
                                        child: Text(
                                          contact.displayName.isNotEmpty
                                              ? contact.displayName[0]
                                              : '',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      trailing: FutureBuilder<bool>(
                                        future: _isFavorite(contact.id),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return CircularProgressIndicator();
                                          }
                                          bool isFavorite =
                                              snapshot.data ?? false;
                                          return IconButton(
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.star
                                                  : Icons.star_border_outlined,
                                              color: isFavorite
                                                  ? Colors.yellow
                                                  : Colors.pinkAccent,
                                            ),
                                            onPressed: () async {
                                              await _toggleFavorite(contact);
                                              setState(() {
                                                // Trigger rebuild to update the star icon
                                              });
                                            },
                                          );
                                        },
                                      ),
                                      onTap: () {
                                        // Handle contact tap
                                      },
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                "No Contacts Found",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 18),
                              ),
                            ),
                    ],
                  ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
