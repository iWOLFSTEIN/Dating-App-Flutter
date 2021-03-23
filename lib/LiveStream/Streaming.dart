import 'package:chat_app/Services/FirebaseUserData.dart';
import 'package:chat_app/utils/settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
// import 'package:flutter/material.dart';

class CallPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String channelName;

  /// non-modifiable client role of the page
  final ClientRole role;

  final email;

  /// Creates a call page with given channel name.
  const CallPage({Key key, this.channelName, this.role, this.email})
      : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  RtcEngine _engine;

  var comment = TextEditingController();

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  Stream<DocumentSnapshot> streamerData;

  var streamerName;

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();

    streamerData = firestore.collection('users').doc(widget.email).snapshots();
    // db.streamUserData(email: widget.email);

    streamerData.listen((event) {
      setState(() {
        streamerName = event.data()['name'];
      });
    });
  }

  Future<void> initialize() async {
    if (APP_ID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await _engine.enableWebSdkInteroperability(true);
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(1920, 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(null, widget.channelName, null, 0);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(APP_ID);
    await _engine.enableVideo();
    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role);
    await _engine.setEnableSpeakerphone(true);
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(error: (code) {
      setState(() {
        final info = 'onError: $code';
        _infoStrings.add(info);
      });
    }, joinChannelSuccess: (channel, uid, elapsed) {
      setState(() {
        final info = 'onJoinChannel: $channel, uid: $uid';
        _infoStrings.add(info);
      });
    }, leaveChannel: (stats) {
      setState(() {
        _infoStrings.add('onLeaveChannel');
        _users.clear();
      });
    }, userJoined: (uid, elapsed) {
      setState(() {
        final info = 'userJoined: $uid';
        _infoStrings.add(info);
        _users.add(uid);
      });
    }, userOffline: (uid, elapsed) {
      setState(() {
        final info = 'userOffline: $uid';
        _infoStrings.add(info);
        _users.remove(uid);
      });
    }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
      setState(() {
        final info = 'firstRemoteVideo: $uid ${width}x $height';
        _infoStrings.add(info);
      });
    }));
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRole.Broadcaster) {
      list.add(RtcLocalView.SurfaceView());
    }
    _users.forEach((int uid) => list.add(RtcRemoteView.SurfaceView(uid: uid)));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[_videoView(views[0])],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]])
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 3))
          ],
        ));
      case 4:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 4))
          ],
        ));
      default:
    }
    return Container();
  }

  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  final userData = FirebaseGetUserData();

  /// Toolbar layout
  Widget _toolbar({var height, var width}) {
    if (widget.role == ClientRole.Audience) {
      return Container(
        //color: Colors.white,
        // alignment: Alignment.bottomCenter,
        padding: EdgeInsets.symmetric(
            vertical: height * 1.7 / 100, horizontal: width * 2.5 / 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('LiveStreams')
                    .doc(widget.email)
                    .collection('Likes')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  if (snapshot.data.docs == null) {
                    return Text(
                      '👍 0 likes',
                      style: TextStyle(color: Colors.white.withOpacity(0.4)),
                    );
                  }

                  var counter = 0;
                  for (var data in snapshot.data.docs) {
                    counter++;
                  }
                  return Text(
                    '👍 $counter likes',
                    style: TextStyle(color: Colors.white.withOpacity(0.4)),
                  );
                }),
            SizedBox(
              height: height * 1 / 100,
            ),
            Row(
              children: [
                StreamBuilder<DocumentSnapshot>(
                    stream: firestore
                        .collection('LiveStreams')
                        .doc(widget.email)
                        .collection('Likes')
                        .doc(auth.currentUser.email)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                          child: Icon(
                            Icons.thumb_up_alt_outlined,
                            size: ((MediaQuery.of(context).size.height +
                                        MediaQuery.of(context).size.width) /
                                    2) *
                                6 /
                                100,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        );
                      }
                      if (snapshot.data.data() == null) {
                        return Container(
                          child: InkWell(
                            onTap: () async {
                              try {
                                await firestore
                                    .collection('LiveStreams')
                                    .doc(widget.email)
                                    .collection('Likes')
                                    .doc(auth.currentUser.email)
                                    .set({'email': auth.currentUser.email});
                              } catch (e) {}
                            },
                            child: Icon(
                              Icons.thumb_up_alt_outlined,
                              size: ((MediaQuery.of(context).size.height +
                                          MediaQuery.of(context).size.width) /
                                      2) *
                                  6 /
                                  100,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        );
                      }
                      return Container(
                        child: InkWell(
                          onTap: () async {
                            try {
                              await firestore
                                  .collection('LiveStreams')
                                  .doc(widget.email)
                                  .collection('Likes')
                                  .doc(auth.currentUser.email)
                                  .delete();
                            } catch (e) {}
                          },
                          child: Icon(
                            Icons.thumb_up_alt,
                            size: ((MediaQuery.of(context).size.height +
                                        MediaQuery.of(context).size.width) /
                                    2) *
                                6 /
                                100,
                            color: Colors.blue,
                          ),
                        ),
                      );
                    }),
                SizedBox(
                  width: width * 1 / 100,
                ),
                Expanded(
                  child: Container(
                    // height: MediaQuery.of(context).size.height * 7 / 100,
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.4)),
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            bottomLeft: Radius.circular(50))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 1.0, horizontal: 10),
                      child: TextField(
                        controller: comment,
                        style: TextStyle(color: Colors.white),
                        autocorrect: false,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintText: 'write something',
                            hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.4))),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: width * 1 / 100,
                ),
                StreamBuilder<FirebaseUserData>(
                    stream:
                        userData.streamUserData(email: auth.currentUser.email),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }
                      return Container(
                        height: MediaQuery.of(context).size.height * 6.3 / 100,
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4)),
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(50),
                                bottomRight: Radius.circular(50))),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: width * 2.2 / 100),
                          child: InkWell(
                            onTap: () async {
                              var timestamp = DateTime.now();

                              if (!(comment.text == null ||
                                  comment.text == '')) {
                                var myComment = comment.text;

                                comment.text = '';

                                await firestore
                                    .collection('LiveStreams')
                                    .doc(widget.email)
                                    .collection('Comments')
                                    .add({
                                  'name': snapshot.data.name,
                                  'text': myComment,
                                  'timestamp': timestamp
                                });
                              }
                            },
                            child: Icon(
                              Icons.send,
                              color: Colors.white.withOpacity(0.4),
                              size: ((MediaQuery.of(context).size.height +
                                          MediaQuery.of(context).size.width) /
                                      2) *
                                  4.5 /
                                  100,
                            ),
                          ),
                        ),
                      );
                    })
              ],
            ),
          ],
        ),
      );
    }
    //  return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('LiveStreams')
                  .doc(widget.email)
                  .collection('Likes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container();
                }
                if (snapshot.data.docs == null) {
                  return Padding(
                    padding: EdgeInsets.only(left: width * 2 / 100),
                    child: Text(
                      '👍 0 likes',
                      style: TextStyle(color: Colors.white.withOpacity(0.4)),
                    ),
                  );
                }

                var counter = 0;
                for (var data in snapshot.data.docs) {
                  counter++;
                }
                return Padding(
                  padding: EdgeInsets.only(left: width * 2 / 100),
                  child: Text(
                    '👍 $counter likes',
                    style: TextStyle(color: Colors.white.withOpacity(0.4)),
                  ),
                );
              }),
          SizedBox(
            height: height * 1 / 100,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RawMaterialButton(
                onPressed: _onToggleMute,
                child: Icon(
                  muted ? Icons.mic_off : Icons.mic,
                  color: muted ? Colors.white : Colors.blueAccent,
                  size: 20.0,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: muted ? Colors.blueAccent : Colors.white,
                padding: const EdgeInsets.all(12.0),
              ),
              RawMaterialButton(
                onPressed: () => _onCallEnd(context),
                child: Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 35.0,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.redAccent,
                padding: const EdgeInsets.all(15.0),
              ),
              RawMaterialButton(
                onPressed: _onSwitchCamera,
                child: Icon(
                  Icons.switch_camera,
                  color: Colors.blueAccent,
                  size: 20.0,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.white,
                padding: const EdgeInsets.all(12.0),
              )
            ],
          ),
        ],
      ),
    );
  }

  /// Info panel to show logs
  Widget _panel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: ListView.builder(
            reverse: true,
            itemCount: _infoStrings.length,
            itemBuilder: (BuildContext context, int index) {
              if (_infoStrings.isEmpty) {
                return null;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellowAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _infoStrings[index],
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  final storage = FirebaseFirestore.instance;
  //final auth = FirebaseAuth.instance;
  void _onCallEnd(BuildContext context) async {
    try {
      Navigator.pop(context);

      await firestore
          .collection('LiveStreams')
          .doc(auth.currentUser.email)
          .collection('Comments')
          .get()
          .then((snapshot) {
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
      });

      await storage
          .collection('LiveStreams')
          .doc(widget.email)
          .collection('Watchers')
          .get()
          .then((snapshot) {
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
      });

      await storage
          .collection('LiveStreams')
          .doc(widget.email)
          .collection('Likes')
          .get()
          .then((snapshot) {
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
      });

      await firestore
          .collection('LiveStreams')
          .doc(auth.currentUser.email)
          .delete();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  FirebaseGetUserData db = FirebaseGetUserData();
  bool isWatching = false;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    var size = (height + width) / 2;
    return WillPopScope(
      onWillPop: () async {
        try {
          if (auth.currentUser.email == widget.email) {
            Navigator.pop(context);

            await firestore
                .collection('LiveStreams')
                .doc(auth.currentUser.email)
                .collection('Comments')
                .get()
                .then((snapshot) {
              for (DocumentSnapshot ds in snapshot.docs) {
                ds.reference.delete();
              }
            });

            await storage
                .collection('LiveStreams')
                .doc(widget.email)
                .collection('Watchers')
                .get()
                .then((snapshot) {
              for (DocumentSnapshot ds in snapshot.docs) {
                ds.reference.delete();
              }
            });

            await firestore
                .collection('LiveStreams')
                .doc(auth.currentUser.email)
                .delete();
          } else {
            Navigator.pop(context);
            await storage
                .collection('LiveStreams')
                .doc(widget.email)
                .collection('Watchers')
                .doc(auth.currentUser.email)
                .delete();
          }
        } catch (e) {}
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text((streamerName == null) ? '...' : streamerName),
        ),
        body: Center(
          child: Stack(
            children: <Widget>[
              _viewRows(),
              Container(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: (widget.role == ClientRole.Broadcaster)
                          ? height * 15 / 100
                          : height * 12 / 100,
                      left: width * 2 / 100),
                  child: StreamBuilder<QuerySnapshot>(
                      stream: firestore
                          .collection('LiveStreams')
                          .doc(widget.email)
                          .collection('Comments')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container();
                        }

                        var comments = snapshot.data.docs;
                        List<Widget> widgetList = [];
                        for (var comment in comments) {
                          final name = comment.data()['name'];
                          final text = comment.data()['text'];

                          widgetList.add(Padding(
                            padding:
                                EdgeInsets.only(bottom: height * 1.2 / 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.cyan),
                                ),
                                SizedBox(
                                  height: height * 0.2 / 100,
                                ),
                                Text(
                                  text,
                                  style: TextStyle(color: Colors.white),
                                )
                              ],
                            ),
                          ));
                        }

                        return Container(
                          height: height * 40 / 100,
                          width: width * 60 / 100,
                          child: ListView(
                            reverse: true,
                            children: widgetList,
                          ),
                        );
                      }),
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                      top: height * 4 / 100, left: width * 2 / 100),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 1000),
                        padding: EdgeInsets.only(
                            bottom: height * 0.2 / 100,
                            top: height * 0.2 / 100,
                            left: width * 1.7 / 100,
                            right: width * 2.5 / 100),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius:
                                BorderRadius.all(Radius.circular(50))),
                        child: StreamBuilder<QuerySnapshot>(
                            stream: firestore
                                .collection('LiveStreams')
                                .doc(widget.email)
                                .collection('Watchers')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return (!isWatching)
                                    ? GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isWatching = !isWatching;
                                          });
                                        },
                                        child: Icon(Icons.remove_red_eye,
                                            color:
                                                Colors.white.withOpacity(0.6)),
                                      )
                                    : GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isWatching = !isWatching;
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            Icon(Icons.remove_red_eye,
                                                color: Colors.white
                                                    .withOpacity(0.6)),
                                            SizedBox(
                                              width: width * 1 / 100,
                                            ),
                                            Text('0 watching',
                                                style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    fontWeight:
                                                        FontWeight.bold))
                                          ],
                                        ),
                                      );
                              }
                              if (snapshot.data.docs == null) {
                                return (!isWatching)
                                    ? GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isWatching = !isWatching;
                                          });
                                        },
                                        child: Icon(Icons.remove_red_eye,
                                            color:
                                                Colors.white.withOpacity(0.6)),
                                      )
                                    : GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isWatching = !isWatching;
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            Icon(Icons.remove_red_eye,
                                                color: Colors.white
                                                    .withOpacity(0.6)),
                                            SizedBox(
                                              width: width * 1 / 100,
                                            ),
                                            Text('0 watching',
                                                style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    fontWeight:
                                                        FontWeight.bold))
                                          ],
                                        ),
                                      );
                              }

                              var counter = 0;
                              for (var data in snapshot.data.docs) {
                                counter++;
                              }
                              return (!isWatching)
                                  ? GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isWatching = !isWatching;
                                        });
                                      },
                                      child: Icon(Icons.remove_red_eye,
                                          color: Colors.white.withOpacity(0.6)),
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isWatching = !isWatching;
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.remove_red_eye,
                                              color: Colors.white
                                                  .withOpacity(0.6)),
                                          SizedBox(
                                            width: width * 1 / 100,
                                          ),
                                          Text('$counter watching',
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.6),
                                                  fontWeight: FontWeight.bold))
                                        ],
                                      ),
                                    );
                            }),
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
                ),
              ),
              _toolbar(height: height, width: width),
            ],
          ),
        ),
      ),
    );
  }
}
