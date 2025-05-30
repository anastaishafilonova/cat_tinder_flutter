import 'package:get_it/get_it.dart';
import 'package:lovecats/database.dart';
import 'package:lovecats/domain/repository/likes_repository.dart';
import 'package:lovecats/presentation/cubit/cat_cubit.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  getIt.registerLazySingleton<LikedCatsRepository>(
        () => LikedCatsRepository(getIt<AppDatabase>()),
  );

  getIt.registerFactory<CatCubit>(() => CatCubit(getIt<LikedCatsRepository>()));
}
