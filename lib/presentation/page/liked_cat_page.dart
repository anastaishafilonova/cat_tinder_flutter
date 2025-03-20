import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/model/liked_cat.dart';
import '../../utils/service_locator.dart';
import '../cubit/cat_cubit.dart';

class LikedCatsPage extends StatefulWidget {
  final List<LikedCat> likedCats;

  const LikedCatsPage({super.key, required this.likedCats});

  @override
  State<LikedCatsPage> createState() => _LikedCatsPageState();
}

class _LikedCatsPageState extends State<LikedCatsPage> {
  String selectedBreed = 'All';
  late List<LikedCat> localLikedCats;

  @override
  void initState() {
    super.initState();
    localLikedCats = List.from(widget.likedCats);
  }

  List<LikedCat> get filteredCats {
    if (selectedBreed == 'All') return localLikedCats;
    return localLikedCats.where((c) => c.cat.breed == selectedBreed).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allBreeds = ['All', ...{...localLikedCats.map((e) => e.cat.breed)}];

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, localLikedCats);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Liked Cats'), backgroundColor: Colors.black54),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/background_1.jpg',
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withOpacity(0.3)),
            Column(
              children: [
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 100),
                  decoration: BoxDecoration(
                    color: Colors.white60,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: DropdownMenuTheme(
                    data: DropdownMenuThemeData(
                      menuStyle: MenuStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.white60),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBreed,
                        onChanged: (value) {
                          setState(() {
                            selectedBreed = value!;
                          });
                        },
                        items: allBreeds.map((breed) {
                          return DropdownMenuItem(
                            value: breed,
                            child: Text(breed),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredCats.length,
                    itemBuilder: (context, index) {
                      final likedCat = filteredCats[index];
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white60,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: likedCat.cat.imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      likedCat.cat.breed,
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Liked on: ${likedCat.likedAt.toLocal().toString().split(' ')[0]}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red, size: 32),
                                onPressed: () {
                                  setState(() {
                                    localLikedCats.remove(likedCat);
                                    getIt<CatCubit>().removeCat(likedCat);

                                    if (selectedBreed != 'All' &&
                                        !localLikedCats.any((cat) => cat.cat.breed == selectedBreed)) {
                                      selectedBreed = 'All';
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}