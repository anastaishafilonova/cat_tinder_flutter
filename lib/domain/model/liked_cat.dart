import 'cat.dart';

class LikedCat {
  final Cat cat;
  final DateTime likedAt;

  LikedCat(this.cat, [DateTime? likedAt]) : likedAt = likedAt ?? DateTime.now();
}
