import 'package:flutter/widgets.dart';

class FadePageRoute extends PageRouteBuilder {
  final Widget widget;

  FadePageRoute(this.widget)
      : super(
            transitionDuration: Duration(milliseconds: 300),
            pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) {
              return widget;
            },
            transitionsBuilder: ((BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
                Widget child) {
              return SlideTransition(
                  position: Tween<Offset>(begin: Offset(1, 1), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: animation, curve: Curves.linear)),
                  child: child);
            }));
}
