import 'package:flutter/material.dart';

class Bustopcard extends StatelessWidget {
  const Bustopcard({super.key, this.onMapfunction});

  final Function? onMapfunction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              onMapfunction!('bus stop near me');
            },
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                height: 50,
                width: 50,
                child: Center(
                  child: Image.asset(
                    "assets/bus-stop.png",
                    height: 40,
                  ),
                ),
              ),
            ),
          ),
          Text("Bus Stop"),
        ],
      ),
    );
  }
}
