import '../model/liked_cat.dart';

class LikedCatsRepository {
  final List<LikedCat> _likedCats = [];

  List<LikedCat> getAll() => List.unmodifiable(_likedCats);

  void add(LikedCat likedCat) {
    _likedCats.add(likedCat);
  }

  void remove(LikedCat likedCat) {
    _likedCats.remove(likedCat);
  }

  void updateAll(List<LikedCat> newList) {
    _likedCats
      ..clear()
      ..addAll(newList);
  }
}
