import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  final String title;
  final Function onPress;
  final bool loading;

  SecondaryButton({
    required this.title,
    required this.onPress,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextButton(
          onPressed: () {
            onPress();
          },
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFFD40061),
            ),
          )),
    );
  }
}
