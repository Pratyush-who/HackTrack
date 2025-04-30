import 'package:flutter/material.dart';

class PrivatePostPage extends StatelessWidget {
  const PrivatePostPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Post'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'This is the Private Post Page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}