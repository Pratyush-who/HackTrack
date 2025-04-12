import 'package:flutter/material.dart';
import 'package:hacktrack/unknownScreen.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      default:
        return MaterialPageRoute(builder: (_) => UnknownScreen());
    }
  }
}
