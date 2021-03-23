import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Navigations/PagesNavController.dart';
import 'package:chat_app/Screens/ConversationScreen.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/pages/ReceiverScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/settings.dart';

class CallPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String channelName;

  final callerEmail;

  /// non-modifiable client role of the page
  final ClientRole role;

  final audioCall;

  final String screen;

  final pic;

  final name;

  //final userData;

  /// Creates a call page with given channel name.
  const CallPage({
    Key key,
    this.channelName,
    //  this.userData,
    this.role,
    this.callerEmail,
    this.pic,
    this.name,
    this.audioCall,
    this.screen,
  }) : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  RtcEngine _engine;

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk

    initialize();
    _timeString = "00:00:00";
    Timer.periodic(Duration(seconds: 1), (Timer t) => _getCurrentTime());
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
    //(widget.audioCall == null)
    // ?
    (widget.audioCall)
        ? await _engine.disableVideo()
        : await _engine.enableVideo();
    // : await _engine.disableVideo();
    _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role);
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

  Widget _toolbar() {
    if (widget.role == ClientRole.Audience) return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
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

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  void _onCallEnd(BuildContext context) async {
    if (!(auth.currentUser.email == widget.callerEmail)) {
      if (widget.screen == 'PagesNavController') {
        Navigator.pushAndRemoveUntil(_scaffoldKey.currentContext,
            FadePageRoute(PagesNavController()), (route) => false);
      } else if (widget.screen == 'ConversationScreen') {
        Navigator.pushAndRemoveUntil(_scaffoldKey.currentContext,
            FadePageRoute(ConversationScreen()), (route) => false);
      } else if (widget.screen == null) {
        Navigator.pop(_scaffoldKey.currentContext);
      }

      try {
        await firestore
            .collection('VideoCalls')
            .doc(widget.channelName)
            .update({
          'isDeclined': true,
          'receiver': null,
        });
      } catch (e) {}
    } else {
      if (widget.screen == 'PagesNavController') {
        Navigator.pushAndRemoveUntil(_scaffoldKey.currentContext,
            FadePageRoute(PagesNavController()), (route) => false);
      } else if (widget.screen == 'ConversationScreen') {
        Navigator.pushAndRemoveUntil(_scaffoldKey.currentContext,
            FadePageRoute(ConversationScreen()), (route) => false);
      } else if (widget.screen == null) {
        Navigator.pop(_scaffoldKey.currentContext);
      }

      try {
        await firestore
            .collection('VideoCalls')
            .doc(widget.channelName)
            .delete();
      } catch (e) {}
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _timeString;
  void _getCurrentTime() {
    DateTime dt =
        DateTime.parse('2021-01-02 ' + _timeString).add(Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _timeString = "$dt".split(' ')[1].split('.')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var size = (height + width) / 2;

    return (!(auth.currentUser.email == widget.callerEmail))
        ? StreamBuilder<DocumentSnapshot>(
            stream: firestore
                .collection('VideoCalls')
                .doc(widget.channelName)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  height: height,
                  width: width,
                  color: Colors.black,
                );
              }

              if (snapshot.data.data() == null) {
                return ReceiverScreen(
                  screen: widget.screen,
                  callerEmail: widget.callerEmail,
                );
              }

              return WillPopScope(
                onWillPop: () async {
                  if (!(auth.currentUser.email == widget.callerEmail)) {
                    if (widget.screen == 'PagesNavController') {
                      Navigator.pushAndRemoveUntil(
                          _scaffoldKey.currentContext,
                          FadePageRoute(PagesNavController()),
                          (route) => false);
                    } else if (widget.screen == 'ConversationScreen') {
                      Navigator.pushAndRemoveUntil(
                          _scaffoldKey.currentContext,
                          FadePageRoute(ConversationScreen()),
                          (route) => false);
                    } else if (widget.screen == null) {
                      Navigator.pop(_scaffoldKey.currentContext);
                    }

                    try {
                      await firestore
                          .collection('VideoCalls')
                          .doc(widget.channelName)
                          .update({
                        'isDeclined': true,
                        'receiver': null,
                      });
                    } catch (e) {}
                  } else {
                    if (widget.screen == 'PagesNavController') {
                      Navigator.pushAndRemoveUntil(
                          _scaffoldKey.currentContext,
                          FadePageRoute(PagesNavController()),
                          (route) => false);
                    } else if (widget.screen == 'ConversationScreen') {
                      Navigator.pushAndRemoveUntil(
                          _scaffoldKey.currentContext,
                          FadePageRoute(ConversationScreen()),
                          (route) => false);
                    } else if (widget.screen == null) {
                      Navigator.pop(_scaffoldKey.currentContext);
                    }

                    try {
                      await firestore
                          .collection('VideoCalls')
                          .doc(widget.channelName)
                          .delete();
                    } catch (e) {}
                  }
                },
                child: Scaffold(
                  key: _scaffoldKey,
                  appBar: AppBar(
                    backgroundColor: Colors.black,
                    title: Text(widget.name),
                  ),
                  backgroundColor: Colors.black,
                  body: Center(
                    child: Stack(
                      children: <Widget>[
                        (widget.audioCall)
                            ? Stack(
                                children: [
                                  (widget.pic == '')
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
                                              context, widget.pic),
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
                                    color: Colors.black.withOpacity(0.6),
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          top: height * 5.5 / 100),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Ongoing call...',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: size * 6 / 100,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(
                                            height: height * 1.7 / 100,
                                          ),
                                          Text(
                                            (_timeString == null)
                                                ? '00:00:00'
                                                : _timeString,
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontSize: size * 3.2 / 100,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _viewRows(),
                        _toolbar(),
                      ],
                    ),
                  ),
                ),
              );
            })
        : WillPopScope(
            onWillPop: () async {
              if (!(auth.currentUser.email == widget.callerEmail)) {
                if (widget.screen == 'PagesNavController') {
                  Navigator.pushAndRemoveUntil(_scaffoldKey.currentContext,
                      FadePageRoute(PagesNavController()), (route) => false);
                } else if (widget.screen == 'ConversationScreen') {
                  Navigator.pushAndRemoveUntil(_scaffoldKey.currentContext,
                      FadePageRoute(ConversationScreen()), (route) => false);
                } else if (widget.screen == null) {
                  Navigator.pop(_scaffoldKey.currentContext);
                }

                try {
                  await firestore
                      .collection('VideoCalls')
                      .doc(widget.channelName)
                      .update({
                    'isDeclined': true,
                    'receiver': null,
                  });
                } catch (e) {}
              } else {
                if (widget.screen == 'PagesNavController') {
                  Navigator.pushAndRemoveUntil(_scaffoldKey.currentContext,
                      FadePageRoute(PagesNavController()), (route) => false);
                } else if (widget.screen == 'ConversationScreen') {
                  Navigator.pushAndRemoveUntil(_scaffoldKey.currentContext,
                      FadePageRoute(ConversationScreen()), (route) => false);
                } else if (widget.screen == null) {
                  Navigator.pop(_scaffoldKey.currentContext);
                }

                try {
                  await firestore
                      .collection('VideoCalls')
                      .doc(widget.channelName)
                      .delete();
                } catch (e) {}
              }
            },
            child: Scaffold(
              key: _scaffoldKey,
              appBar: AppBar(
                backgroundColor: Colors.black,
                title: Text(widget.name),
              ),
              backgroundColor: Colors.black,
              body: Center(
                child: Stack(
                  children: <Widget>[
                    (widget.audioCall)
                        ? Stack(
                            children: [
                              (widget.pic == '')
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
                                          context, widget.pic),
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
                                color: Colors.black.withOpacity(0.6),
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(top: height * 5.5 / 100),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Ongoing call...',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: size * 6 / 100,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        height: height * 1.7 / 100,
                                      ),
                                      Text(
                                        (_timeString == null)
                                            ? '00:00:00'
                                            : _timeString,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: size * 3.2 / 100,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _viewRows(),
                    _toolbar(),
                  ],
                ),
              ),
            ),
          );
  }
}
