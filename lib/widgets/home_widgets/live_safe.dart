import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safe_circle/widgets/home_widgets/live_safe/BustopCard.dart';
import 'package:safe_circle/widgets/home_widgets/live_safe/HospitalCard.dart';
import 'package:safe_circle/widgets/home_widgets/live_safe/PharmeccuCard.dart';
import 'package:safe_circle/widgets/home_widgets/live_safe/PoliceStationCard.dart';

class LiveSafe extends StatelessWidget {
  const LiveSafe({super.key});

  static Future<void> openMap(String location) async {
    String googleUrl = 'https://www.google.com/maps/search/$location';

    final Uri _url = Uri.parse(googleUrl);

    try {
      await launchUrl(_url);
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Something went wrong! Call emergency number");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: MediaQuery.of(context).size.width,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          PoliceStationCard(
            onMapfunction: openMap,
          ),
          SizedBox(width: 20),
          HospitalCard(
            onMapfunction: openMap,
          ),
          SizedBox(width: 20),
          PharmeccuCard(
            onMapfunction: openMap,
          ),
          SizedBox(width: 20),
          Bustopcard(
            onMapfunction: openMap,
          ),
        ],
      ),
    );
  }
}
