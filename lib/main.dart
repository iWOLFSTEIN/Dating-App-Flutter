import 'package:chat_app/Screens/AutoMatchScreen.dart';
import 'package:chat_app/Screens/EditProfileScreen.dart';
import 'package:chat_app/Screens/FavMatchScreen.dart';
import 'package:chat_app/Screens/HomeScreen.dart';
import 'package:chat_app/Screens/ImageHandlerScreen.dart';
import 'package:chat_app/Screens/StartScreen.dart';
import 'package:chat_app/Screens/UserImageViewer.dart';
import 'package:chat_app/Screens/UserProfile.dart';
import 'package:chat_app/Screens/UserSearchScreen.dart';
import 'package:chat_app/Services/DataProvider.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/Services/FirebaseProfilePicsModel.dart';
import 'package:chat_app/Services/FirebaseUserData.dart';
import 'package:chat_app/Services/UserState.dart';
import 'package:chat_app/pages/CallerScreen1.dart';
import 'package:chat_app/pages/ReceiverScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Screens/WelcomeScreen.dart';
import 'Screens/LoginScreen.dart';
import 'Screens/SignupScreen.dart';
import 'Screens/ConfirmEmaiScreen.dart';
import 'Screens/ChatsScreen.dart';
import 'Navigations/PagesNavController.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Screens/ConversationScreen.dart';
// import 'Screens/Facebook.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key key}) : super(key: key);

  // FirebaseGetUserData firebaseGetUserData = FirebaseGetUserData();
  // final auth = FirebaseAuth.instance;
  // FirebaseGetProfilePicsModel firebaseGetProfilePicsModel =
  //     FirebaseGetProfilePicsModel();

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  UserState userState = UserState();

  @override
  Widget build(BuildContext context) {
    return
        //  (auth != null)
        //     ?
        MultiProvider(
            providers: [
          ChangeNotifierProvider(create: (context) => DataProvider()),
        ],
            child: Container(
              color: Color(0xFF13293D),
              child: FutureBuilder(
                  future: userState.getVisitingFlag(),
                  builder: (context, snapshot) {
                    if (!(snapshot.hasData)) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      title: "Chatoo",
                      home: (snapshot.data == 0)
                          ? WelcomeScreen()
                          : (snapshot.data == 2)
                              ? PagesNavController()
                              : LoginScreen(),
                      // StartScreen(),
                      // AutoMatchScreen(),

                      // ConversationScreen()
                      //   ChatsScreen()
                      // (auth == null) ?
                      //LoginScreen()
                      //:
                      // PagesNavController()
                      //  UserSearchScreen(),
                      //ConfirmEmailScreen()
                      //   SignupScreen()
                      //   WelcomeScreen()
                      //  LoginScreen(),
                      // UserProfile(),
                      // EditProfileScreen(),
                      //  ImageHandlerScreen(),
                      // UserImageViewer(),
                      // HomeScreen(),
                      // ReceiverScreen()

                      // CallerScreen1(),

                      // CallerScreen2(),

                      //  FavMatchScreen(),
                    );
                  }),
            ));
  }
}
