import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/model/cat.dart';
import '../../domain/model/liked_cat.dart';
import '../../domain/repository/likes_repository.dart';

@injectable
class CatCubit extends Cubit<LikedCatsState> {
  final LikedCatsRepository _repository;
  StreamSubscription? _dbSubscription;

  CatCubit(this._repository) : super(LikedCatsState([], 0, 0)) {
    _setupDbListener();
    _loadInitialData();
  }

  void _setupDbListener() {
    _dbSubscription = _repository.watchChanges().listen((_) {
      _refreshState();
    });
  }

  Future<void> _loadInitialData() async {
    await _refreshState();
  }

  Future<void> _refreshState() async {
    final liked = await _repository.getAll();
    final counts = await _repository.getCounts();

    emit(LikedCatsState(
      liked,
      counts['likes'] ?? 0,
      counts['dislikes'] ?? 0,
    ));
  }

  @override
  Future<void> close() {
    _dbSubscription?.cancel();
    return super.close();
  }

  Future<void> likeCat(CatModel cat) async {
    await _repository.add(LikedCat(cat));
    await _refreshState();
  }

  Future<void> dislikeCat(CatModel cat) async {
    await _repository.dislike(cat);
    await _refreshState();
  }

  Future<void> removeCat(LikedCat cat) async {
    await _repository.remove(cat);
    await _refreshState();
  }

  Future<void> restoreFrom(List<LikedCat> updatedList) async {
    await _repository.updateAll(updatedList);
    await _refreshState();
  }

  Future<void> refreshState() async {
    await _refreshState();
  }
}

class LikedCatsState {
  final List<LikedCat> likedCats;
  final int likeCount;
  final int dislikeCount;

  LikedCatsState(this.likedCats, this.likeCount, this.dislikeCount);
}