import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hacktrack/auth/auth_wrapper.dart';
import 'firebase_options.dart';
import 'package:cloudinary_flutter/image/cld_image.dart';
import 'package:cloudinary_flutter/cloudinary_object.dart';

late CloudinaryObject cloudinary;
void main() async {
  cloudinary = CloudinaryObject.fromCloudName(cloudName: 'dteigt5oc');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hackathon Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF388E3C),
          background: const Color(0xFF121212),
          surface: const Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(), // Only use home, remove initialRoute
    );
  }
}