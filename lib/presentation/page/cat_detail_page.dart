import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CatDetailPage extends StatelessWidget {
  final String imageUrl;
  final String breed;
  final String description;

  const CatDetailPage({super.key, required this.imageUrl, required this.breed, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(title: Text(breed), backgroundColor: Colors.black38),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
            SizedBox(height: 20),
            Text(breed, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(description, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}