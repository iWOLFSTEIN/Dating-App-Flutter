import 'dart:math';
import 'package:provider/provider.dart';
//import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Screens/ConversationScreen.dart';
import 'package:chat_app/Screens/ImageViewerScreen.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/Services/FirebaseProfilePicsModel.dart';
import 'package:chat_app/pages/CallerScreen1.dart';
// import 'package:chat_app/pages/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:swipedetector/swipedetector.dart';
import 'package:chat_app/Services/DataProvider.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key key, this.userData}) : super(key: key);

  final userData;

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  var iconChanger = 0;
  var myBio =
      "I am the subzero the grandmaster of the linquei. You cannot match my skills. Release the girl beast.";

  FirebaseGetProfilePicsModel storage = FirebaseGetProfilePicsModel();
  FirebaseAuth auth = FirebaseAuth.instance;

  List<FutureBuilder> images = [];
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Stream<DocumentSnapshot> iBlockedStream;
  Stream<DocumentSnapshot> gotBlockedStream;

  bool iBlocked = false;
  bool gotBlocked = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    iBlockedStream = firestore
        .collection('Blocking')
        .doc(auth.currentUser.email)
        .collection('iBlocked')
        .doc(widget.userData['email'])
        .snapshots();

    iBlockedStreamData(iBlockedStreamEvent: iBlockedStream);

    gotBlockedStream = firestore
        .collection('Blocking')
        .doc(auth.currentUser.email)
        .collection('gotBlocked')
        .doc(widget.userData['email'])
        .snapshots();

    gotBlockedStreamData(gotBlockedStreamEvent: gotBlockedStream);
  }

  iBlockedStreamData({iBlockedStreamEvent}) {
    iBlockedStreamEvent.listen((event) {
      if (event.data() != null) {
        if (mounted) {
          setState(() {
            iBlocked = true;
          });
        }
      }
    });
  }

  gotBlockedStreamData({gotBlockedStreamEvent}) {
    gotBlockedStreamEvent.listen((event) {
      if (event.data() != null) {
        if (mounted) {
          setState(() {
            gotBlocked = true;
          });
        }
      }
    });
  }

  var index = 0;

  String generateRandomString(int len) {
    var r = Random();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  bool isCalling = false;
  // final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;

    // var dataProvider = Provider.of<DataProvider>(context);

    var icons = [
      Icon(
        Icons.favorite_border,
        color: Colors.white.withOpacity(0.6),
        size: size * 13 / 100,
      ),
      Icon(
        Icons.favorite,
        color: Colors.red,
        size: size * 13 / 100,
      ),
    ];

    return Scaffold(
      backgroundColor: Color(0xFF13293D),
      body: StreamBuilder<FirebaseProfilePicsModel>(
          stream: storage.streamUserData(email: widget.userData['email']),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            List<FutureBuilder> imagesList = [
              (iBlocked || gotBlocked)
                  ? FutureBuilder(
                      future: null,
                      builder: (context, snapshot) {
                        return Container(
                          width: width,
                          height: heigth / 1.5,
                          child: Image.asset(
                            'images/user1.png',
                            fit: BoxFit.cover,
                          ),
                        );
                      })
                  : FutureBuilder(
                      future: FireStorageService.loadImage(
                          context, widget.userData['profilePic']),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                              height: heigth / 1.5,
                              width: width,
                              child:
                                  Center(child: CircularProgressIndicator()));
                        }
                        return Container(
                          width: width,
                          height: heigth / 1.5,
                          child: CachedNetworkImage(
                            imageUrl: snapshot.data.toString(),
                            fit: BoxFit.cover,
                          ),
                        );
                      }),
            ];

            List imagesUrls = [];

            if (!(iBlocked || gotBlocked)) if (!(snapshot.data.otherPics == []))
              for (var image in snapshot.data.otherPics) {
                var imageBuilder = FutureBuilder(
                    future: FireStorageService.loadImage(context, image),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                            height: heigth / 1.5,
                            width: width,
                            child: Center(child: CircularProgressIndicator()));
                      }
                      return Container(
                        width: width,
                        height: heigth / 1.5,
                        child: CachedNetworkImage(
                          imageUrl: snapshot.data.toString(),
                          fit: BoxFit.cover,
                        ),
                      );
                    });

                imagesList.add(imageBuilder);
                imagesUrls.add(image);
              }

            images = imagesList;

            return ModalProgressHUD(
              inAsyncCall: isCalling,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: heigth / 1.5,
                    backgroundColor: Color(0xFF13293D),
                    // pinned: true,
                    actions: [
                      Padding(
                        padding: EdgeInsets.only(right: width * 3 / 100),
                        child: StreamBuilder<DocumentSnapshot>(
                            stream: firestore
                                .collection('Favorites')
                                .doc(auth.currentUser.email)
                                .collection('MyFavorites')
                                .doc(widget.userData['email'])
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return icons[0];
                              }
                              if (snapshot.data.data() == null) {
                                return GestureDetector(
                                    onTap: (iBlocked || gotBlocked)
                                        ? () {}
                                        : () async {
                                            // setState(() {
                                            //   iconChanger =
                                            //       (iconChanger == 0) ? 1 : 0;
                                            // });
                                            await firestore
                                                .collection('Favorites')
                                                .doc(auth.currentUser.email)
                                                .collection('MyFavorites')
                                                .doc(widget.userData['email'])
                                                .set(widget.userData);
                                          },
                                    child: icons[0]);
                              }
                              return GestureDetector(
                                  onTap: (iBlocked || gotBlocked)
                                      ? () {}
                                      : () async {
                                          // setState(() {
                                          //   iconChanger =
                                          //       (iconChanger == 0) ? 1 : 0;
                                          // });
                                          await firestore
                                              .collection('Favorites')
                                              .doc(auth.currentUser.email)
                                              .collection('MyFavorites')
                                              .doc(widget.userData['email'])
                                              .delete();
                                        },
                                  child: icons[1]);
                            }),
                      )
                    ],

                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        children: [
                          (widget.userData['profilePic'] == '' ||
                                  widget.userData['profilePic'] == null)
                              ? Container(
                                  width: double.infinity,
                                  height: heigth / 1.5,
                                  child: Image.asset(
                                    'images/user1.png',
                                    fit: BoxFit.cover,
                                  ))
                              : Container(
                                  height: heigth / 1.5,
                                  child: AnimatedSwitcher(
                                    duration: Duration(milliseconds: 300),
                                    child: IndexedStack(
                                      key: ValueKey<int>(index),
                                      index: index,
                                      children: images,
                                    ),
                                  )),
                          SwipeDetector(
                            onSwipeLeft: () {
                              if (index < images.length - 1)
                                setState(() {
                                  index++;
                                });
                            },
                            onSwipeRight: () {
                              if (index > 0)
                                setState(() {
                                  index--;
                                });
                            },
                            swipeConfiguration: SwipeConfiguration(
                                verticalSwipeMinVelocity: 100.0,
                                verticalSwipeMinDisplacement: 50.0,
                                verticalSwipeMaxWidthThreshold: 100.0,
                                horizontalSwipeMaxHeightThreshold: 50.0,
                                horizontalSwipeMinDisplacement: 50.0,
                                horizontalSwipeMinVelocity: 200.0),
                            child: Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              padding: EdgeInsets.only(
                                  left: width * 45 / 100,
                                  bottom: heigth * 52 / 100),
                              // constraints: BoxConstraints(maxHeight: heigth /1.4),
                              height: heigth / 1.5,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Color(0xFF0DE75A),
                                    radius: size * 1.6 / 100,
                                  ),
                                  SizedBox(width: width * 1 / 100),
                                  Text(
                                    "Active",
                                    style: TextStyle(
                                        color: Colors.white,
                                        letterSpacing: 1.0),
                                  )
                                ],
                              ),
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [
                                    Color.fromRGBO(19, 41, 61, 0.0),
                                    Color.fromRGBO(19, 41, 61, 0.1),
                                    Color.fromRGBO(19, 41, 61, 1.0)
                                  ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter)),
                            ),
                          ),
                        ],
                      ),
                      titlePadding: EdgeInsets.only(
                          left: width * 4 / 100, bottom: heigth * 2 / 100),
                      title: Text(widget.userData['name'],
                          style: TextStyle(
                              color: Colors.white, fontFamily: 'Mulish')),
                    ),
                  ),
                  SliverFillRemaining(
                      //  fillOverscroll: true,
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: width * 5 / 100),
                          child: (iBlocked || gotBlocked)
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(widget.userData['username'],
                                            style: TextStyle(
                                                fontFamily: 'Mulish',
                                                fontSize: size * 5.5 / 100,
                                                color: Colors.white
                                                    .withOpacity(0.4))),
                                        Expanded(child: Container()),
                                        InkWell(
                                          onTap: (gotBlocked)
                                              ? () {}
                                              : () {
                                                  showAlertDialogue(context,
                                                      name: 'Unblocking',
                                                      widget: Container(
                                                        alignment:
                                                            Alignment.center,
                                                        height:
                                                            heigth * 3 / 100,
                                                        child: InkWell(
                                                          onTap: () async {
                                                            Navigator.pop(
                                                                context);

                                                            setState(() {
                                                              isCalling = true;
                                                            });

                                                            try {
                                                              await firestore
                                                                  .collection(
                                                                      'Blocking')
                                                                  .doc(auth
                                                                      .currentUser
                                                                      .email)
                                                                  .collection(
                                                                      'iBlocked')
                                                                  .doc(widget
                                                                          .userData[
                                                                      'email'])
                                                                  .delete();
                                                              // .set(widget.userData);

                                                              await firestore
                                                                  .collection(
                                                                      'Blocking')
                                                                  .doc(widget
                                                                          .userData[
                                                                      'email'])
                                                                  .collection(
                                                                      'gotBlocked')
                                                                  .doc(auth
                                                                      .currentUser
                                                                      .email)
                                                                  .delete();
                                                              //     .set({
                                                              //   'email': auth
                                                              //       .currentUser
                                                              //       .email
                                                              // });

                                                              setState(() {
                                                                isCalling =
                                                                    false;

                                                                iBlocked =
                                                                    false;
                                                                gotBlocked =
                                                                    false;
                                                              });

                                                              // dataProvider
                                                              //         .refresherUnblock =
                                                              //     !dataProvider
                                                              //         .refresherUnblock;
                                                              CoolAlert.show(
                                                                  context:
                                                                      context,
                                                                  type: CoolAlertType
                                                                      .success,
                                                                  text:
                                                                      'User has been unblocked successfully.');
                                                            } catch (e) {
                                                              setState(() {
                                                                isCalling =
                                                                    false;
                                                              });
                                                              CoolAlert.show(
                                                                  context:
                                                                      context,
                                                                  type:
                                                                      CoolAlertType
                                                                          .error,
                                                                  text:
                                                                      'An error occurred.');
                                                            }
                                                          },
                                                          child: Text("Unblock",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontFamily:
                                                                      'Mulish')),
                                                        ),
                                                      ));
                                                },
                                          child: Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.blue,
                                          ),
                                        )
                                      ],
                                    ),
                                    SizedBox(height: heigth * 1.0 / 100),
                                    Container(
                                      height: heigth * 12 / 100,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(child: Container()),
                                          InkWell(
                                            onTap: () async {
                                              CoolAlert.show(
                                                  context: context,
                                                  type: CoolAlertType.warning,
                                                  text: (iBlocked)
                                                      ? "You blocked this user."
                                                      : 'This user has blocked you.');
                                              // var chennelId =
                                              //     generateRandomString(16);

                                              // setState(() {
                                              //   isCalling = true;
                                              // });

                                              // try {
                                              //   await firestore
                                              //       .collection('VideoCalls')
                                              //       .doc(chennelId)
                                              //       .set({
                                              //     'caller':
                                              //         auth.currentUser.email,
                                              //     'receiver':
                                              //         widget.userData['email'],
                                              //     'chennelId': chennelId,
                                              //     'isPicked': false,
                                              //     'isDeclined': false,
                                              //     'isAudio': true,
                                              //     // 'isCalling': true,
                                              //   });
                                              // } catch (e) {
                                              //   setState(() {
                                              //     isCalling = false;
                                              //   });

                                              // CoolAlert.show(
                                              //     context: context,
                                              //     type: CoolAlertType.error,
                                              //     title: 'Sorry!',
                                              //     text: 'An error occurred.');
                                              // }
                                              // setState(() {
                                              //   isCalling = false;
                                              // });

                                              // await _handleCameraAndMic(
                                              //     Permission.camera);
                                              // await _handleCameraAndMic(
                                              //     Permission.microphone);

                                              // Navigator.push(
                                              //     context,
                                              //     FadePageRoute(CallerScreen1(
                                              //       chennelId: chennelId,
                                              //       userData: widget.userData,
                                              //     )));
                                            },
                                            child: CircleAvatar(
                                              radius: size * 9 / 100,
                                              child: Icon(
                                                Icons.call,
                                                color: Colors.white,
                                              ),
                                              backgroundColor: Colors.grey,
                                            ),
                                          ),
                                          SizedBox(width: width * 2 / 100),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                bottom: heigth * 1.5 / 100),
                                            child: InkWell(
                                              onTap: () {
                                                CoolAlert.show(
                                                    context: context,
                                                    type: CoolAlertType.warning,
                                                    text: (iBlocked)
                                                        ? "You blocked this user."
                                                        : 'This user has blocked you.');
                                                // Navigator.push(
                                                //     context,
                                                //     FadePageRoute(
                                                //         ConversationScreen(
                                                //       userData: widget.userData,
                                                //       conversationEmail: widget
                                                //           .userData['email'],
                                                //     )));
                                              },
                                              child: CircleAvatar(
                                                radius: size * 12 / 100,
                                                child: Icon(Icons.chat_bubble,
                                                    color: Colors.white,
                                                    size: size * 10.5 / 100),
                                                backgroundColor: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: width * 2 / 100),
                                          InkWell(
                                            onTap: () async {
                                              CoolAlert.show(
                                                  context: context,
                                                  type: CoolAlertType.warning,
                                                  text: (iBlocked)
                                                      ? "You blocked this user."
                                                      : 'This user has blocked you.');
                                              // var chennelId =
                                              //     generateRandomString(16);

                                              // setState(() {
                                              //   isCalling = true;
                                              // });

                                              // try {
                                              //   await firestore
                                              //       .collection('VideoCalls')
                                              //       .doc(chennelId)
                                              //       .set({
                                              //     'caller':
                                              //         auth.currentUser.email,
                                              //     'receiver':
                                              //         widget.userData['email'],
                                              //     'chennelId': chennelId,
                                              //     'isPicked': false,
                                              //     'isDeclined': false,
                                              //     'isAudio': false,
                                              //     // 'isCalling': true
                                              //   });
                                              // } catch (e) {
                                              //   setState(() {
                                              //     isCalling = false;
                                              //   });

                                              //   CoolAlert.show(
                                              //       context: context,
                                              //       type: CoolAlertType.error,
                                              //       title: 'Sorry!',
                                              //       text: 'An error occurred.');
                                              // }

                                              // setState(() {
                                              //   isCalling = false;
                                              // });

                                              // await _handleCameraAndMic(
                                              //     Permission.camera);
                                              // await _handleCameraAndMic(
                                              //     Permission.microphone);

                                              // Navigator.push(
                                              //     context,
                                              //     FadePageRoute(CallerScreen1(
                                              //       chennelId: chennelId,
                                              //       userData: widget.userData,
                                              //     )));
                                            },
                                            child: CircleAvatar(
                                              radius: size * 9 / 100,
                                              child: Icon(
                                                Icons.videocam,
                                                color: Colors.white,
                                              ),
                                              backgroundColor: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(widget.userData['username'],
                                            style: TextStyle(
                                                fontFamily: 'Mulish',
                                                fontSize: size * 5.5 / 100,
                                                color: Colors.white
                                                    .withOpacity(0.4))),
                                        Expanded(child: Container()),
                                        InkWell(
                                          onTap: () {
                                            showAlertDialogue(context,
                                                name: 'Blocking',
                                                check: true,
                                                widget: Container(
                                                  height: heigth * 10 / 100,
                                                  child: Column(children: [
                                                    Expanded(
                                                        child: InkWell(
                                                      onTap: () async {
                                                        Navigator.pop(context);

                                                        setState(() {
                                                          isCalling = true;
                                                        });

                                                        try {
                                                          await firestore
                                                              .collection(
                                                                  'Blocking')
                                                              .doc(auth
                                                                  .currentUser
                                                                  .email)
                                                              .collection(
                                                                  'iBlocked')
                                                              .doc(widget
                                                                      .userData[
                                                                  'email'])
                                                              .set(widget
                                                                  .userData);

                                                          await firestore
                                                              .collection(
                                                                  'Blocking')
                                                              .doc(widget
                                                                      .userData[
                                                                  'email'])
                                                              .collection(
                                                                  'gotBlocked')
                                                              .doc(auth
                                                                  .currentUser
                                                                  .email)
                                                              .set({
                                                            'email': auth
                                                                .currentUser
                                                                .email
                                                          });

                                                          setState(() {
                                                            isCalling = false;
                                                          });
                                                          CoolAlert.show(
                                                              context: context,
                                                              type:
                                                                  CoolAlertType
                                                                      .success,
                                                              text:
                                                                  'User has been blocked successfully.');
                                                        } catch (e) {
                                                          setState(() {
                                                            isCalling = false;
                                                          });
                                                          CoolAlert.show(
                                                              context: context,
                                                              type:
                                                                  CoolAlertType
                                                                      .error,
                                                              text:
                                                                  'An error occurred.');
                                                        }
                                                      },
                                                      child: Text("Block",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontFamily:
                                                                  'Mulish')),
                                                    )),
                                                    SizedBox(
                                                        height:
                                                            heigth * 1 / 100),
                                                    Expanded(
                                                        child: InkWell(
                                                      onTap: () {
                                                        Navigator.pop(context);

                                                        CoolAlert.show(
                                                            context: context,
                                                            type: CoolAlertType
                                                                .success,
                                                            text:
                                                                'User has been reported successfully.');
                                                      },
                                                      child: Text("Report",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontFamily:
                                                                  'Mulish')),
                                                    )),
                                                    SizedBox(
                                                        height:
                                                            heigth * 1 / 100),
                                                    Expanded(
                                                        child: InkWell(
                                                      onTap: () async {
                                                        Navigator.pop(context);

                                                        setState(() {
                                                          isCalling = true;
                                                        });

                                                        try {
                                                          await firestore
                                                              .collection(
                                                                  'Blocking')
                                                              .doc(auth
                                                                  .currentUser
                                                                  .email)
                                                              .collection(
                                                                  'iBlocked')
                                                              .doc(widget
                                                                      .userData[
                                                                  'email'])
                                                              .set(widget
                                                                  .userData);

                                                          await firestore
                                                              .collection(
                                                                  'Blocking')
                                                              .doc(widget
                                                                      .userData[
                                                                  'email'])
                                                              .collection(
                                                                  'gotBlocked')
                                                              .doc(auth
                                                                  .currentUser
                                                                  .email)
                                                              .set({
                                                            'email': auth
                                                                .currentUser
                                                                .email
                                                          });

                                                          setState(() {
                                                            isCalling = false;
                                                          });
                                                          CoolAlert.show(
                                                              context: context,
                                                              type:
                                                                  CoolAlertType
                                                                      .success,
                                                              text:
                                                                  'User has been blocked and reported successfully.');
                                                        } catch (e) {
                                                          setState(() {
                                                            isCalling = false;
                                                          });
                                                          CoolAlert.show(
                                                              context: context,
                                                              type:
                                                                  CoolAlertType
                                                                      .error,
                                                              text:
                                                                  'An error occurred.');
                                                        }
                                                      },
                                                      child: Text(
                                                          "Block and Report",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontFamily:
                                                                  'Mulish')),
                                                    ))
                                                  ]),
                                                ));
                                          },
                                          child: Icon(
                                            Icons.warning_amber_rounded,
                                            color:
                                                Colors.white.withOpacity(0.4),
                                          ),
                                        )
                                      ],
                                    ),
                                    SizedBox(height: heigth * 1.0 / 100),
                                    Container(
                                      height: heigth * 12 / 100,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(child: Container()),
                                          InkWell(
                                            onTap: () async {
                                              var chennelId =
                                                  generateRandomString(16);

                                              setState(() {
                                                isCalling = true;
                                              });

                                              try {
                                                await firestore
                                                    .collection('VideoCalls')
                                                    .doc(chennelId)
                                                    .set({
                                                  'caller':
                                                      auth.currentUser.email,
                                                  'receiver':
                                                      widget.userData['email'],
                                                  'chennelId': chennelId,
                                                  'isPicked': false,
                                                  'isDeclined': false,
                                                  'isAudio': true,
                                                  // 'isCalling': true,
                                                });
                                              } catch (e) {
                                                setState(() {
                                                  isCalling = false;
                                                });

                                                CoolAlert.show(
                                                    context: context,
                                                    type: CoolAlertType.error,
                                                    title: 'Sorry!',
                                                    text: 'An error occurred.');
                                              }
                                              setState(() {
                                                isCalling = false;
                                              });

                                              await _handleCameraAndMic(
                                                  Permission.camera);
                                              await _handleCameraAndMic(
                                                  Permission.microphone);

                                              Navigator.push(
                                                  context,
                                                  FadePageRoute(CallerScreen1(
                                                    chennelId: chennelId,
                                                    userData: widget.userData,
                                                  )));
                                            },
                                            child: CircleAvatar(
                                              radius: size * 9 / 100,
                                              child: Icon(
                                                Icons.call,
                                                color: Colors.white,
                                              ),
                                              backgroundColor:
                                                  Color(0xFF0DE75A),
                                            ),
                                          ),
                                          SizedBox(width: width * 2 / 100),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                bottom: heigth * 1.5 / 100),
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    FadePageRoute(
                                                        ConversationScreen(
                                                      userData: widget.userData,
                                                      conversationEmail: widget
                                                          .userData['email'],
                                                    )));
                                              },
                                              child: CircleAvatar(
                                                radius: size * 12 / 100,
                                                child: Icon(Icons.chat_bubble,
                                                    color: Colors.white,
                                                    size: size * 10.5 / 100),
                                                backgroundColor: Colors.blue,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: width * 2 / 100),
                                          InkWell(
                                            onTap: () async {
                                              var chennelId =
                                                  generateRandomString(16);

                                              setState(() {
                                                isCalling = true;
                                              });

                                              try {
                                                await firestore
                                                    .collection('VideoCalls')
                                                    .doc(chennelId)
                                                    .set({
                                                  'caller':
                                                      auth.currentUser.email,
                                                  'receiver':
                                                      widget.userData['email'],
                                                  'chennelId': chennelId,
                                                  'isPicked': false,
                                                  'isDeclined': false,
                                                  'isAudio': false,
                                                  // 'isCalling': true
                                                });
                                              } catch (e) {
                                                setState(() {
                                                  isCalling = false;
                                                });

                                                CoolAlert.show(
                                                    context: context,
                                                    type: CoolAlertType.error,
                                                    title: 'Sorry!',
                                                    text: 'An error occurred.');
                                              }

                                              setState(() {
                                                isCalling = false;
                                              });

                                              await _handleCameraAndMic(
                                                  Permission.camera);
                                              await _handleCameraAndMic(
                                                  Permission.microphone);

                                              Navigator.push(
                                                  context,
                                                  FadePageRoute(CallerScreen1(
                                                    chennelId: chennelId,
                                                    userData: widget.userData,
                                                  )));
                                            },
                                            child: CircleAvatar(
                                              radius: size * 9 / 100,
                                              child: Icon(
                                                Icons.videocam,
                                                color: Colors.white,
                                              ),
                                              backgroundColor:
                                                  Color(0xFF20D5B7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    (!(widget.userData['bio'] == '' ||
                                            widget.userData['bio'] == null))
                                        ? SizedBox(height: heigth * 2 / 100)
                                        : Container(),
                                    (!(widget.userData['bio'] == '' ||
                                            widget.userData['bio'] == null))
                                        ? buildColumnText('Bio', size, heigth,
                                            widget.userData['bio'])
                                        : Container(),
                                    (!(widget.userData['gender'] == '' ||
                                            widget.userData['gender'] == null))
                                        ? SizedBox(height: heigth * 2 / 100)
                                        : Container(),
                                    (!(widget.userData['gender'] == '' ||
                                            widget.userData['gender'] == null))
                                        ? buildColumnText('Gender', size,
                                            heigth, widget.userData['gender'])
                                        : Container(),
                                    (!(widget.userData['interestedIn'] == '' ||
                                            widget.userData['interestedIn'] ==
                                                null))
                                        ? SizedBox(height: heigth * 2 / 100)
                                        : Container(),
                                    (!(widget.userData['interestedIn'] == '' ||
                                            widget.userData['interestedIn'] ==
                                                null))
                                        ? buildColumnText(
                                            'Interested In',
                                            size,
                                            heigth,
                                            widget.userData['interestedIn'])
                                        : Container(),
                                    (!(widget.userData['location'] == '' ||
                                            widget.userData['location'] ==
                                                null))
                                        ? SizedBox(height: heigth * 2 / 100)
                                        : Container(),
                                    (!(widget.userData['location'] == '' ||
                                            widget.userData['location'] ==
                                                null))
                                        ? buildColumnText('Location', size,
                                            heigth, widget.userData['location'])
                                        : Container(),
                                    (!(widget.userData['ethnicity'] == '' ||
                                            widget.userData['ethnicity'] ==
                                                null))
                                        ? SizedBox(height: heigth * 2 / 100)
                                        : Container(),
                                    (!(widget.userData['ethnicity'] == '' ||
                                            widget.userData['ethnicity'] ==
                                                null))
                                        ? buildColumnText(
                                            'Ethnicity',
                                            size,
                                            heigth,
                                            widget.userData['ethnicity'])
                                        : Container(),
                                    (!(widget.userData['age'] == '' ||
                                            widget.userData['age'] == null))
                                        ? SizedBox(height: heigth * 2 / 100)
                                        : Container(),
                                    (!(widget.userData['age'] == '' ||
                                            widget.userData['age'] == null))
                                        ? buildColumnText('Age', size, heigth,
                                            widget.userData['age'])
                                        : Container(),
                                    (!(widget.userData['height'] == '' ||
                                            widget.userData['height'] == null))
                                        ? SizedBox(height: heigth * 2 / 100)
                                        : Container(),
                                    (!(widget.userData['height'] == '' ||
                                            widget.userData['height'] == null))
                                        ? buildColumnText('Height', size,
                                            heigth, widget.userData['height'])
                                        : Container(),
                                    (!(widget.userData['bodyType'] == '' ||
                                            widget.userData['bodyType'] ==
                                                null))
                                        ? SizedBox(height: heigth * 2 / 100)
                                        : Container(),
                                    (!(widget.userData['bodyType'] == '' ||
                                            widget.userData['bodyType'] ==
                                                null))
                                        ? buildColumnText('Body Type', size,
                                            heigth, widget.userData['bodyType'])
                                        : Container(),
                                    (!(widget.userData['interests'] == '' ||
                                            widget.userData['interests'] ==
                                                null))
                                        ? SizedBox(height: heigth * 2 / 100)
                                        : Container(),
                                    (!(widget.userData['interests'] == '' ||
                                            widget.userData['interests'] ==
                                                null))
                                        ? buildColumnText(
                                            'Interests',
                                            size,
                                            heigth,
                                            '#' +
                                                widget.userData['interests']
                                                    .replaceAll(' ', ' #'))
                                        : Container(),
                                    (!(widget.userData == null))
                                        ? SizedBox(height: heigth * 2 / 100)
                                        : Container(),
                                  ],
                                ),
                        ),
                      )),
                ],
              ),
            );
          }),
    );
  }

  Column buildColumnText(var name, double size, double heigth, var data) {
    return Column(
        // mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: size * 5.5 / 100,
                  color: Colors.white.withOpacity(0.4))),
          SizedBox(height: heigth * 1.0 / 100),
          Text(data,
              style: TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: size * 6.5 / 100,
                  color: Colors.white))
        ]);
  }

  showAlertDialogue(BuildContext context,
      {String name, var widget, bool check = true}) {
    var alertDialogue = AlertDialog(
        backgroundColor: Color(0xFF13293D),
        title: Text(name,
            style: TextStyle(color: Colors.white, fontFamily: 'Mulish')),
        content: widget,
        actionsPadding: EdgeInsets.only(right: 20, bottom: 20),
        actions: [
          InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white, fontFamily: 'Mulish'))),
        ]);

    showDialog(
        context: context,
        builder: (context) {
          return alertDialogue;
        });
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }
}
