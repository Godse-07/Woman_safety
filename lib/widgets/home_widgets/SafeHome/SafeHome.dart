import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher_string.dart';

class SafeHome extends StatelessWidget {
  const SafeHome({super.key});

  void ShowModelSafeHome(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height / 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFD8080), Color(0xFFFB8580), Color(0xFFFBD079)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: 200,
                height: 200,
                child: Image.asset('assets/bell.png', fit: BoxFit.cover),
              ),
              Text(
                'Share your location with your favorite contacts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Get current location
                    Position position = await _getCurrentLocation();

                    // Get favorite contacts from Firebase
                    List<Map<String, dynamic>> favoriteContacts = await _getFavoriteContacts();

                    // Extract phone numbers from favorite contacts
                    List<String> phoneNumbers = favoriteContacts.map((contact) => contact['phone'] as String).toList();

                    // Share location with all favorite contacts at once
                    await _shareLocation(position, phoneNumbers);

                    // Show confirmation to the user
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Location shared with favorite contacts. Check your clipboard if SMS failed.')),
                    );
                  } catch (e) {
                    // Show error message to the user
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: Text('Share Location'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Color(0xFFFB8580),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<List<Map<String, dynamic>>> _getFavoriteContacts() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;

    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    }
    return [];
  }

  // Future<void> _shareLocation(Position position, List<String> phoneNumbers) async {
  //   String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
  //   String message = 'Check out my current location: $googleMapsUrl';
    
  //   // Combine phone numbers into a single string, separated by commas
  //   String phoneNumberList = phoneNumbers.join(',');

  //   // SMS URL with multiple recipients
  //   String smsUrl = 'sms:$phoneNumberList?body=${Uri.encodeComponent(message)}';
    
  //   try {
  //     if (await canLaunch(smsUrl)) {
  //       await launch(smsUrl);
  //     } else {
  //       throw 'Could not launch SMS';
  //     }
  //   } catch (e) {
  //     print('Error launching SMS: $e');
      
  //     // Fallback: Launch the default messaging app
  //     String fallbackUrl = 'sms:$phoneNumberList';
  //     try {
  //       if (await canLaunch(fallbackUrl)) {
  //         await launch(fallbackUrl);
  //         // If successful, copy the message to clipboard
  //         await Clipboard.setData(ClipboardData(text: message));
  //         print('Message copied to clipboard');
  //       } else {
  //         throw 'Could not launch messaging app';
  //       }
  //     } catch (e) {
  //       print('Error launching messaging app: $e');
  //       // Copy the message to clipboard if all else fails
  //       await Clipboard.setData(ClipboardData(text: message));
  //       print('Message copied to clipboard');
  //       throw 'Could not send SMS. Message copied to clipboard.';
  //     }
  //   }
  // }


  Future<void> _shareLocation(Position position, List<String> phoneNumbers) async {
  if (phoneNumbers.isEmpty) {
    throw 'No favorite contacts found';
  }

  String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
  String message = 'Check out my current location: $googleMapsUrl';

  for (String phoneNumber in phoneNumbers) {
    try {
      // Format phone number - remove any spaces and make sure it starts with proper format
      String formattedNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
      if (!formattedNumber.startsWith('+')) {
        // If number doesn't start with +, assume it's a local number and add +91 (for India)
        formattedNumber = '+91$formattedNumber';
      }

      if (Platform.isAndroid) {
        // Android-specific SMS URI format
        final Uri smsUri = Uri(
          scheme: 'smsto',
          path: formattedNumber,
          queryParameters: {'body': message},
        );

        final String smsUrl = smsUri.toString().replaceAll('smsto:', 'sms:');
        
        if (await canLaunchUrlString(smsUrl)) {
          await launchUrlString(
            smsUrl,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } else {
          // Fallback to intent URL for Android
          final String intentUrl = 'intent://send/$formattedNumber#Intent;scheme=smsto;package=com.android.mms;S.sms_body=${Uri.encodeComponent(message)};end';
          
          if (await canLaunchUrlString(intentUrl)) {
            await launchUrlString(
              intentUrl,
              mode: LaunchMode.externalNonBrowserApplication,
            );
          } else {
            print('Could not launch SMS for number: $formattedNumber');
          }
        }
      } else {
        // iOS and other platforms
        final Uri smsUri = Uri(
          scheme: 'sms',
          path: formattedNumber,
          queryParameters: {'body': message},
        );

        if (await canLaunchUrlString(smsUri.toString())) {
          await launchUrlString(
            smsUri.toString(),
            mode: LaunchMode.externalApplication,
          );
        }
      }
    } catch (e) {
      print('Error sending SMS to $phoneNumber: $e');
    }
  }

  // Always copy to clipboard as backup
  await Clipboard.setData(ClipboardData(text: message));
}


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ShowModelSafeHome(context);
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
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
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          height: 200,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(
                        "Send Location",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        "Send your location to your emergency contacts",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      leading: Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  "assets/share_location.png",
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
