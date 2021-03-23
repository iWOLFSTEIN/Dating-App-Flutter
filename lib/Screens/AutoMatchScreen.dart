import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Screens/ConversationScreen.dart';
import 'package:chat_app/Screens/UserProfile.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/Services/FirebaseUserData.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as Mathematics;

class AutoMatchScreen extends StatefulWidget {
  AutoMatchScreen({Key key}) : super(key: key);

  @override
  _AutoMatchScreenState createState() => _AutoMatchScreenState();
}

class _AutoMatchScreenState extends State<AutoMatchScreen>
    with TickerProviderStateMixin {
  AnimationController rotationController;
  var animation;

  // Stream<QuerySnapshot> usersStream;
  var matchedUserData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    rotationController =
        AnimationController(duration: Duration(milliseconds: 400), vsync: this);

    animation =
        CurvedAnimation(parent: rotationController, curve: Curves.linear);
  }

  Mathematics.Random random = Mathematics.Random();

  @override
  void dispose() {
    rotationController.dispose();
    super.dispose();
  }

  rotateToMatch({userData}) {
    if (!matchFound) {
      setState(() {
        animation =
            CurvedAnimation(parent: rotationController, curve: Curves.linear);
      });
      rotationController.repeat();
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          animation =
              CurvedAnimation(parent: rotationController, curve: Curves.ease);
          rotationController.forward();
          if (userData != null) {
            setState(() {
              matchFound = true;
            });
            setState(() {
              matchNotFound = false;
            });
          } else {
            setState(() {
              matchNotFound = true;
            });
          }
        });
      });
    }
  }

  bool matchNotFound = false;
  bool matchFound = false;
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  FirebaseGetUserData db = FirebaseGetUserData();
  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    var size = (height + width) / 4;

    return Scaffold(
      backgroundColor: Color(0xFF13293D),
      appBar: AppBar(
        backgroundColor: Color(0xFF13293D),
        title: Text('Auto Matching'),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            int length = snapshot.data.docs.length;
            int counter = 0;

            int randomNumber = random.nextInt(length);

            if (matchedUserData == null)
              for (var data in snapshot.data.docs) {
                if (counter == randomNumber) {
                  matchedUserData = data.data();
                }
                counter++;
              }

            return Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 400),
                    // curve: Curves.ease,
                    switchInCurve: Curves.ease,
                    switchOutCurve: Curves.ease,
                    child: (!matchFound)
                        ? Column(
                            children: [
                              Text(
                                (matchNotFound)
                                    ? 'No match Found'
                                    : 'Double Tap to',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: size * 12 / 100,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                (matchNotFound) ? 'Try Again!!' : 'Match!!',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: size * 12 / 100,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : Text(
                            'Match Found!!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: size * 12 / 100,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                  AnimatedPadding(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.ease,
                    padding: (matchFound)
                        ? EdgeInsets.only(
                            bottom: height * 14 / 100, left: width * 4 / 100)
                        : EdgeInsets.all(0),
                    child: Stack(
                      overflow: Overflow.visible,
                      children: [
                        AnimatedPositioned(
                          duration: Duration(milliseconds: 400),
                          curve: Curves.ease,
                          left: (matchFound) ? width * 50 / 100 : 60,
                          top: (matchFound) ? height * 33 / 100 : 40,
                          child: Container(
                            height: height * 20 / 100,
                            width: width * 40 / 100,
                            child: Material(
                              elevation: 16,
                              color: Colors.white,
                              shape: CircleBorder(),
                              child: Container(
                                padding: EdgeInsets.all(5),
                                child: FutureBuilder(
                                    future: FireStorageService.loadImage(
                                        context, matchedUserData['profilePic']),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      return Container(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                                fit: BoxFit.cover,
                                                image:
                                                    CachedNetworkImageProvider(
                                                        snapshot.data
                                                            .toString()))),
                                      );
                                    }),
                              ),
                            ),
                          ),
                        ),
                        AnimatedAlign(
                          duration: Duration(milliseconds: 400),
                          curve: Curves.ease,
                          alignment: (matchFound)
                              ? Alignment.topLeft
                              : Alignment.center,
                          child: RotationTransition(
                            alignment: Alignment.center,
                            turns: animation,
                            child: Container(
                              height: (matchFound)
                                  ? height * 37.5 / 100
                                  : height * 40 / 100,
                              width: (matchFound)
                                  ? width * 75 / 100
                                  : width * 80 / 100,
                              child: Material(
                                elevation: 16,
                                color: Colors.white,
                                shape: CircleBorder(),
                                child: Container(
                                  padding: (matchFound)
                                      ? EdgeInsets.all(7)
                                      : EdgeInsets.all(10),
                                  child: GestureDetector(
                                    onDoubleTap: () {
                                      rotateToMatch(userData: matchedUserData);
                                    },
                                    child: StreamBuilder<FirebaseUserData>(
                                        stream: db.streamUserData(
                                            email: auth.currentUser.email),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }
                                          return FutureBuilder(
                                              future:
                                                  FireStorageService.loadImage(
                                                      context,
                                                      snapshot.data.profilePic),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData) {
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                }
                                                return Container(
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      image: DecorationImage(
                                                          fit: BoxFit.cover,
                                                          image: CachedNetworkImageProvider(
                                                              snapshot.data
                                                                  .toString()))),
                                                );
                                              });
                                        }),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.ease,
                    opacity: (matchFound) ? 1.0 : 0.0,
                    child: Row(
                      children: [
                        Expanded(child: Container()),
                        RaisedButton(
                            padding: EdgeInsets.symmetric(
                                horizontal: width * 6 / 100,
                                vertical: height * 2.5 / 100),
                            child: Center(
                              child: Text(
                                'Match Again',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: size * 7 / 100),
                              ),
                            ),
                            color: Colors.cyan,
                            onPressed: () {
                              if (matchFound) {
                                if (matchFound) {
                                  setState(() {
                                    matchFound = false;
                                    matchedUserData = null;
                                  });
                                }
                              }
                            }),
                        Expanded(child: Container()),
                        RaisedButton(
                            padding: EdgeInsets.symmetric(
                                horizontal: width * 8 / 100,
                                vertical: height * 2.5 / 100),
                            child: Center(
                              child: Text(
                                'Start Chat',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: size * 7 / 100),
                              ),
                            ),
                            color: Colors.greenAccent,
                            onPressed: () {
                              if (matchFound) {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return ConversationScreen(
                                      userData: matchedUserData,
                                      conversationEmail:
                                          matchedUserData['email']);
                                }));
                              }
                            }),
                        Expanded(child: Container()),
                      ],
                    ),
                  )
                ],
              ),
            );
          }),
    );
  }
}
