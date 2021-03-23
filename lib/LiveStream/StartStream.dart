// import 'dart:html';
import 'package:permission_handler/permission_handler.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/LiveStream/Streaming.dart';

class StartStream extends StatelessWidget {
  StartStream({Key key, this.email, this.role, this.chennelId})
      : super(key: key);

  // final auth = FirebaseAuth.instance;
  final chennelId;
  final role;
  final email;
  final storage = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;
    return StreamBuilder<DocumentSnapshot>(
        stream: storage.collection('LiveStreams').doc(email).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Material(
              child: Container(
                height: heigth,
                width: width,
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Starting the stream',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      height: heigth * 1 / 100,
                    ),
                    SleekCircularSlider(
                        appearance: CircularSliderAppearance(
                      spinnerMode: true,
                    )),
                  ],
                ),
              ),
            );
          }

          return CallPage(
            role: role,
            channelName: chennelId,
            email: email,
          );
        });
  }
}
