import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/model/liked_cat.dart';
import '../../utils/service_locator.dart';
import '../cubit/cat_cubit.dart';
import 'cat_detail_page.dart';

class LikedCatsPage extends StatelessWidget {
  const LikedCatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CatCubit>(),
      child: BlocBuilder<CatCubit, LikedCatsState>(
        builder: (context, state) {
          return _LikedCatsContent(likedCats: state.likedCats);
        },
      ),
    );
  }
}

class _LikedCatsContent extends StatefulWidget {
  final List<LikedCat> likedCats;

  const _LikedCatsContent({required this.likedCats});

  @override
  State<_LikedCatsContent> createState() => _LikedCatsPageState();
}

class _LikedCatsPageState extends State<_LikedCatsContent> {
  String selectedBreed = 'All';

  List<LikedCat> get filteredCats {
    if (selectedBreed == 'All') return widget.likedCats;
    return widget.likedCats.where((c) => c.cat.breed == selectedBreed).toList();
  }

  @override
  void didUpdateWidget(covariant _LikedCatsContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.likedCats.isEmpty && selectedBreed != 'All') {
      setState(() {
        selectedBreed = 'All';
      });
    }

    final breeds = widget.likedCats.map((e) => e.cat.breed).toSet();
    if (selectedBreed != 'All' && !breeds.contains(selectedBreed)) {
      setState(() {
        selectedBreed = 'All';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allBreeds = LinkedHashSet<String>(
      equals: (a, b) => a == b,
      hashCode: (s) => s.hashCode,
    )..add('All')..addAll(
      widget.likedCats
          .map((e) => e.cat.breed)
          .cast<String>(),
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Liked Cats'),
          backgroundColor: Colors.black54,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/background_1.jpg', fit: BoxFit.cover),
            Container(color: Color.fromRGBO(0, 0, 0, 0.3)),
            Column(
              children: [
                const SizedBox(height: 20),
                if (widget.likedCats.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 100),
                    decoration: BoxDecoration(
                      color: Colors.white60,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
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
                            child: Text(
                              breed,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: widget.likedCats.isEmpty
                      ? const Center(
                    child: Text(
                      'No liked cats yet',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  )
                      : ListView.builder(
                    itemCount: filteredCats.length,
                    itemBuilder: (context, index) {
                      final likedCat = filteredCats[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CatDetailPage(
                                imageUrl: likedCat.cat.imageUrl,
                                breed: likedCat.cat.breed,
                                description: likedCat.cat.description,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                    ),
                                    errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        likedCat.cat.breed,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                  onPressed: () async {
                                    await context
                                        .read<CatCubit>()
                                        .removeCat(likedCat);
                                  },
                                ),
                              ],
                            ),
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