import 'cat.dart';

class LikedCat {
  final CatModel cat;

  LikedCat(this.cat);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is LikedCat &&
              runtimeType == other.runtimeType &&
              cat == other.cat;

  @override
  int get hashCode => cat.hashCode;

  @override
  String toString() {
    return 'LikedCat{cat: $cat}';
  }
}
