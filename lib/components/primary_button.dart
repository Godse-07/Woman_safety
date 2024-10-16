import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String title;
  final Function onPress;
  final bool loading;

  PrimaryButton({
    required this.title,
    required this.onPress,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: MediaQuery.of(context).size.width * 0.65,
      child: ElevatedButton(
          onPressed: () {
            onPress();
          },
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFD40061),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          )),
    );
  }
}
