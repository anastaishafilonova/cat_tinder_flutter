import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'domain/model/cat.dart';
part 'database.g.dart';

class Cats extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get imageUrl => text().customConstraint('UNIQUE')();
  TextColumn get breed => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(Constant('none'))(); // 'liked', 'disliked', 'none'
}

@DriftDatabase(tables: [Cats])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<CatModel>> getAllCats() async {
    final dbCats = await select(cats).get();
    return dbCats.map((dbCat) => CatModel(
      dbCat.imageUrl,
      dbCat.breed ?? 'Неизвестная порода',
      dbCat.description ?? 'Нет описания',
    )).toList();
  }

  Future<List<CatModel>> getLikedCats() async {
    final dbCats = await (select(cats)..where((t) => t.status.equals('liked'))).get();
    return dbCats.map((dbCat) => CatModel(
      dbCat.imageUrl,
      dbCat.breed ?? 'Неизвестная порода',
      dbCat.description ?? 'Нет описания',
    )).toList();
  }

  Future<void> insertOrUpdateCat(CatModel cat) async {
    await into(cats).insertOnConflictUpdate(
      CatsCompanion(
        imageUrl: Value(cat.imageUrl),
        breed: Value(cat.breed),
        description: Value(cat.description),
        status: const Value('none'),
      ),
    );
  }

  Future<void> updateCatStatus(String imageUrl, String status) async {
    await (update(cats)..where((t) => t.imageUrl.equals(imageUrl)))
        .write(CatsCompanion(status: Value(status)));
  }

  Future<bool> isCatLiked(String imageUrl) async {
    final cat = await (select(cats)..where((t) => t.imageUrl.equals(imageUrl))).getSingleOrNull();
    return cat?.status == 'liked';
  }

  Future<List<Cat>> getAllCatsWithStatus() async {
    final dbCats = await select(cats).get();
    return dbCats;
  }

  Future<void> clearDatabase() async {
    await delete(cats).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cats.db'));
    return NativeDatabase(file);
  });
}
