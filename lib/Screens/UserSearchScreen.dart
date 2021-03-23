import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Screens/UserProfile.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:widget_animator/widget_animator.dart';

class UserSearchScreen extends StatefulWidget {
  UserSearchScreen({Key key}) : super(key: key);

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final firestore = FirebaseFirestore.instance;
  var textStyle = TextStyle(
    color: Colors.white,
  );
  var searchMaterial = '';
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 2;
    return Scaffold(
      backgroundColor: Color(0xFF13293D),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.only(top: heigth * 7 / 100),
            child: Row(
              children: [
                SizedBox(width: width * 4 / 100),
                Expanded(
                  child: Container(
                    height: heigth * 6 / 100,
                    width: width * 70 / 100,
                    decoration: BoxDecoration(
                        color: Color(0xFF18344E),
                        borderRadius: BorderRadius.circular(50)),
                    child: Material(
                      color: Color(0xFF18344E),
                      borderRadius: BorderRadius.circular(50),
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: width * 4 / 100),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchMaterial = value;
                            });
                          },
                          style: textStyle,
                          autocorrect: false,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintText: 'Write username',
                            hintStyle: textStyle.copyWith(
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: width * 4 / 100),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                List<Widget> widgetList = [];
                for (var data in snapshot.data.docs) {
                  // String a;
                  // a.con

                  if (data.data()['username'].contains(searchMaterial)) {
                    var userWidget = WidgetAnimator(
                        curve: Curves.easeIn,
                        duration: Duration(milliseconds: 300),
                        child: FutureBuilder(
                            future: FireStorageService.loadImage(
                                context, data.data()['profilePic']),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container();
                              }
                              return InkWell(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return UserProfile(
                                      userData: data.data(),
                                    );
                                  }));
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: heigth * 11 / 100,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: width * 5 / 100,
                                      ),
                                      CircleAvatar(
                                          radius: size * 4.8 / 100,
                                          backgroundColor: Colors.white,
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                  snapshot.data.toString())),
                                      SizedBox(
                                        width: width * 3 / 100,
                                      ),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data.data()['name'],
                                              style: TextStyle(
                                                  fontSize: size * 3.3 / 100,
                                                  color: Colors.white),
                                            ),
                                            SizedBox(height: heigth * 1 / 100),
                                            Text(
                                              (data.data()['bio'].length < 18)
                                                  ? data
                                                      .data()['bio']
                                                      .toLowerCase()
                                                  : data
                                                          .data()['bio']
                                                          .substring(0, 17)
                                                          .toLowerCase() +
                                                      '...',
                                              // 'hello',
                                              style: TextStyle(
                                                  fontSize: size * 2.7 / 100,
                                                  color: Colors.white
                                                      .withOpacity(0.4)),
                                            )
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: width * 1 / 100,
                                      ),
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              data.data()['gender'],
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.4),
                                                  fontSize: size * 2 / 100),
                                            ),
                                            SizedBox(height: 15),
                                            Opacity(
                                              opacity: 0.0,
                                              child: CircleAvatar(
                                                radius: size * 1.5 / 100,
                                                child: Text(
                                                  "1",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          size * 1.8 / 100),
                                                ),
                                                backgroundColor:
                                                    Color(0xFF0DE75A),
                                              ),
                                            )
                                          ]),
                                      SizedBox(
                                        width: width * 5 / 100,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }));

                    widgetList.add(userWidget);
                  }
                }
                return Expanded(
                    child: ListView(
                  children: widgetList,
                ));
              })
        ],
      ),
    );
  }
}
