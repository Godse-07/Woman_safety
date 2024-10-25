import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safe_circle/child/bottom_screens/chatScreenChild.dart';

class ChildChat extends StatefulWidget {
  const ChildChat({super.key});

  @override
  State<ChildChat> createState() => _ChildChatState();
}

class _ChildChatState extends State<ChildChat> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to get linked parents for the current child
  Stream<List<DocumentSnapshot>> getParents() async* {
    final String? currentUserUid = _auth.currentUser?.uid;

    if (currentUserUid == null) {
      yield [];
      return;
    }

    // Get the current child's document to find their parent's email
    DocumentSnapshot childDoc = await _firestore
        .collection('users')
        .doc(currentUserUid)
        .get();
    
    if (!childDoc.exists) {
      yield [];
      return;
    }

    final childData = childDoc.data() as Map<String, dynamic>;
    final parentEmail = childData['gemail'] as String?; // Using gemail instead of mail

    if (parentEmail == null) {
      yield [];
      return;
    }

    // Listen to users collection for parents matching the parent's email
    await for (QuerySnapshot parentsSnapshot in _firestore
        .collection('users')
        .where('type', isEqualTo: 'parent')
        .where('gemail', isEqualTo: parentEmail) // Using gemail to match parent's email
        .snapshots()) {
      
      List<DocumentSnapshot> parentDocs = parentsSnapshot.docs;
      yield parentDocs;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Parents'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: getParents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final parents = snapshot.data ?? [];

          if (parents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No parents linked yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Trigger a rebuild to refresh data
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: parents.length,
            itemBuilder: (context, index) {
              final parent = parents[index];
              final data = parent.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: data['profilePictureUrl'] != null
                      ? CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(data['profilePictureUrl']),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreenChild(
                                parentId: parent.id,
                                parentName: data['name'] ?? 'No Name',
                                parentProfile: data['profilePictureUrl'],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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