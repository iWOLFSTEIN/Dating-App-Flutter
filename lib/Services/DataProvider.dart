import 'package:flutter/cupertino.dart';

class DataProvider with ChangeNotifier {
  int _incrementer = 0;
  int get incrementer => _incrementer;
  set incrementer(var value) {
    _incrementer = value;
    notifyListeners();
  }

  bool _refresher = false;
  bool get refresher => _refresher;
  set refresher(var value) {
    _refresher = value;
    notifyListeners();
  }

  bool _refresherUnblock = false;
  bool get refresherUnblock => _refresherUnblock;
  set refresherUnblock(var value) {
    _refresher = value;
    notifyListeners();
  }
}
