import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Navigations/PagesNavController.dart';
import 'package:chat_app/Screens/ConversationScreen.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/pages/call.dart';
import 'package:chat_app/utils/settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:volume/volume.dart';

class ReceiverScreen extends StatefulWidget {
  ReceiverScreen({
    Key key,
    this.screen,
    this.callData,
    this.callerEmail,
  }) : super(key: key);

  String screen;

  var callData;

  var callerEmail;

  @override
  _ReceiverScreenState createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  AudioManager audioManager;
  int maxVol, currentVol;
  ShowVolumeUI showVolumeUI = ShowVolumeUI.HIDE;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if (widget.callData != null)
      setState(() {
        callerEmail = widget.callData['caller'];
        chennelId = widget.callData['chennelId'];
        isPicked = widget.callData['isPicked'];
        isDeclined = widget.callData['isDeclined'];
        isAudio = widget.callData['isAudio'];
        receiverEmail = widget.callData['receiver'];
      });
    audioManager = AudioManager.STREAM_SYSTEM;
    initAudioStreamType();
    updateVolumes();
  }

  Future<void> initAudioStreamType() async {
    await Volume.controlVolume(AudioManager.STREAM_SYSTEM);
  }

  updateVolumes() async {
    // get Max Volume
    maxVol = await Volume.getMaxVol;
    // get Current Volume
    currentVol = await Volume.getVol;
    if (mounted) setState(() {});
  }

  setVol(int i) async {
    await Volume.setVol(i, showVolumeUI: showVolumeUI);
  }

  var callerEmail;
  var chennelId;
  var isPicked = false;
  var isDeclined = false;
  var isAudio = false;
  var receiverEmail;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var size = (height + width) / 2;

    return WillPopScope(
      onWillPop: () async {
        if (widget.screen == 'PagesNavController')
          Navigator.pushAndRemoveUntil(
              context, FadePageRoute(PagesNavController()), (route) => false);
        else if (widget.screen == 'ConversationScreen')
          Navigator.pushAndRemoveUntil(
              context, FadePageRoute(ConversationScreen()), (route) => false);

        try {
          if (chennelId != null) {
            final snapshot =
                await firestore.collection('VideoCalls').doc(chennelId).get();

            if (snapshot.exists) {
              await firestore.collection('VideoCalls').doc(chennelId).update({
                'isDeclined': true,
                'receiver': null,
              });
            }
          }
        } catch (e) {}
      },
      child: Scaffold(
        body: StreamBuilder<DocumentSnapshot>(
            stream: firestore
                .collection('users')
                .doc(widget.callerEmail)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  height: height,
                  width: width,
                  color: Colors.black,
                  child: Center(
                    child: Text(
                      'Someone is calling...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: size * 3.2 / 100,
                      ),
                    ),
                  ),
                );
              }

              var callUserData = snapshot.data.data();

              return Material(
                child: Container(
                  color: Colors.black,
                  height: height,
                  width: width,
                  child: Stack(
                    children: [
                      (snapshot.data.data()['profilePic'] == '')
                          ? Container(
                              height: height,
                              width: width,
                              child: Image.asset(
                                'images/user1.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : FutureBuilder(
                              //  stream: null,
                              future: FireStorageService.loadImage(
                                  context,
                                  // callerData['profilePic']
                                  snapshot.data.data()['profilePic']

                                  // widget.callerEmail['profilePic'],
                                  ),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Container(
                                    height: height,
                                    width: width,
                                    color: Colors.black,
                                  );
                                }

                                return Container(
                                  height: height,
                                  width: width,
                                  child: Image.network(
                                    snapshot.data.toString(),
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }),
                      Container(
                        height: height,
                        width: width,
                        color: Colors.black.withOpacity(0.65),
                      ),
                      Column(
                        // crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: height * 12 / 100),
                            child: Column(
                              children: [
                                Text(
                                  snapshot.data.data()['name'],
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: size * 7 / 100,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  height: height * 1 / 100,
                                ),
                                StreamBuilder<DocumentSnapshot>(
                                    stream: firestore
                                        .collection('VideoCalls')
                                        .doc(chennelId)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return Container();
                                      }
                                      if (snapshot.data.data() == null) {
                                        return Text(
                                          'call has ended.',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: size * 3.2 / 100,
                                          ),
                                        );
                                      }
                                      return Text(
                                        "is calling you..",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: size * 3.2 / 100,
                                        ),
                                      );
                                    }),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: height * 12 / 100),
                            child: StreamBuilder<DocumentSnapshot>(
                                stream: firestore
                                    .collection('VideoCalls')
                                    .doc(chennelId)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Container();
                                  }

                                  if (snapshot.data.data() == null) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
                                            InkWell(
                                              onTap: () async {
                                                if (widget.screen ==
                                                    'PagesNavController')
                                                  Navigator.pushAndRemoveUntil(
                                                      context,
                                                      FadePageRoute(
                                                          PagesNavController()),
                                                      (route) => false);
                                                else if (widget.screen ==
                                                    'ConversationScreen')
                                                  Navigator.pushAndRemoveUntil(
                                                      context,
                                                      FadePageRoute(
                                                          ConversationScreen()),
                                                      (route) => false);
                                              },
                                              child: Material(
                                                color: Colors.red,
                                                elevation: 8,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(100)),
                                                child: Container(
                                                  height: height * 10 / 100,
                                                  width: width * 20 / 100,
                                                  child: Icon(
                                                    Icons.call_end,
                                                    color: Colors.white,
                                                    size: size * 7 / 100,
                                                  ),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  100))),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: height * 1 / 100,
                                            ),
                                            Text(
                                              "Go Back",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            )
                                          ],
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: width * 16 / 100,
                                      ),
                                      Column(
                                        children: [
                                          InkWell(
                                            onTap: () async {
                                              if (widget.screen ==
                                                  'PagesNavController')
                                                Navigator.pushAndRemoveUntil(
                                                    context,
                                                    FadePageRoute(
                                                        PagesNavController()),
                                                    (route) => false);
                                              else if (widget.screen ==
                                                  'ConversationScreen')
                                                Navigator.pushAndRemoveUntil(
                                                    context,
                                                    FadePageRoute(
                                                        ConversationScreen()),
                                                    (route) => false);

                                              try {
                                                await firestore
                                                    .collection('VideoCalls')
                                                    .doc(chennelId)
                                                    .update({
                                                  'isDeclined': true,
                                                  'receiver': null,
                                                });
                                              } catch (e) {}
                                            },
                                            child: Material(
                                              color: Colors.red,
                                              elevation: 8,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(100)),
                                              child: Container(
                                                height: height * 10 / 100,
                                                width: width * 20 / 100,
                                                child: Icon(
                                                  Icons.call_end,
                                                  color: Colors.white,
                                                  size: size * 7 / 100,
                                                ),
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                100))),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: height * 1 / 100,
                                          ),
                                          Text(
                                            "Decline",
                                            style:
                                                TextStyle(color: Colors.white),
                                          )
                                        ],
                                      ),
                                      Expanded(
                                        child: SizedBox(),
                                      ),
                                      Column(
                                        children: [
                                          InkWell(
                                            onTap: () async {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          CallPage(
                                                            channelName:
                                                                chennelId,
                                                            audioCall: isAudio,
                                                            role: Role,
                                                            screen:
                                                                widget.screen,
                                                            pic: callUserData[
                                                                'profilePic'],
                                                            name: callUserData[
                                                                'name'],
                                                            callerEmail:
                                                                callerEmail,
                                                          )));

                                              try {
                                                await _handleCameraAndMic(
                                                    Permission.camera);
                                                await _handleCameraAndMic(
                                                    Permission.microphone);

                                                await firestore
                                                    .collection('VideoCalls')
                                                    .doc(chennelId)
                                                    .update({
                                                  'isPicked': true,
                                                });

                                                var aM = AudioManager
                                                    .STREAM_VOICE_CALL;
                                                if (mounted)
                                                  setState(() {
                                                    audioManager = aM;
                                                  });
                                                await Volume.controlVolume(aM);

                                                var expectedVolume = maxVol / 2;
                                                setVol(expectedVolume.toInt());
                                                updateVolumes();
                                              } catch (e) {}
                                            },
                                            child: Material(
                                              color: Colors.green,
                                              elevation: 8,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(100)),
                                              child: Container(
                                                height: height * 10 / 100,
                                                width: width * 20 / 100,
                                                child: Icon(
                                                  Icons.call,
                                                  color: Colors.white,
                                                  size: size * 7 / 100,
                                                ),
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                100))),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: height * 1 / 100,
                                          ),
                                          Text(
                                            "Accept",
                                            style:
                                                TextStyle(color: Colors.white),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        width: width * 16 / 100,
                                      ),
                                    ],
                                  );
                                }),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }
}
