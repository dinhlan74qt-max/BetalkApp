import 'package:flutter/material.dart';

class TestPage extends StatefulWidget {
  final String userId;
  const TestPage({super.key, required this.userId});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:Text('TestPage'),
      ),
    );
  }
}
