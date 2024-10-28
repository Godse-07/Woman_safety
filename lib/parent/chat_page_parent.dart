import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';


class ChatPageParent extends StatefulWidget {
  final String childId;
  final String childName;
  final String? childProfile;

  const ChatPageParent({
    Key? key,
    required this.childId,
    required this.childName,
    this.childProfile,
  }) : super(key: key);

  @override
  State<ChatPageParent> createState() => _ChatPageParentState();
}

class _ChatPageParentState extends State<ChatPageParent> {
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
    final String chatRoomId = _getChatRoomId(senderId, widget.childId);

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': widget.childId,
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
        messageContent = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
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
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(timestamp),
              style: TextStyle(
                fontSize: 11,
                color: isCurrentUser ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        );
        break;
      case 'video':
        messageContent = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () => _showFullScreenVideo(context, message['message']),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Icon(
                    Icons.play_circle_fill,
                    size: 50,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(timestamp),
              style: TextStyle(
                fontSize: 11,
                color: isCurrentUser ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        );
        break;
      default:
        messageContent = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message['message'],
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(timestamp),
              style: TextStyle(
                fontSize: 11,
                color: isCurrentUser ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        );
    }

    return Container(
      alignment: align,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Container(
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
    );
  }


   void _showFullScreenImage(BuildContext context, String imageUrl) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
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
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: FullScreenVideoPlayer(videoUrl: videoUrl),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final String chatRoomId = _getChatRoomId(
      _auth.currentUser!.uid,
      widget.childId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.childProfile != null)
              CircleAvatar(
                backgroundImage: NetworkImage(widget.childProfile!),
                radius: 20,
              )
            else
              const CircleAvatar(
                child: Icon(Icons.person),
                radius: 20,
              ),
            const SizedBox(width: 12),
            Text(widget.childName),
          ],
        ),
        backgroundColor: Colors.blueAccent,
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

                    final messages = snapshot.data!.docs;
                    return ListView.builder(
  reverse: true,
  itemCount: messages.length,
  itemBuilder: (context, index) {
    final messageData = messages[index].data() as Map<String, dynamic>;
    final currentMsgTime = (messageData['timestamp'] as Timestamp?)?.toDate();
    
    final previousMessageData = index < messages.length - 1
        ? messages[index + 1].data() as Map<String, dynamic>
        : null;
    final previousMsgTime = previousMessageData?['timestamp'] as Timestamp?;
    final previousDateTime = previousMsgTime?.toDate();

    final widgets = <Widget>[];

    if (_shouldShowDate(currentMsgTime, previousDateTime)) {
      widgets.add(_buildDateHeader(currentMsgTime!));
    }
    
    widgets.add(_buildMessageItem(messageData));
    
    return Column(children: widgets);
  },
);
                  },
                ),
              ),
              _buildMessageInput(),
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
  Widget _buildMessageInput() {
    return Container(
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: Colors.blueAccent,
            onPressed: _showMediaOptions,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Colors.blueAccent,
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                _sendMessage(_messageController.text, 'text');
                _messageController.clear();
              }
            },
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

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideoPlayer({Key? key, required this.videoUrl})
      : super(key: key);

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    try {
      _controller = VideoPlayerController.network(widget.videoUrl);
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing video player: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading video: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isInitialized)
          const Center(child: CircularProgressIndicator())
        else
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                // Custom controls overlay
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 60.0,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                // Video progress indicator
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.blue,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}