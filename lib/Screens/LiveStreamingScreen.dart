import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/LiveStream/StartStream.dart';
import 'package:chat_app/LiveStream/Streaming.dart';
import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Screens/AppDrawer.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/utils/settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:volume/volume.dart';

class LiveStreamingScreen extends StatefulWidget {
  LiveStreamingScreen({Key key}) : super(key: key);

  @override
  _LiveStreamingScreenState createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen>
    with AutomaticKeepAliveClientMixin<LiveStreamingScreen> {
  final auth = FirebaseAuth.instance;
  final storage = FirebaseFirestore.instance;
  AudioManager audioManager;
  int maxVol, currentVol;
  ShowVolumeUI showVolumeUI = ShowVolumeUI.HIDE;

  @override
  void initState() {
    super.initState();
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

  String generateRandomString(int len) {
    var r = Random();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  List<Widget> streamersList = [];

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;

    List<Widget> streamers = [];

    return Scaffold(
      backgroundColor: Color(0xFF13293D),
      appBar: AppBar(
        backgroundColor: Color(0xFF13293D),
        title: Text('Live Streams'),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: storage.collection('LiveStreams').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            streamers = [
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: width * 1 / 100, vertical: heigth * 1 / 100),
                child: InkWell(
                  onTap: () async {
                    var id = generateRandomString(16);

                    try {
                      await _handleCameraAndMic(Permission.microphone);
                      await _handleCameraAndMic(Permission.camera);

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => StartStream(
                                    role: Role,
                                    email: auth.currentUser.email,
                                    chennelId: id,
                                  )));

                      await storage
                          .collection('LiveStreams')
                          .doc(auth.currentUser.email)
                          .set({
                        'email': auth.currentUser.email,
                        'chennelId': id,
                      });
                    } catch (e) {}
                  },
                  child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(),
                        Container(),
                        Icon(
                          Icons.add,
                          size: size * 30 / 100,
                          color: Colors.white,
                        ),
                        Text(
                          'Start a stream',
                          style: TextStyle(
                              fontSize: size * 7 / 100,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Container(),
                      ],
                    ),
                    decoration: BoxDecoration(
                        color: Colors.cyan,
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        border: Border.all(
                          color: Colors.white,
                          //  width: width * 0.5 / 100
                        )),
                  ),
                ),
              ),
            ];

            for (var data in snapshot.data.docs) {
              var chennelId = data.data()['chennelId'];
              var streamerEmail = data.data()['email'];

              var widget = StreamBuilder<DocumentSnapshot>(
                  stream: storage
                      .collection('users')
                      .doc(data.data()['email'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        color: Colors.black,
                      );
                    }

                    var name = snapshot.data.data()['name'];

                    return (snapshot.data.data()['profilePic'] == '' ||
                            snapshot.data.data()['profilePic'] == null)
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: width * 1 / 100,
                                vertical: heigth * 1 / 100),
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                  color: Colors.black,
                                  image: DecorationImage(
                                      image: AssetImage('images/user1.png'),
                                      fit: BoxFit.cover)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                        bottom: heigth * 2 / 100),
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: size * 7 / 100),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                        : FutureBuilder(
                            future: FireStorageService.loadImage(
                                context, snapshot.data.data()['profilePic']),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                              return InkWell(
                                onTap: () async {
                                  try {
                                    await _handleCameraAndMic(
                                        Permission.microphone);
                                    await _handleCameraAndMic(
                                        Permission.camera);

                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => CallPage(
                                                  channelName: chennelId,
                                                  role: Role1,
                                                  email: streamerEmail,
                                                )));

                                    await storage
                                        .collection('LiveStreams')
                                        .doc(streamerEmail)
                                        .collection('Watchers')
                                        .doc(auth.currentUser.email)
                                        .set({'email': auth.currentUser.email});

                                    var aM = AudioManager.STREAM_MUSIC;

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
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: width * 1 / 100,
                                      vertical: heigth * 1 / 100),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20)),
                                        image: DecorationImage(
                                            image: CachedNetworkImageProvider(
                                                snapshot.data.toString()),
                                            fit: BoxFit.cover)),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                              left: width * 1 / 100,
                                              bottom: heigth * 2 / 100),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.55),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(20))),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                name,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: size * 6 / 100),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            });
                  });

              streamers.add(widget);
            }

            streamersList = streamers;

            return GridView.count(
              crossAxisCount: 2,
              childAspectRatio: (width * 40 / 100 / (heigth * 13 / 100) / 2),
              children: streamersList,
            );
          }),
      drawer: AppDrawer(),
    );
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
