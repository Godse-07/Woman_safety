import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final email = TextEditingController();

  Future<void> sendpasswordResetLink(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 15),
                child: Text(
                  "Forget Password",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD40061),
                  ),
                ),
              ),
              Image.asset(
                "assets/new_logo.png",
                height: 450,
              ),
              const Text(
                "Enter your email address to reset your password.",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SwipeButton.expand(
                thumb: Icon(
                  Icons.double_arrow_rounded,
                  color: Colors.white,
                ),
                child: Text(
                  "Swipe to change password...",
                  style: TextStyle(
                    color: Color(0xFFD40061),
                  ),
                ),
                activeThumbColor: Color(0xFFD40061),
                activeTrackColor: Colors.grey.shade300,
                onSwipe: () async {
                  if (email.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Email is required."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  } else {
                    await sendpasswordResetLink(email.text);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text("Password reset link sent to your email."),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
