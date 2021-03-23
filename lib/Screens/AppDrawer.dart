import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Screens/AutoMatchScreen.dart';
import 'package:chat_app/Screens/EditProfileScreen.dart';
import 'package:chat_app/Screens/LoginScreen.dart';
import 'package:chat_app/Screens/MyFavorites.dart';
import 'package:chat_app/Screens/UserSearchScreen.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/Services/FirebaseUserData.dart';
import 'package:chat_app/Services/SignInServices.dart';
import 'package:chat_app/Services/UserState.dart';
import 'package:chat_app/utils/FacebookAdsUtils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatefulWidget {
  AppDrawer({
    Key key,
  }) : super(key: key);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final db = FirebaseGetUserData();

  final auth = FirebaseAuth.instance;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FacebookAudienceNetwork.init(
        //  testingId: "b7eced01-39d8-4929-8736-bc3a7e3df690"

        );
  }

  bool adLoaded = false;
  UserState userState = UserState();

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var size = (height + width) / 8;
    return Drawer(
      child: Container(
        color: Color(0xFF13293D),

        //Color(0xFFEEF4F6),
        child: ListView(
          children: [
            StreamBuilder<FirebaseUserData>(
                stream: db.streamUserData(email: auth.currentUser.email),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      height: height / 3,
                    );
                  }
                  return Container(
                    height: height / 3,
                    decoration: BoxDecoration(
                        color: Color(0xFF29bae9),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF13293D).withOpacity(1.0),
                              Color(0xFF13293D).withOpacity(0.5),
                              Color(0xFF13293D).withOpacity(0.0),
                            ])),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: height * 1 / 100, left: width * 4 / 100),
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                // Color(0xFF1c5162).withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            FutureBuilder(
                                // stream: null,
                                future: FireStorageService.loadImage(context,
                                    snapshot.data.profilePic.toString()),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return CircleAvatar(
                                      backgroundColor: Color(0xFFecf9fe),
                                      radius: size * 50 / 100,
                                      // backgroundImage:
                                      //     // (currentSignedInUser.photoURL != null)
                                      //     //     ?
                                      //     CachedNetworkImageProvider(
                                      //       snapshot.data.toString()
                                      //         )
                                      // : currentUserAlternateImage,
                                    );
                                  }
                                  return CircleAvatar(
                                      backgroundColor: Color(0xFFecf9fe),
                                      radius: size * 50 / 100,
                                      backgroundImage:
                                          // (currentSignedInUser.photoURL != null)
                                          //     ?
                                          CachedNetworkImageProvider(
                                              snapshot.data.toString())
                                      // : currentUserAlternateImage,
                                      );
                                }),
                            SizedBox(height: height * 1.5 / 100),
                            Text(
                              snapshot.data.name,
                              // (currentSignedInUser.displayName != null)
                              //     ? currentSignedInUser.displayName
                              //     : currentUserAlternateName,
                              style: TextStyle(
                                  color: Colors.white,
                                  // Color(0xFF1c5162).withOpacity(0.8),
                                  fontWeight: FontWeight.w900,
                                  fontSize: size * 16 / 100),
                            ),
                            SizedBox(height: height * 1 / 100),
                            Text(
                              // currentSignedInUser.email,
                              //  'iamalisonhazzard@gmail.com',
                              snapshot.data.username,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: size * 11 / 100,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

            // ListTile(
            //   title:
            Padding(
              padding: EdgeInsets.only(
                  left: width * 4.5 / 100,
                  bottom: height * 2.4 / 100,
                  top: height * .5 / 100),
              child: Text(
                "  ---------------------------------------------",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    //Color(0xFF1c5162).withOpacity(0.2),
                    fontWeight: FontWeight.w600,
                    fontSize: size * 12 / 100),
              ),
            ),
            // ),
            ListTile(
              onTap: () {
                Navigator.pop(context);

                Navigator.push(context, FadePageRoute(EditProfileScreen()));
              },
              leading: Icon(
                Icons.person_outline,
                color: Colors.white,
                //Color(0xFF1c5162).withOpacity(0.6),
              ),
              title: Text(
                "Edit Profile",
                style: TextStyle(
                    color: Colors.white,
                    // Color(0xFF1c5162).withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: size * 12 / 100),
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MyFavorites()));
              },
              leading: Icon(
                Icons.favorite_border,
                color: Colors.white,
                // Color(0xFF1c5162).withOpacity(0.6),
              ),
              title: Text(
                "My Favorites",
                style: TextStyle(
                    color: Colors.white,
                    // Color(0xFF1c5162).withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: size * 12 / 100),
              ),
            ),

            // Container(
            //   // color: Colors.green,
            //   height:
            //       // (adLoaded) ?
            //       120,
            //   //   : 0,
            //   // 0,
            //   child: FacebookNativeAd(
            //     placementId: FacebookNativeBannerAdId,
            //     //  "236180364658625_236182687991726",
            //     adType: NativeAdType.NATIVE_BANNER_AD,
            //     bannerAdSize: NativeBannerAdSize.HEIGHT_120,
            //     width: double.infinity,
            //     backgroundColor: Colors.blue,
            //     titleColor: Colors.white,
            //     descriptionColor: Colors.white,
            //     buttonColor: Colors.deepPurple,
            //     buttonTitleColor: Colors.white,
            //     buttonBorderColor: Colors.white,
            //     listener: (result, value) {
            //       // print("Native Ad: $result --> $value");
            //       // if (result == NativeAdResult.LOADED) {
            //       //   setState(() {
            //       //     adLoaded = true;
            //       //   });
            //       // } else if (result == NativeAdResult.ERROR) {
            //       //   setState(() {
            //       //     adLoaded = false;
            //       //   });
            //       // }
            //     },
            //   ),
            // ),

            FacebookNativeAd(
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

            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UserSearchScreen()));
              },
              leading: Icon(Icons.search, color: Colors.white
                  // Color(0xFF1c5162).withOpacity(0.6),
                  ),
              title: Text(
                "Search",
                style: TextStyle(
                    color: Colors.white,
                    //Color(0xFF1c5162).withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: size * 12 / 100),
              ),
            ),

            // Container(
            //   color: Colors.green,
            //   height: 120,
            //   child: FacebookNativeAd(
            //     placementId: "236180364658625_236182687991726",
            //     adType: NativeAdType.NATIVE_BANNER_AD,
            //     bannerAdSize: NativeBannerAdSize.HEIGHT_120,
            //     width: double.infinity,
            //     backgroundColor: Colors.blue,
            //     titleColor: Colors.white,
            //     descriptionColor: Colors.white,
            //     buttonColor: Colors.deepPurple,
            //     buttonTitleColor: Colors.white,
            //     buttonBorderColor: Colors.white,
            //     listener: (result, value) {
            //       print("Native Ad: $result --> $value");
            //     },
            //   ),
            // ),

            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AutoMatchScreen()));
              },
              leading: Icon(Icons.group_outlined, color: Colors.white
                  // Color(0xFF1c5162).withOpacity(0.6),
                  ),
              title: Text(
                "Auto Matching",
                style: TextStyle(
                    color: Colors.white,
                    //Color(0xFF1c5162).withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: size * 12 / 100),
              ),
            ),

            ListTile(
              title: Text(
                "  ---------------------------------------------",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    //Color(0xFF1c5162).withOpacity(0.2),
                    fontWeight: FontWeight.w600,
                    fontSize: size * 12 / 100),
              ),
            ),

            ListTile(
              onTap: () async {
                var url =
                    "https://sulefa786.blogspot.com/p/privacy-policy-chatoo-chat-dating-free.html";

                try {
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    CoolAlert.show(
                      context: context,
                      type: CoolAlertType.warning,
                      title: "Invalid Url!",
                      text: "The url is not valid to launch.",
                    );
                  }
                } catch (e) {}
              },
              leading: Icon(Icons.rule, color: Colors.white
                  // Color(0xFF1c5162).withOpacity(0.6),
                  ),
              title: Text(
                "Privacy Policy",
                style: TextStyle(
                    color: Colors.white,
                    //Color(0xFF1c5162).withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: size * 12 / 100),
              ),
            ),

            ListTile(
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                    context: context,
                    applicationName: 'Chatoo',
                    applicationVersion: '1.0.0',
                    applicationLegalese:
                        'This is Dater version 1.0.0 with all the copy rightes secured by the maker of this app. Any attempy to steal this app or its content can cause copy right issues and a legal action against you.',
                    applicationIcon: Image.asset(
                      'images/appIcon.png',
                      height: height * 5.5 / 100,
                      width: width * 11 / 100,
                    ));
              },
              leading: Icon(
                Icons.info_outline,
                color: Colors.white,

                // Color(0xFF1c5162).withOpacity(0.6),
              ),
              title: Text(
                "About",
                style: TextStyle(
                    color: Colors.white,
                    // Color(0xFF1c5162).withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: size * 12 / 100),
              ),
            ),
            // StreamBuilder<DocumentSnapshot>(
            //     stream:
            //      firestore
            //         .collection('appLink')
            //         .doc('rewarderPlayStoreUrlLink')
            //         .snapshots(),
            //     builder: (context, snapshot) {
            //       return
            ListTile(
              onTap: () async {
                final firestore = FirebaseFirestore.instance;
                try {
                  await firestore
                      .collection('AppLink')
                      .doc('getAppPlayStoreLink')
                      .get()
                      .then((snapshot) async {
                    var url = snapshot.data()['link'];
                    if (url == "not available") {
                      CoolAlert.show(
                        context: context,
                        type: CoolAlertType.info,
                        title: "Not Available!",
                        text: "This option will be available soon.",
                      );
                    } else {
                      // var url = snapshot.data()['link'];
                      // debugPrint('This is the url of the app' + url);
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        CoolAlert.show(
                          context: context,
                          type: CoolAlertType.warning,
                          title: "Invalid Url!",
                          text: "The url is not valid to launch.",
                        );
                      }
                    }
                  });
                } catch (e) {
                  CoolAlert.show(
                    context: context,
                    type: CoolAlertType.error,
                    title: "Sorry!",
                    text:
                        // e.toString(),
                        "An error occured.",
                  );
                }
                // try {
                // if (snapshot.data['link'] == "") {
                //   CoolAlert.show(
                //     context: context,
                //     type: CoolAlertType.info,
                //     title: "Not Available!",
                //     text: "This option will be available soon.",
                //   );
                // } else {
                //   var url = snapshot.data['link'];
                //   if (await canLaunch(url)) {
                //     await launch(url);
                //   } else {
                //     CoolAlert.show(
                //       context: context,
                //       type: CoolAlertType.warning,
                //       title: "Invalid Url!",
                //       text: "The url is not valid to launch.",
                //     );
                //   }
                // }
                // } catch (e) {
                // CoolAlert.show(
                //   context: context,
                //   type: CoolAlertType.error,
                //   title: "Sorry!",
                //   text: e.toString(),
                //   //  "An error occured. Come back later.",
                // );
                // }
              },
              leading: Icon(
                Icons.star_border,
                color: Colors.white,
                //Color(0xFF1c5162).withOpacity(0.6),
              ),
              title: Text(
                "Rate us",
                style: TextStyle(
                    color: Colors.white,
                    //Color(0xFF1c5162).withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: size * 12 / 100),
              ),
            )
            //   ;
            // })
            ,
            ListTile(
              onTap: () {
                try {
                  SignInServies signInServies = SignInServies();
                  FirebaseAuth auth = FirebaseAuth.instance;
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false);

                  signInServies.signOutGoogle();
                  auth.signOut();
                  userState.setVisitingFlag(value: 1);
                } catch (e) {
                  CoolAlert.show(
                    context: context,
                    type: CoolAlertType.error,
                    title: "Oops...",
                    text: "Sorry, something went wrong",
                  );
                }
              },
              leading: Icon(
                Icons.logout,
                color: Colors.white,
                // Color(0xFF1c5162).withOpacity(0.6),
              ),
              title: Text(
                "Log out",
                style: TextStyle(
                    color: Colors.white,
                    // Color(0xFF1c5162).withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: size * 12 / 100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
