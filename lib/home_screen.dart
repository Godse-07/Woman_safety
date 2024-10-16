import 'dart:math';

import 'package:flutter/material.dart';
import 'package:safe_circle/utils/quetos.dart';
import 'package:safe_circle/widgets/home_widgets/Emergency_card.dart';
import 'package:safe_circle/widgets/home_widgets/SafeHome/SafeHome.dart';
import 'package:safe_circle/widgets/home_widgets/customCarouel.dart';
import 'package:safe_circle/widgets/home_widgets/custom_appbar.dart';
import 'package:safe_circle/widgets/home_widgets/live_safe.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 1;

  getRandomQuote() {
    setState(() {
      index = Random().nextInt(quotes.length);
    });
  }

  @override
  void initState() {
    getRandomQuote();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 20, left: 10, top: 10, right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFD8080),
                    Color(0xFFFB8580),
                    Color(0xFFFBD079),
                  ],
                ),
              ),
              width: double.infinity,
              padding: EdgeInsets.only(left: 10, right: 10, bottom: 5),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8, right: 8),
                  child: CustomAppbar(
                    onTap: getRandomQuote,
                    qIndex: index,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Customcarouel(),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 10, top: 10, bottom: 10),
                    child: Text(
                      "Emergency",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  EmergencyCard(),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 10, top: 10, bottom: 10),
                    child: Text(
                      "Explore LiveSafe",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  LiveSafe(),
                  SizedBox(
                    height: 20,
                  ),
                  SafeHome(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
