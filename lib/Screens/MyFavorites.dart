import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Screens/ConversationScreen.dart';
import 'package:chat_app/Screens/UserProfile.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/utils/FacebookAdsUtils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:widget_animator/widget_animator.dart';

class MyFavorites extends StatefulWidget {
  MyFavorites({Key key}) : super(key: key);

  @override
  _MyFavoritesState createState() => _MyFavoritesState();
}

class _MyFavoritesState extends State<MyFavorites> {
  final firestore = FirebaseFirestore.instance;

  final auth = FirebaseAuth.instance;

  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var size = (height + width) / 2;
    return ModalProgressHUD(
      inAsyncCall: isDeleting,
      child: Scaffold(
        backgroundColor: Color(0xFF13293D),
        appBar: AppBar(
          backgroundColor: Color(0xFF13293D),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: width * 5 / 100),
              child: InkWell(
                onTap: () async {
                  setState(() {
                    isDeleting = true;
                  });

                  await firestore
                      .collection('Favorites')
                      .doc(auth.currentUser.email)
                      .collection('MyFavorites')
                      .get()
                      .then((snapshot) {
                    for (DocumentSnapshot ds in snapshot.docs) {
                      ds.reference.delete();
                    }
                  });
                  setState(() {
                    isDeleting = false;
                  });
                },
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          title: Text(
            'My Favorites',
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('Favorites')
                .doc(auth.currentUser.email)
                .collection('MyFavorites')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              List<Widget> widgetList = [];

              int counterForAds = 0;

              for (var data in snapshot.data.docs) {
                var userWidget = WidgetAnimator(
                    curve: Curves.easeIn,
                    duration: Duration(milliseconds: 300),
                    child: FutureBuilder(
                        future: FireStorageService.loadImage(
                            context, data.data()['profilePic']
                            //  profilePic
                            ),
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
                              height: height * 11 / 100,
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
                                        SizedBox(height: height * 1 / 100),
                                        Text(
                                          (data.data()['bio'].length < 18)
                                              ? data.data()['bio'].toLowerCase()
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
                                              color:
                                                  Colors.white.withOpacity(0.4),
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
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: size * 1.8 / 100),
                                            ),
                                            backgroundColor: Color(0xFF0DE75A),
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
                        })
                    //           ;

                    // })

                    );

                widgetList.add(userWidget);
                counterForAds++;
                if (counterForAds == 3) {
                  counterForAds = 0;
                  widgetList.add(
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 4 / 100,
                          vertical: height * 1 / 100),
                      child: FacebookNativeAd(
                        placementId: FacebookNativeAdId,
                        // "236180364658625_236181534658508",
                        adType: NativeAdType.NATIVE_AD,
                        width: double.infinity,
                        height: 300,
                        backgroundColor: Colors.blue,
                        titleColor: Colors.white,
                        descriptionColor: Colors.white,
                        buttonColor: Colors.deepPurple,
                        buttonTitleColor: Colors.white,
                        buttonBorderColor: Colors.white,
                        keepAlive:
                            true, //set true if you do not want adview to refresh on widget rebuild
                        keepExpandedWhileLoading:
                            false, // set false if you want to collapse the native ad view when the ad is loading
                        expandAnimationDuraion:
                            300, //in milliseconds. Expands the adview with animation when ad is loaded
                        listener: (result, value) {
                          print("Native Ad: $result --> $value");
                        },
                      ),
                    ),
                  );
                }
              }
              return ListView(
                children: widgetList,
              );
            }),
      ),
    );
  }
}
