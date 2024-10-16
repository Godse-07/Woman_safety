import 'dart:math';

import 'package:flutter/material.dart';
import 'package:safe_circle/constant.dart';
import 'package:safe_circle/login_page.dart';
import 'package:safe_circle/utils/quetos.dart';
import 'package:safe_circle/widgets/home_widgets/Emergency_card.dart';
import 'package:safe_circle/widgets/home_widgets/SafeHome/SafeHome.dart';
import 'package:safe_circle/widgets/home_widgets/customCarouel.dart';
import 'package:safe_circle/widgets/home_widgets/custom_appbar.dart';
import 'package:safe_circle/widgets/home_widgets/live_safe.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  @override
  int index = 1;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getRandomQuote();
  }

  void getRandomQuote() {
    setState(() {
      index = Random().nextInt(quotes.length);
    });
  }

  Future<void> logout() async {
    setState(() {
      isLoading = true; // Show the loading indicator
    });

    // Simulate a network call or logout process
    await Future.delayed(
        Duration(seconds: 2)); // Replace with your logout logic

    // After logout, navigate to the LoginPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.05,
                  margin: EdgeInsets.only(top: 15, left: 10, right: 10),
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
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 10),
                        child: Text(
                          "Trust us to keep your daughters safe.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Spacer(),
                      Container(
                        child: InkWell(
                          onTap: isLoading
                              ? null
                              : logout, // Disable tap while loading
                          child: Icon(Icons.logout),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  margin:
                      EdgeInsets.only(bottom: 20, left: 10, top: 10, right: 10),
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
                      padding:
                          const EdgeInsets.only(top: 8.0, left: 8, right: 8),
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
                        padding: const EdgeInsets.only(
                            left: 10, top: 10, bottom: 10),
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
                        padding: const EdgeInsets.only(
                            left: 10, top: 10, bottom: 10),
                        child: Text(
                          "Explore LiveSafe",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      LiveSafe(),
                      SizedBox(height: 20),
                      SafeHome(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Center(
                child: Progress()), // Show the progress indicator in the center
        ],
      ),
    );
  }
}
