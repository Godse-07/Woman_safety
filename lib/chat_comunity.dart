import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

class ChatCommunity extends StatefulWidget {
  const ChatCommunity({Key? key}) : super(key: key);

  @override
  State<ChatCommunity> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<ChatCommunity> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  bool _shouldShowDate(DateTime? current, DateTime? previous) {
    if (current == null) return false;
    if (previous == null) return true;
    return !DateUtils.isSameDay(current, previous);
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getDateText(date),
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _getDateText(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) {
      return 'Today';
    } else if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('MMMM d').format(date);
    }
    return DateFormat('MMMM d, y').format(date);
  }

  String _formatMessageTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('HH:mm').format(time);
  }

  Future<void> _sendMessage(String message, String type) async {
    if (message.trim().isEmpty && type == 'text') return;

    final String senderId = _auth.currentUser!.uid;
    final String senderName = _auth.currentUser!.displayName ?? "Anonymous";

    await _firestore
        .collection('community_chats')
        .add({
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'type': type, // 'text', 'image', or 'video'
      'timestamp': FieldValue.serverTimestamp(),
    });
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
      final Reference ref = _storage.ref().child('community_media').child(fileName);

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
    final color = isCurrentUser ? Colors.blueAccent[100] : Colors.grey[300];
    final borderRadius = isCurrentUser
        ? BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
          );

    final timestamp = (message['timestamp'] as Timestamp?)?.toDate();
    
    Widget messageContent;
    switch (message['type']) {
      case 'image':
        messageContent = GestureDetector(
          onTap: () => _showFullScreenImage(context, message['message']),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message['message'],
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
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
        messageContent = Text(
          message['message'],
          style: TextStyle(fontSize: 16),
        );
    }

    return Container(
      alignment: align,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) Text(message['senderName']),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: messageContent,
          ),
          const SizedBox(height: 4),
          Text(
            _formatMessageTime(timestamp),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Chat'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('community_chats')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final messageData = messages[index].data() as Map<String, dynamic>;
                        final currentMsgTime = (messageData['timestamp'] as Timestamp?)?.toDate();

                                              final previousMsgTime = index < messages.length - 1
                            ? (messages[index + 1].data() as Map<String, dynamic>)['timestamp']
                            : null;

                        bool showDateHeader = _shouldShowDate(currentMsgTime, (previousMsgTime as Timestamp?)?.toDate());

                        return Column(
                          children: [
                            if (showDateHeader && currentMsgTime != null) _buildDateHeader(currentMsgTime),
                            _buildMessageItem(messageData),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              if (_isLoading) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_a_photo),
                      onPressed: _showMediaOptions,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        _sendMessage(_messageController.text.trim(), 'text');
                        _messageController.clear();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
          ),
          body: Center(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  void _showFullScreenVideo(BuildContext context, String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPlayer(videoUrl: videoUrl),
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const FullScreenVideoPlayer({required this.videoUrl, Key? key}) : super(key: key);

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

