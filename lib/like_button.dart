import 'package:flutter/material.dart';

class LikeButton extends StatelessWidget {
  final bool isLike;
  final VoidCallback onPressed;

  const LikeButton({super.key, required this.isLike, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(20),
        backgroundColor: isLike ? Colors.green : Colors.red,
      ),
      child: Icon(isLike ? Icons.thumb_up : Icons.thumb_down, color: Colors.white),
    );
  }
}
