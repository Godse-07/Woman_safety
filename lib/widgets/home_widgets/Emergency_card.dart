import 'package:flutter/cupertino.dart';
import 'package:safe_circle/widgets/home_widgets/emergencies/ambulence_emergency.dart';
import 'package:safe_circle/widgets/home_widgets/emergencies/fire_brigade.dart';
import 'package:safe_circle/widgets/home_widgets/emergencies/police_emergency.dart';

class EmergencyCard extends StatelessWidget {
  const EmergencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          PoliceEmergencyCard(),
          AmbulanceEmergency(),
          FireBrigadeEmergency(),
        ],
      ),
    );
  }
}
