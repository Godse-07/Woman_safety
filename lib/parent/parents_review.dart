import 'package:flutter/material.dart';

class ParentsReview extends StatefulWidget {
  const ParentsReview({super.key});

  @override
  State<ParentsReview> createState() => _ParentsReviewState();
}

class _ParentsReviewState extends State<ParentsReview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Parents Review'),
      ),
    );
  }
}