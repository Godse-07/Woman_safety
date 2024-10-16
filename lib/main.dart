import 'package:flutter/material.dart';
import 'package:safe_circle/firebase_options.dart';
import 'package:safe_circle/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:safe_circle/login_page.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: HomeScreen(),
      home: LoginPage(),
    );
  }
}
