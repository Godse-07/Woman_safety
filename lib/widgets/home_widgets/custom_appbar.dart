import 'package:flutter/material.dart';
import 'package:safe_circle/utils/quetos.dart';

class CustomAppbar extends StatelessWidget {
  Function? onTap;
  int? qIndex;

  CustomAppbar({this.onTap, this.qIndex});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: EdgeInsets.only(
          bottom: 10,
        ),
        child: Text(
          quotes[qIndex!],
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () {
        onTap!();
      },
    );
  }
}
