import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/pages/call.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:volume/volume.dart';

class CallerScreen1 extends StatefulWidget {
  CallerScreen1({
    Key key,
    this.chennelId,
    this.userData,
  }) : super(key: key);

  var chennelId;

  var userData;

  @override
  _CallerScreen1State createState() => _CallerScreen1State();
}

class _CallerScreen1State extends State<CallerScreen1> {
  final _channelController = TextEditingController();

  bool _validateError = false;

  ClientRole _role = ClientRole.Broadcaster;

  Stream<DocumentSnapshot> callInfo;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // FirebaseAuth auth = FirebaseAuth.instance;

  bool isPicked = false;
  bool isDeclined = false;
  bool isAudio = false;

  AudioManager audioManager;
  int maxVol, currentVol;
  ShowVolumeUI showVolumeUI = ShowVolumeUI.HIDE;

  var caller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    callInfo =
        firestore.collection('VideoCalls').doc(widget.chennelId).snapshots();
    assignValues(info: callInfo);

    //  audioManager = AudioManager.STREAM_SYSTEM;
    // initAudioStreamType();
    // updateVolumes();
    volumeController();
  }

  volumeController() {
    try {
      audioManager = AudioManager.STREAM_SYSTEM;
      initAudioStreamType();
      updateVolumes();
    } catch (e) {}
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

    var aM = AudioManager.STREAM_VOICE_CALL;
    if (mounted)
      setState(() {
        audioManager = aM;
      });
    await Volume.controlVolume(aM);

    var expectedVolume = maxVol / 2;
    setVol(expectedVolume.toInt());
    updateVolumesAfter();
  }

  updateVolumesAfter() async {
    // get Max Volume
    maxVol = await Volume.getMaxVol;
    // get Current Volume
    currentVol = await Volume.getVol;
    setState(() {});
  }

  setVol(int i) async {
    await Volume.setVol(i, showVolumeUI: showVolumeUI);
  }

  assignValues({var info}) {
    try {
      callInfo.listen((snapshot) {
        if (mounted) {
          setState(() {
            isPicked = snapshot.data()['isPicked'];
            isDeclined = snapshot.data()['isDeclined'];
            isAudio = snapshot.data()['isAudio'];
            caller = snapshot.data()['caller'];
          });
        }
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var size = (height + width) / 2;

    if (isPicked && !isDeclined)
      return CallPage(
        channelName: widget.chennelId,
        role: _role,
        audioCall: isAudio,
        callerEmail: caller,
        pic: widget.userData['profilePic'],
        name: widget.userData['name'],
      );
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        try {
          await firestore
              .collection('VideoCalls')
              .doc(widget.chennelId)
              .delete();
        } catch (e) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: Material(
          child: Container(
            color: Colors.black,
            height: height,
            width: width,
            child: Stack(
              children: [
                (widget.userData['profilePic'] == '')
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
                            context, widget.userData['profilePic']),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: height * 12 / 100),
                      child: Column(
                        children: [
                          Text(
                            widget.userData['name'],
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: size * 7 / 100,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: height * 2 / 100,
                          ),
                          Text(
                            (isDeclined)
                                ? "call has ended."
                                : "waiting for reply...",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: size * 3.2 / 100,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: height * 12 / 100),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              InkWell(
                                onTap: () async {
                                  Navigator.pop(context);
                                  try {
                                    await firestore
                                        .collection('VideoCalls')
                                        .doc(widget.chennelId)
                                        .delete();
                                  } catch (e) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: Material(
                                  color: Colors.red,
                                  elevation: 8,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(100)),
                                  child: Container(
                                    height: height * 10 / 100,
                                    width: width * 20 / 100,
                                    child: Icon(
                                      Icons.call_end,
                                      color: Colors.white,
                                      size: size * 7 / 100,
                                    ),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(100))),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: height * 1 / 100,
                              ),
                              Text(
                                (isDeclined) ? "Go Back" : "Decline",
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> onJoin() async {
    // update input validation
    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });
    if (_channelController.text.isNotEmpty) {
      // await for camera and mic permissions before pushing video page
      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      // push video page with given channel name
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPage(
            channelName: _channelController.text,
            role: _role,
          ),
        ),
      );
    }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }
}
