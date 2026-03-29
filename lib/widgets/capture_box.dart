import 'package:flutter/material.dart';

class CaptureBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 3),
        ),
      ),
    );
  }
}