import 'package:flutter/material.dart';
import 'dart:math';

class Fish {
  Color color; // Removed 'final' to allow color change
  final double speed;
  Offset position;
  Random random = Random();

  Fish({required this.color, required this.speed})
      : position = Offset(150, 150); // Initial position in the center

  void moveFish() {
    // Logic for moving the fish
    double dx = random.nextDouble() * 2 - 1;
    double dy = random.nextDouble() * 2 - 1;
    position = Offset(position.dx + dx * speed, position.dy + dy * speed);
  }

  void changeDirection() {
    // Logic for changing direction when a collision occurs
  }

  Widget buildFish() {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}