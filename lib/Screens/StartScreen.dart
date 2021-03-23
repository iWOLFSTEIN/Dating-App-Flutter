import 'package:flutter/material.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({Key key}) : super(key: key);

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: Color(0xFF13293D),
        alignment: Alignment.center,
        child: Container(
          height: height * 15 / 100,
          width: width * 30 / 100,
          child: Center(
            child: Image.asset('images/appIcon.png'),
          ),
        ),
      ),
    );
  }
}
