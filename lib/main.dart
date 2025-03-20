import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';

var logger = Logger();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat Tinder',
      theme: ThemeData(scaffoldBackgroundColor: Colors.grey),
      home: CatHomePage(),
    );
  }
}

class CatHomePage extends StatefulWidget {
  const CatHomePage({super.key});

  @override
  CatHomePageState createState() => CatHomePageState();
}

class Cat {
  String imageUrl = '';
  String breed = '';
  String description = '';


  Cat(this.imageUrl, this.breed, this.description);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Cat && runtimeType == other.runtimeType &&
              imageUrl == other.imageUrl;

  @override
  int get hashCode => imageUrl.hashCode;


}

class CatHomePageState extends State<CatHomePage> {
  String imageUrl = '';
  String breed = '';
  String description = '';
  int likeCount = 0;
  Set<Cat> cats = {};

  @override
  void initState() {
    super.initState();
    fetchRandomCat();
  }

  void precacheCatImages() {
    for (var cat in cats) {
      precacheImage(NetworkImage(cat.imageUrl), context);
    }
  }

  Future<void> fetchRandomCat() async {
    final myApiKey = "live_Th9rVfzEYMG0TtGVQYuLwwzrmBOFdVeGZ0f9pZMtZUZ0h09mXmQ88Pn38bu9jkcN";
    if (cats.isEmpty) {
      try {
        final response = await http.get(
          Uri.parse(
              'https://api.thecatapi.com/v1/images/search?limit=5&has_breeds=1'),
          headers: {'x-api-key': myApiKey},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);

          if (data.isNotEmpty) {
            for (var item in data) {
              if (item['breeds'] != null && item['breeds'].isNotEmpty) {
                cats.add(Cat(
                  item['url'],
                  item['breeds'][0]['name'],
                  item['breeds'][0]['description'],
                ));
              }
            }
            precacheCatImages();
          }
        } else {
          throw Exception('Request error: ${response.statusCode}');
        }
      } catch (e) {
        logger.log(Logger.level, 'Cat downloading error: $e');
      }
    }

    if (cats.isNotEmpty) {
      Cat cat = cats.first;
      setState(() {
        imageUrl = cat.imageUrl;
        breed = cat.breed;
        description = cat.description;
      });
      cats.remove(cat);
    }
  }



  void likeCat() {
    setState(() {
      likeCount++;
    });
    fetchRandomCat();
  }

  void dislikeCat() {
    fetchRandomCat();
  }

  void openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatDetailPage(imageUrl: imageUrl, breed: breed, description: description),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(title: Text('Cat Tinder')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: openDetails,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                likeCat();
              } else if (details.primaryVelocity! < 0) {
                dislikeCat();
              }
            },
            child: Stack(
              children: [
                Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                        ],
                        stops: [0, 0.7]
                      ),
                    ),
                    padding: EdgeInsets.all(10),
                    child: Text(
                      breed,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              LikeButton(onPressed: dislikeCat, icon: SvgPicture.asset('assets/dislike.svg')),
              LikeButton(onPressed: likeCat, icon: SvgPicture.asset('assets/like.svg')),
            ],
          ),
          SizedBox(height: 10),
          Text("Likes: $likeCount", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
        ],
      ),
    );
  }
}

class LikeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final SvgPicture icon;

  const LikeButton({super.key, required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      iconSize: 34,
      onPressed: onPressed,
    );
  }
}

class CatDetailPage extends StatelessWidget {
  final String imageUrl;
  final String breed;
  final String description;

  const CatDetailPage({super.key, required this.imageUrl, required this.breed, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(breed)),
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
            Text(description, style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
          ],
        ),
      )
    );
  }
}
