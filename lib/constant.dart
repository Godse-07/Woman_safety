import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Progress extends StatelessWidget {
  const Progress({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.halfTriangleDot(
        size: 80,
        color: Colors.pink,
      ),
    );
  }
}

// Function to show progress dialog
void showProgressDialog(BuildContext context) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return const Progress();
    },
  );
}

// Function to hide progress dialog
void hideProgressDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}