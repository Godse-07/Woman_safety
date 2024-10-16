import 'package:flutter/material.dart';

class ParentsChat extends StatefulWidget {
  const ParentsChat({super.key});

  @override
  State<ParentsChat> createState() => _ParentsChatState();
}

class _ParentsChatState extends State<ParentsChat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Parents Chat'),
      ),
    );
  }
}