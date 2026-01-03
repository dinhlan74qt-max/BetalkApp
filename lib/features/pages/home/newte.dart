import 'package:flutter/material.dart';

class NewTest extends StatefulWidget {
  const NewTest({super.key});

  @override
  State<NewTest> createState() => _NewTestState();
}

class _NewTestState extends State<NewTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:Text('TestPage Post'),
      ),
    );;
  }
}
