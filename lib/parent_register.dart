import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safe_circle/components/custom_textfield.dart';
import 'package:safe_circle/components/primary_button.dart';
import 'package:safe_circle/components/secondary_button.dart';
import 'package:safe_circle/constant.dart';
import 'package:safe_circle/login_page.dart';
import 'package:safe_circle/model/user_model.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {


  bool isPasswordShown = true;
  bool isRPasswordShown = true;
  final _formKey = GlobalKey<FormState>();
  final _formData = Map<String, Object>();

  void _onSubmit() async {
    _formKey.currentState!.save();

    // Validate if the password and confirm password match
    if (_formData['password'] != _formData['rpassword']) {
      _showErrorDialog("Password does not match");
      return;
    }

    // Check if the email already exists
    bool emailExists = await _checkEmailExists(_formData['email'].toString());
    if (emailExists) {
      _showErrorDialog("An account with this email already exists");
      return;
    }

    // If everything is correct, show progress bar and register the user
    Progress();
    _registerUser();
  }

  Future<bool> _checkEmailExists(String email) async {
  try {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    print("Error checking email existence: $e");
    _showErrorDialog("An error occurred while checking email existence.");
    return false;
  }
}


  void _registerUser() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: _formData['email'].toString(),
        password: _formData['password'].toString(),
      );

      if (userCredential.user != null) {
        DocumentReference<Map<String, dynamic>> db = FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid);
        final user = UserModel(
          name: _formData['name'].toString(),
          number: _formData['number'].toString(),
          parent_email: _formData['email'].toString(),
          child_mail: _formData['cemail'].toString(),
          id: userCredential.user!.uid,
          type: "parent",
        );
        await db.set(user.toJson()).whenComplete(() {
          Navigator.of(context).pop(); // Dismiss progress dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Dismiss progress dialog
      _showErrorDialog(e.message ?? "An error occurred during registration");
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss progress dialog
      _showErrorDialog("An unexpected error occurred");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 15),
                child: Center(
                  child: Text(
                    "Register as a Parent",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD40061),
                    ),
                  ),
                ),
              ),
              Center(
                child: Image.asset(
                  "assets/new_logo.png",
                  height: 450,
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextfield(
                      hintText: "Enter Name",
                      prefix: Icon(Icons.person_outline_outlined),
                      validate: (name) {
                        if (name!.isEmpty) {
                          return "Name is required";
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.name,
                      onsave: (name) {
                        _formData['name'] = name ?? "";
                      },
                    ),
                    SizedBox(height: 20),
                    CustomTextfield(
                      hintText: "Enter Phone",
                      prefix: Icon(Icons.phone),
                      validate: (number) {
                        if (number!.isEmpty || number.length < 10) {
                          return "Valid phone number is required";
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      onsave: (number) {
                        _formData['number'] = number ?? "";
                      },
                    ),
                    SizedBox(height: 20),
                    CustomTextfield(
                      hintText: "Enter Email",
                      prefix: Icon(Icons.email_rounded),
                      validate: (email) {
                        if (email!.isEmpty || !email.contains("@")) {
                          return "Valid email is required";
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      onsave: (email) {
                        _formData['email'] = email ?? "";
                      },
                    ),
                    SizedBox(height: 20),
                    CustomTextfield(
                      hintText: "Enter Child's Email",
                      prefix: Icon(Icons.email_rounded),
                      validate: (cemail) {
                        if (cemail!.isEmpty || !cemail.contains("@")) {
                          return "Valid child's email is required";
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      onsave: (cemail) {
                        _formData['cemail'] = cemail ?? "";
                      },
                    ),
                    SizedBox(height: 20),
                    CustomTextfield(
                      hintText: "Enter Password",
                      isPassword: isPasswordShown,
                      prefix: Icon(Icons.password),
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            isPasswordShown = !isPasswordShown;
                          });
                        },
                        icon: Icon(
                          isPasswordShown
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      validate: (password) {
                        if (password!.isEmpty || password.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                      onsave: (password) {
                        _formData['password'] = password ?? "";
                      },
                    ),
                    SizedBox(height: 20),
                    CustomTextfield(
                      hintText: "Re-enter Password",
                      isPassword: isPasswordShown,
                      prefix: Icon(Icons.password),
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            isPasswordShown = !isPasswordShown;
                          });
                        },
                        icon: Icon(
                          isRPasswordShown
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      validate: (password) {
                        if (password!.isEmpty || password.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                      onsave: (password) {
                        _formData['rpassword'] = password ?? "";
                      },
                    ),
                    SizedBox(height: 30),
                    PrimaryButton(
                      title: "Register",
                      onPress: () {
                        if (_formKey.currentState!.validate()) {
                          _onSubmit();
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              SecondaryButton(
                title: "Login with existing account",
                onPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}