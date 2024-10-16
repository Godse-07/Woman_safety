import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

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
        body: isLoading
            ? Center(child: CircularProgressIndicator())
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
                            prefixIcon: Icon(Icons.search, color: Colors.pinkAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 10.0),
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
                                        style:
                                            TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        contact.phones.isNotEmpty
                                            ? contact.phones.first.number
                                            : "No Phone",
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.pinkAccent,
                                        child: Text(
                                          contact.displayName.isNotEmpty ? contact.displayName[0] : '',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.pinkAccent,
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
                                style: TextStyle(color: Colors.grey, fontSize: 18),
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
