import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safe_circle/parent/chat_page_parent.dart';

class ParentsChat extends StatefulWidget {
  const ParentsChat({super.key});

  @override
  State<ParentsChat> createState() => _ParentsChatState();
}

class _ParentsChatState extends State<ParentsChat> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to get all children where gemail matches current user's email and type is 'child'
  Stream<QuerySnapshot> getChildren() {
    // Get current user's email
    final String? currentUserEmail = _auth.currentUser?.email;

    if (currentUserEmail == null) {
      // Return an empty stream if no user is logged in
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .where('gemail', isEqualTo: currentUserEmail)
        .where('type', isEqualTo: 'child')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    if (_auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your children'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getChildren(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No children found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final child = snapshot.data!.docs[index];
              final data = child.data() as Map<String, dynamic>;

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
                      Text(data['mail'] ?? 'No Email'),
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
                          builder: (context) => ChatPageParent(
                            childId: child.id,
                            childName: data['name'] ?? 'No Name',
                            childProfile: data['profilePictureUrl'],
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

// class ChatScreen extends StatelessWidget {
//   final String childId;
//   final String childName;
//   final String? childProfile;

//   const ChatScreen({
//     super.key,
//     required this.childId,
//     required this.childName,
//     this.childProfile,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             if (childProfile != null)
//               CircleAvatar(
//                 backgroundImage: NetworkImage(childProfile!),
//                 radius: 20,
//               )
//             else
//               const CircleAvatar(
//                 child: Icon(Icons.person),
//                 radius: 20,
//               ),
//             const SizedBox(width: 12),
//             Text(childName),
//           ],
//         ),
//         backgroundColor: Colors.blue,
//       ),
//       body: const Center(
//         child:
//             Text('Individual chat screen - Implement chat functionality here'),
//       ),
//     );
//   }
// }
