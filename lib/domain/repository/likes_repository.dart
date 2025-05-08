import '../../database.dart';
import '../model/cat.dart';
import '../model/liked_cat.dart';

class LikedCatsRepository {
  final AppDatabase _db;

  LikedCatsRepository(this._db);

  Future<List<LikedCat>> getAll() async {
    final cats = await _db.getLikedCats();
    return cats.map((cat) => LikedCat(cat)).toList();
  }

  Future<void> remove(LikedCat cat) async {
    await _db.updateCatStatus(cat.cat.imageUrl, 'none');
  }

  Future<void> add(LikedCat likedCat) async {
    await _db.updateCatStatus(likedCat.cat.imageUrl, 'liked');
  }

  Future<void> dislike(CatModel cat) async {
    await _db.updateCatStatus(cat.imageUrl, 'disliked');
  }

  Future<void> updateAll(List<LikedCat> newList) async {
    final allCats = await _db.getAllCats();
    for (final cat in allCats) {
      final status = newList.any((lc) => lc.cat.imageUrl == cat.imageUrl)
          ? 'liked'
          : 'none';
      await _db.updateCatStatus(cat.imageUrl, status);
    }
  }

  Future<List<Cat>> getAllFromDb() async {
    return await _db.getAllCatsWithStatus();
  }

  Future<Map<String, int>> getCounts() async {
    return await _db.getLikeDislikeCounts();
  }

  Stream<void> watchChanges() {
    return _db.watchChanges();
  }
}
