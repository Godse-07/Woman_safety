import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safe_circle/constant.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  String? _imageUrl;
  bool _isLoading = false;
  final picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User information fields
  String? name;
  String? email;
  String? number;
  String? accountType;
  String? parent_name;
  String? parent_email;

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Load data when the widget is initialized
  }

  // Method to load profile data from Firestore
  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _imageUrl = data['profilePictureUrl'] as String?;
            name = data['name'] as String?;
            email = data['mail'] as String?;
            number = data['number'] as String?;
            accountType = data['type'] as String?;
            parent_name = data['gname'] as String?;
            parent_email = data['gemail'] as String?;
          });
        }
      }
    } catch (e) {
      print('Failed to load profile data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfileField(String field, String newValue) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          field: newValue,
        });

        // Refresh the profile data after update
        await _loadProfileData(); // Refresh data to reflect the changes

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$field updated successfully')),
        );
      } catch (e) {
        print('Failed to update profile field: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update $field')),
        );
      }
    }
  }

  Future<void> _getImage() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _imageUrl = null; // Clear the old image URL
        });
      }
    } catch (e) {
      print('Failed to pick image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select image')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final ref = _storage.ref().child('profile_pictures/${user.uid}.jpg');
      await ref.putFile(_image!);
      final url = await ref.getDownloadURL();

      // Save the URL to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'profilePictureUrl': url,
      }, SetOptions(merge: true));

      setState(() {
        _imageUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture uploaded successfully')),
      );
    } catch (e) {
      print('Failed to upload image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final ref = _storage.ref().child('profile_pictures/${user.uid}.jpg');
      await ref.delete();

      await _firestore.collection('users').doc(user.uid).update({
        'profilePictureUrl': FieldValue.delete(),
      });

      setState(() {
        _image = null;
        _imageUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture removed successfully')),
      );
    } catch (e) {
      print('Failed to remove image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove image')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editProfileField(String field, String? currentValue) async {
    TextEditingController controller =
        TextEditingController(text: currentValue);
    final newValue = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter new $field'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (newValue != null && newValue.isNotEmpty) {
      await _updateProfileField(field, newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'User Profile',
            style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: Progress())
          : SizedBox(
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFD8080),
                        Color(0xFFFB8580),
                        Color(0xFFFBD079),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 80,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : (_imageUrl != null
                                      ? NetworkImage(_imageUrl!)
                                      : null) as ImageProvider?,
                              child: (_image == null && _imageUrl == null)
                                  ? Icon(Icons.person,
                                      size: 80, color: Colors.grey[600])
                                  : null,
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _getImage,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: Text('Select Profile Picture'),
                                    ),
                                    SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _uploadImage,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: Text('Upload Profile Picture'),
                                    ),
                                    SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _removeImage,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: Text('Remove Profile Picture'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text('Name: $name'),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editProfileField('name', name),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text('Email: $email'),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editProfileField('mail', email),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text('Phone Number: $number'),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () =>
                                _editProfileField('number', number),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text('Account Type: $accountType'),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () =>
                                _editProfileField('type', accountType),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text('Parent Name: $parent_name'),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () =>
                                _editProfileField('gname', parent_name),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text('Parent Email: $parent_email'),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () =>
                                _editProfileField('gemail', parent_email),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
