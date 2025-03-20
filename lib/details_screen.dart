import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DetailsScreen extends StatelessWidget {
  final String imageUrl;
  final String breedName;
  final String description;

  const DetailsScreen({super.key, required this.imageUrl, required this.breedName, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(breedName)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(description, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
