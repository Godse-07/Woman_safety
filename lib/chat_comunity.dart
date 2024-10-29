import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Main Chat Screen Widget
class ChatCommunity extends StatefulWidget {
  const ChatCommunity({Key? key}) : super(key: key);

  @override
  State<ChatCommunity> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<ChatCommunity> {
  // Controllers and Services
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // State variables
  bool _isLoading = false;
  String? _userName;
  String? _userProfileUrl;

  // Initialize state and load user data
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Load user profile data from Firestore
  Future<void> _loadUserProfile() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? 'Anonymous';
          _userProfileUrl = userDoc.data()?['profilePictureUrl'];
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Check if date should be shown in chat
  bool _shouldShowDate(DateTime? current, DateTime? previous) {
    if (current == null) return false;
    if (previous == null) return true;
    return !DateUtils.isSameDay(current, previous);
  }

  // Build date header widget
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

  // Format date text for header
  String _getDateText(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) {
      return 'Today';
    } else if (DateUtils.isSameDay(
        date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('MMMM d').format(date);
    }
    return DateFormat('MMMM d, y').format(date);
  }

  // Format message time
  String _formatMessageTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('HH:mm').format(time);
  }

  // Send message to Firestore
  Future<void> _sendMessage(String message, String type) async {
    if (message.trim().isEmpty && type == 'text') return;

    final String senderId = _auth.currentUser!.uid;
    String senderName = _userName ?? 'Anonymous';
    String? photoURL = _auth.currentUser?.photoURL ?? _userProfileUrl;

    await _firestore.collection('community_chats').add({
      'senderId': senderId,
      'senderName': senderName,
      'photoURL': photoURL,
      'message': message,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Pick and send media (image/video)
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
      final Reference ref =
          _storage.ref().child('community_media').child(fileName);

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

  // Show media picker options
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

  // Build individual message item
  Widget _buildMessageItem(Map<String, dynamic> message) {
    final bool isCurrentUser = message['senderId'] == _auth.currentUser!.uid;
    final align = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isCurrentUser ? Colors.blueAccent[100] : Colors.grey[300];
    final borderRadius = isCurrentUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
          );

    final timestamp = (message['timestamp'] as Timestamp?)?.toDate();
    final String senderName = message['senderName'] ?? 'Anonymous';
    final String? senderPhotoURL = message['photoURL'];

    return Container(
      alignment: align,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            UserAvatar(
              photoURL: senderPhotoURL,
              name: senderName,
              radius: 20,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(message),
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
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            UserAvatar(
              photoURL: _auth.currentUser?.photoURL ?? _userProfileUrl,
              name: _userName ?? 'Anonymous',
              radius: 20,
            ),
          ],
        ],
      ),
    );
  }

  // Build message content based on type
  Widget _buildMessageContent(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'image':
        return GestureDetector(
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
      case 'video':
        return GestureDetector(
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
      default:
        return Text(
          message['message'],
          style: TextStyle(fontSize: 16),
        );
    }
  }

  // Show full screen image
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

  // Show full screen video
  void _showFullScreenVideo(BuildContext context, String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPlayer(videoUrl: videoUrl),
      ),
    );
  }

  // Main build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: const Text(
          'Community Chat',
          style: TextStyle(
            color: Colors.pink,
          ),
        )),
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
                        final messageData =
                            messages[index].data() as Map<String, dynamic>;
                        final currentMsgTime =
                            (messageData['timestamp'] as Timestamp?)?.toDate();

                        final previousMsgTime = index < messages.length - 1
                            ? (messages[index + 1].data()
                                as Map<String, dynamic>)['timestamp']
                            : null;

                        bool showDateHeader = _shouldShowDate(currentMsgTime,
                            (previousMsgTime as Timestamp?)?.toDate());

                        return Column(
                          children: [
                            if (showDateHeader && currentMsgTime != null)
                              _buildDateHeader(currentMsgTime),
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
}

// Full Screen Video Player Widget
class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const FullScreenVideoPlayer({required this.videoUrl, Key? key})
      : super(key: key);

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

// Continuing FullScreenVideoPlayer implementation
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

// First, create a new ProfileCard widget
class ProfileCard extends StatelessWidget {
  final String? photoURL;
  final String name;
  final VoidCallback onClose;

  const ProfileCard({
    Key? key,
    required this.photoURL,
    required this.name,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(0),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Column(
                    children: [
                      if (photoURL != null && photoURL!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: photoURL!,
                          imageBuilder: (context, imageProvider) => Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          placeholder: (context, url) => Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                            child: Center(
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          child: Center(
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String? photoURL;
  final String name;
  final double radius;

  const UserAvatar({
    Key? key,
    this.photoURL,
    required this.name,
    this.radius = 20,
  }) : super(key: key);

  void _showProfileCard(BuildContext context) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: InkWell(
          onTap: () => overlayEntry?.remove(),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: ProfileCard(
                photoURL: photoURL,
                name: name,
                onClose: () => overlayEntry?.remove(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  Widget _buildDefaultAvatar(String text) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String avatarText = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => _showProfileCard(context),
      child: photoURL != null && photoURL!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: photoURL!,
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: radius,
                backgroundImage: imageProvider,
              ),
              placeholder: (context, url) => CircleAvatar(
                radius: radius,
                backgroundColor: Colors.grey[300],
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              errorWidget: (context, url, error) =>
                  _buildDefaultAvatar(avatarText),
            )
          : _buildDefaultAvatar(avatarText),
    );
  }
}
