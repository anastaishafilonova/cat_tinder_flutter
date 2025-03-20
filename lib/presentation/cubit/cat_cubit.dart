import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:lovecats/domain/repository/likes_repository.dart';
import '../../domain/model/cat.dart';
import '../../domain/model/liked_cat.dart';

class LikedCatsState {
  final List<LikedCat> likedCats;

  LikedCatsState(this.likedCats);
}

@injectable
class CatCubit extends Cubit<LikedCatsState> {
  final LikedCatsRepository repository;

  CatCubit(this.repository) : super(LikedCatsState(repository.getAll()));

  void likeCat(Cat cat) {
    repository.add(LikedCat(cat, DateTime.now()));
    emit(LikedCatsState(repository.getAll()));
  }

  void removeCat(LikedCat likedCat) {
    repository.remove(likedCat);
    emit(LikedCatsState(repository.getAll()));
  }

  void restoreFrom(List<LikedCat> updatedList) {
    repository.updateAll(updatedList);
    emit(LikedCatsState(repository.getAll()));
  }
}
