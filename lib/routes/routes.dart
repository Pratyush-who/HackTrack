import 'package:flutter/material.dart';
import 'package:hacktrack/auth/auth_wrapper.dart';
import 'package:hacktrack/auth/login.dart';
import 'package:hacktrack/auth/signup.dart';
import 'package:hacktrack/screens/HomeScreen.dart';
import 'package:hacktrack/screens/unknownScreen.dart';

class Routes {
  static const String initial = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      default:
        return MaterialPageRoute(builder: (_) => const UnknownScreen());
    }
  }
}