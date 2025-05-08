import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../../database.dart';
import '../../domain/model/cat.dart';
import '../../domain/model/liked_cat.dart';
import '../../utils/logger.dart';
import '../../utils/service_locator.dart';
import '../cubit/cat_cubit.dart';
import 'cat_detail_page.dart';
import 'liked_cat_page.dart';

final db = AppDatabase();

class CatHomePage extends StatefulWidget {
  const CatHomePage({super.key});

  @override
  CatHomePageState createState() => CatHomePageState();
}

class CatHomePageState extends State<CatHomePage> {
  String imageUrl = '';
  String breed = '';
  String description = '';
  bool isLoading = false;
  bool isLiking = false;
  bool showImage = false;
  Queue<CatModel> catQueue = Queue<CatModel>();
  StreamSubscription<LikedCatsState>? _cubitSubscription;

  @override
  void initState() {
    super.initState();
    _initCats();
  }

  void _initCats() {
    printAllCatsWithStatusAndBreed();
    fetchMoreCats().then((_) => fetchNextCat());
  }

  void _setupCubitListener() {
    _cubitSubscription = getIt<CatCubit>().stream.listen((state) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _cubitSubscription?.cancel();
    super.dispose();
  }

  int get likeCount => BlocProvider.of<CatCubit>(context).state.likeCount;
  int get dislikeCount => BlocProvider.of<CatCubit>(context).state.dislikeCount;
  List<LikedCat> get likedCats => getIt<CatCubit>().state.likedCats;

  void likeCat() {
    if (isLiking || imageUrl.isEmpty) return;

    setState(() => isLiking = true);
    final cat = CatModel(imageUrl, breed, description);
    getIt<CatCubit>().likeCat(cat).whenComplete(() {
      if (mounted) {
        setState(() => isLiking = false);
        print('Liked cat, new likeCount: $likeCount');
        fetchNextCat();
      }
    });
  }

  void dislikeCat() {
    if (isLiking || imageUrl.isEmpty) return;

    setState(() => isLiking = true);
    final cat = CatModel(imageUrl, breed, description);
    getIt<CatCubit>().dislikeCat(cat).whenComplete(() {
      if (mounted) {
        setState(() => isLiking = false);
        fetchNextCat();
      }
    });
  }

  Future<void> printAllCatsWithStatusAndBreed() async {
    final db = AppDatabase(); // Или используйте ваш экземпляр базы данных
    final allCats = await db.getAllCatsWithStatus(); // Используем существующий метод
    if (allCats.isEmpty) {
      print('В базе данных нет котов');
      return;
    }

    print('\nСписок всех котов в базе данных:');
    print('--------------------------------');
    print('| №  | Статус      | Порода              | URL изображения');
    print('--------------------------------');

    int counter = 1;
    for (final cat in allCats) {
      final status = cat.status ?? 'none';
      final breed = cat.breed ?? 'Неизвестная порода';
      final url = cat.imageUrl.length > 30
          ? '${cat.imageUrl.substring(0, 27)}...'
          : cat.imageUrl;

      print('| ${counter.toString().padLeft(2)} | ${status.padRight(10)} | ${breed.padRight(18)} | $url');
      counter++;
    }

    print('--------------------------------');
    print('Всего котов: ${allCats.length}');
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
        Uri.parse(
          'https://api.thecatapi.com/v1/images/search?limit=6&has_breeds=1&size=small&mime_types=jpg',
        ),
        headers: {'x-api-key': myApiKey},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var item in data) {
          if (item['breeds'] != null && item['breeds'].isNotEmpty) {
            final cat = CatModel(
              item['url'],
              item['breeds'][0]['name'],
              item['breeds'][0]['description'],
            );
            if (!catQueue.contains(cat)) {
              catQueue.add(cat);
              await db.insertOrUpdateCat(cat);
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
        showErrorDialog(
          'Не удалось загрузить котиков. Проверьте соединение с интернетом.',
        );
      }
    }
  }

  void openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CatDetailPage(
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
        builder:
            (context) =>
                LikedCatsPage(),
      ),
    );

    getIt<CatCubit>().refreshState();
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
    return BlocBuilder<CatCubit, LikedCatsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('Cat Tinder'),
            backgroundColor: Colors.grey,
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.favorite, color: Colors.black54, size: 24),
                onPressed: openLikedCatsPage,
                label: const Text(
                  'Favourites',
                  style: TextStyle(fontSize: 24, color: Colors.black54),
                ),
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/background_1.jpg', fit: BoxFit.cover),
              Container(color: Colors.black.withAlpha((255 * 0.3).round())),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading || imageUrl.isEmpty)
                    const CircularProgressIndicator()
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
                            duration: const Duration(milliseconds: 500),
                            opacity: showImage ? 1.0 : 0.0,
                            child: Container(
                              height: 420,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
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
                                      placeholder: (context, url) =>
                                      const Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
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
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 6,
                                            ),
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
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          IconButton(
                            onPressed: dislikeCat,
                            icon: const Icon(
                              Icons.heart_broken,
                              color: Colors.red,
                              size: 64,
                            ),
                          ),
                          Text(
                            "${state.dislikeCount}",
                            style: const TextStyle(fontSize: 32, color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: likeCat,
                            icon: const Icon(
                              Icons.favorite,
                              color: Colors.green,
                              size: 64,
                            ),
                          ),
                          Text(
                            "${state.likeCount}",
                            style: const TextStyle(fontSize: 32, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
