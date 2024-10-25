import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChildChat extends StatefulWidget {
  const ChildChat({super.key});

  @override
  State<ChildChat> createState() => _ChildChatState();
}

class _ChildChatState extends State<ChildChat> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to get all parents where the user's email matches mail
  Stream<QuerySnapshot> getParents() {
    final String? currentUserEmail = _auth.currentUser?.email;

    if (currentUserEmail == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .where('mail', isEqualTo: currentUserEmail)
        .where('type', isEqualTo: 'parent')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your parents'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Parents'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getParents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No parents found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final parent = snapshot.data!.docs[index];
              final data = parent.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: data['profilePictureUrl'] != null
                      ? CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              NetworkImage(data['profilePictureUrl']),
                        )
                      : const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person),
                        ),
                  title: Text(
                    data['gname'] ?? 'No Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(data['gemail'] ?? 'No Email'),
                      Text('Phone: ${data['number'] ?? 'No Number'}'),
                    ],
                  ),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            parentId: parent.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final String parentId;

  const ChatScreen({
    super.key,
    required this.parentId,
  });

  Future<Map<String, dynamic>?> getParentData() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final parentSnapshot =
        await _firestore.collection('users').doc(parentId).get();

    if (!parentSnapshot.exists) {
      return null;
    }

    return parentSnapshot.data() as Map<String, dynamic>?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Parent'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getParentData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text('Failed to load parent data.'),
            );
          }

          final parentData = snapshot.data!;
          final parentName = parentData['gname'] ?? 'No Name';
          final parentEmail = parentData['gemail'] ?? 'No Email';
          final parentNumber = parentData['number'] ?? 'No Number';
          final parentProfile = parentData['profilePictureUrl'];

          return Column(
            children: [
              ListTile(
                leading: parentProfile != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(parentProfile),
                        radius: 30,
                      )
                    : const CircleAvatar(
                        child: Icon(Icons.person),
                        radius: 30,
                      ),
                title: Text(parentName),
                subtitle: Text(parentEmail),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Phone: $parentNumber',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const Divider(),
              const Expanded(
                child: Center(
                  child: Text('Chat functionality goes here'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
