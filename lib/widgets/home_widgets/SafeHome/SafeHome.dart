import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:telephony_sms/telephony_sms.dart';

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
                    // Show loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Sending location to contacts...')),
                    );

                    Position position = await _getCurrentLocation();
                    List<Map<String, dynamic>> favoriteContacts =
                        await _getFavoriteContacts();
                    List<String> phoneNumbers = favoriteContacts
                        .map((contact) => contact['phone'] as String)
                        .toList();

                    await _shareLocation(
                        position, phoneNumbers, context); // Added context here
                  } catch (e) {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                      ),
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



  Future<void> _shareLocation(Position position, List<String> phoneNumbers,
      BuildContext context) async {
    if (phoneNumbers.isEmpty) {
      throw 'No favorite contacts found';
    }

    final _telephonySMS = TelephonySMS();
    await _telephonySMS.requestPermission();

    String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    String message = 'Check out my current location: $googleMapsUrl';

    int sentCount = 0; // Count of successfully sent SMS
    int unsentCount = 0; // Count of SMS that failed to send

    for (String number in phoneNumbers) {
      String formattedNumber = number.replaceAll(RegExp(r'\s+'), '');
      if (!formattedNumber.startsWith('+')) {
        formattedNumber = '+91$formattedNumber'; // Assuming Indian numbers
      }

      print('Sending SMS to $formattedNumber');

      try {
        await _telephonySMS
            .sendSMS(
              phone: formattedNumber,
              message: message,
            )
            .timeout(
              Duration(seconds: 20),
              onTimeout: () => throw 'SMS timeout',
            );

        // If the message is sent successfully
        sentCount++;
        print('Message sent to $formattedNumber. Total sent: $sentCount');
      } catch (e) {
        // If there's an error, increment the unsent counter
        unsentCount++;
        print(
            'Failed to send SMS to $formattedNumber. Total unsent: $unsentCount');
      }

      // Optional: Delay between sending to avoid overwhelming the service
      await Future.delayed(Duration(milliseconds: 100));
    }
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
          height: 210,
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
