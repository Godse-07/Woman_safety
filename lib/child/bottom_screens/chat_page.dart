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
              //   print(data);
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
                    data['name'] ?? 'No Name',
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
                            parentName: data['name'] ?? 'No Name',
                            parentProfile: data['profilePictureUrl'],
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

  final String parentName;
  final String? parentProfile;

  const ChatScreen({
    super.key,
    required this.parentId,
    required this.parentName,
    this.parentProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (parentProfile != null)
              CircleAvatar(
                backgroundImage: NetworkImage(parentProfile!),
                radius: 20,
              )
            else
              const CircleAvatar(
                child: Icon(Icons.person),
                radius: 20,
              ),
            const SizedBox(width: 12),
            Text(parentName),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child:
            Text('Individual chat screen - Implement chat functionality here'),
      ),
    );
  }
}
