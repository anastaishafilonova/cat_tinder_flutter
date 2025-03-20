import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/model/cat.dart';
import '../../domain/model/liked_cat.dart';
import '../../utils/logger.dart';
import '../../utils/service_locator.dart';
import '../cubit/cat_cubit.dart';
import 'cat_detail_page.dart';
import 'liked_cat_page.dart';

class CatHomePage extends StatefulWidget {
  const CatHomePage({super.key});

  @override
  CatHomePageState createState() => CatHomePageState();
}

class CatHomePageState extends State<CatHomePage> {
  String imageUrl = '';
  String breed = '';
  String description = '';
  int likeCount = 0;
  int dislikeCount = 0;
  List<LikedCat> likedCats = [];
  bool isLoading = false;
  bool isLiking = false;
  bool showImage = false;
  Queue<Cat> catQueue = Queue<Cat>();

  @override
  void initState() {
    super.initState();
    fetchMoreCats().then((_) => fetchNextCat());
  }

  Future<void> fetchNextCat() async {
    if (catQueue.isEmpty) {
      fetchMoreCats();
      return;
    }

    final cat = catQueue.removeFirst();
    setState(() {
      imageUrl = cat.imageUrl;
      breed = cat.breed;
      description = cat.description;
      showImage = false;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      setState(() => showImage = true);
    });

    if (catQueue.length < 2) {
      fetchMoreCats();
    }
  }

  Future<void> fetchMoreCats() async {
    final myApiKey = dotenv.env['API_KEY'] ?? '';

    try {
      final response = await http.get(
        Uri.parse('https://api.thecatapi.com/v1/images/search?limit=6&has_breeds=1&size=small&mime_types=jpg'),
        headers: {'x-api-key': myApiKey},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var item in data) {
          if (item['breeds'] != null && item['breeds'].isNotEmpty) {
            final cat = Cat(
                item['url'],
                item['breeds'][0]['name'],
                item['breeds'][0]['description']
            );
            if (!catQueue.contains(cat)) {
              catQueue.add(cat);
              precacheImage(NetworkImage(cat.imageUrl), context);
            }
          }
        }
      } else {
        throw Exception('Ошибка API: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Ошибка загрузки: $e');
      if (mounted) {
        showErrorDialog('Не удалось загрузить котиков. Проверьте соединение с интернетом.');
      }
    }
  }


  void likeCat() {
    if (isLiking || imageUrl.isEmpty) return;

    setState(() {
      isLiking = true;
      likeCount++;
    });

    final cat = Cat(imageUrl, breed, description);
    getIt<CatCubit>().likeCat(cat);

    fetchNextCat().then((_) {
      setState(() => isLiking = false);
    });
  }

  void dislikeCat() {
    if (isLiking || imageUrl.isEmpty) return;

    setState(() {
      isLiking = true;
      dislikeCount++;
    });

    fetchNextCat().then((_) {
      setState(() => isLiking = false);
    });
  }

  void openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatDetailPage(
          imageUrl: imageUrl,
          breed: breed,
          description: description,
        ),
      ),
    );
  }

  void openLikedCatsPage() async {
    final updatedLikedCats = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LikedCatsPage(
          likedCats: getIt<CatCubit>().state.likedCats,
        ),
      ),
    );

    if (updatedLikedCats != null) {
      getIt<CatCubit>().restoreFrom(updatedLikedCats);
      setState(() {
        likedCats = updatedLikedCats;
        likeCount = likedCats.length;
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ошибка сети'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ОК'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Cat Tinder'),
        backgroundColor: Colors.grey,
        actions: [
          TextButton.icon(
            icon: Icon(Icons.favorite, color: Colors.black54, size: 24),
            onPressed: openLikedCatsPage,
            label: Text('Favourites', style: TextStyle(fontSize: 24, color: Colors.black54)),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background_1.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withAlpha((255 * 0.3).round())),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading || imageUrl.isEmpty)
                CircularProgressIndicator()
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Dismissible(
                    key: Key(imageUrl),
                    direction: DismissDirection.horizontal,
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        likeCat();
                      } else {
                        dislikeCat();
                      }
                    },
                    child: GestureDetector(
                      onTap: openDetails,
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: 500),
                        opacity: showImage ? 1.0 : 0.0,
                        child: Container(
                          height: 420,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => Icon(Icons.error),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withAlpha((255 * 0.6).round()),
                                        Colors.transparent,
                                        Colors.black.withAlpha((255 * 0.8).round()),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 20,
                                  left: 20,
                                  right: 20,
                                  child: Text(
                                    breed,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(color: Colors.black54, blurRadius: 6),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        onPressed: dislikeCat,
                        icon: Icon(Icons.heart_broken, color: Colors.red, size: 64),
                      ),
                      Text("$dislikeCount", style: TextStyle(fontSize: 32, color: Colors.white)),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: likeCat,
                        icon: Icon(Icons.favorite, color: Colors.green, size: 64),
                      ),
                      Text("$likeCount", style: TextStyle(fontSize: 32, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
