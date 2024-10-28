import 'package:flutter/material.dart';
import 'package:safe_circle/child/bottom_page.dart';
import 'package:safe_circle/constant.dart';
import 'package:safe_circle/db/shared_pref.dart';
import 'package:safe_circle/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:safe_circle/login_page.dart';
import 'package:safe_circle/parent/parent_bottom_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Circle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: _checkLoginStatus(),
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Progress();
          }
          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return LoginPage();
          }
          if (snapshot.data == "child") {
            return BottomPage();
          } else if (snapshot.data == "parent") {
            return ParentsBottomPage();
          }
          return LoginPage();
        },
      ),
    );
  }

  Future<String?> _checkLoginStatus() async {
    return await SharedPref.getUserType();
  }
}