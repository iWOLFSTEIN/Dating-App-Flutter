import 'package:chat_app/Services/UserState.dart';
import 'package:flutter/material.dart';
import 'LoginScreen.dart';

class WelcomeScreen extends StatefulWidget {
  WelcomeScreen({Key key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  UserState userState = UserState();

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;

    return Scaffold(
      backgroundColor: Color(0xFF13293D),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(height: heigth * 20 / 100, width: width),
          Image.asset(
            'images/appIcon.png',
            height: heigth / 2.7,
            width: width / 1.7,
          ),
          Text(
            "Welcome to CA!",
            style: TextStyle(
              fontFamily: 'Mulish',
              fontSize: size / 6.5,
              color: Colors.white,
            ),
          ),
          Padding(
            padding:
                EdgeInsets.only(left: width * 6 / 100, right: width * 6 / 100),
            child: Text(
                "A platform to meet new people and make new friends. Chat, Flirt, Date and Enjoy!",
                style: TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: size / 14.5,
                  color: Colors.white,
                )),
          ),
          Container(
            height: heigth * 10 / 100,
          ),
          FlatButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ));
                userState.setVisitingFlag(value: 1);
              },
              child: Container(
                  height: heigth * 7 / 100,
                  color: Color(0xFF20D5B7),
                  child: Center(
                      child: Text(
                    "Get Started!",
                    style: TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: size / 14.5,
                    ),
                  )))),
          Container(
            height: heigth * 0.5 / 100,
          ),
        ],
      ),
    );
  }
}
