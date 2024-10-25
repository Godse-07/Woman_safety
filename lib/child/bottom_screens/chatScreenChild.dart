import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatScreenChild extends StatefulWidget {
  final String parentId;
  final String parentName;
  final String? parentProfile;

  const ChatScreenChild({
    Key? key,
    required this.parentId,
    required this.parentName,
    this.parentProfile,
  }) : super(key: key);

  @override
  State<ChatScreenChild> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreenChild> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _sendMessage(String message, String type) async {
    if (message.trim().isEmpty && type == 'text') return;

    final String senderId = _auth.currentUser!.uid;
    final String chatRoomId = _getChatRoomId(senderId, widget.parentId);

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': widget.parentId,
      'message': message,
      'type': type, // 'text', 'image', or 'video'
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  String _getChatRoomId(String userId1, String userId2) {
    return userId1.compareTo(userId2) > 0
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  Future<void> _pickAndSendMedia(ImageSource source, String type) async {
    try {
      setState(() => _isLoading = true);

      final XFile? mediaFile = type == 'image'
          ? await _picker.pickImage(source: source)
          : await _picker.pickVideo(source: source);

      if (mediaFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${mediaFile.name}';
      final Reference ref = _storage.ref().child('chat_media').child(fileName);

      await ref.putFile(File(mediaFile.path));
      final String downloadUrl = await ref.getDownloadURL();

      await _sendMessage(downloadUrl, type);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending media: $e')),
      );
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickAndSendMedia(ImageSource.camera, 'image');
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickAndSendMedia(ImageSource.gallery, 'image');
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Take Video'),
            onTap: () {
              Navigator.pop(context);
              _pickAndSendMedia(ImageSource.camera, 'video');
            },
          ),
          ListTile(
            leading: const Icon(Icons.video_library),
            title: const Text('Choose Video'),
            onTap: () {
              Navigator.pop(context);
              _pickAndSendMedia(ImageSource.gallery, 'video');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    final bool isCurrentUser = message['senderId'] == _auth.currentUser!.uid;
    final align = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isCurrentUser ? Colors.blue[100] : Colors.grey[300];

    Widget messageContent;
    switch (message['type']) {
      case 'image':
        messageContent = GestureDetector(
          onTap: () => _showFullScreenImage(context, message['message']),
          child: Image.network(
            message['message'],
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        );
        break;
      case 'video':
        messageContent = GestureDetector(
          onTap: () => _showFullScreenVideo(context, message['message']),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                color: Colors.black,
              ),
              const Icon(
                Icons.play_circle_fill,
                size: 50,
                color: Colors.white,
              ),
            ],
          ),
        );
        break;
      default:
        messageContent = Text(message['message']);
    }

    return Container(
      alignment: align,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: messageContent,
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenVideo(BuildContext context, String videoUrl) {
    // Implement video player functionality here
    // You'll need to add a video player package like video_player or chewie
  }

  @override
  Widget build(BuildContext context) {
    final String chatRoomId = _getChatRoomId(
      _auth.currentUser!.uid,
      widget.parentId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.parentProfile != null)
              CircleAvatar(
                backgroundImage: NetworkImage(widget.parentProfile!),
                radius: 20,
              )
            else
              const CircleAvatar(
                child: Icon(Icons.person),
                radius: 20,
              ),
            const SizedBox(width: 12),
            Text(widget.parentName),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .doc(chatRoomId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      reverse: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final message = snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                        return _buildMessageItem(message);
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, -2),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _showMediaOptions,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (_messageController.text.trim().isNotEmpty) {
                          _sendMessage(_messageController.text, 'text');
                          _messageController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
