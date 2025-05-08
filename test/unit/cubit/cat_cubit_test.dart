import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lovecats/domain/model/cat.dart';
import 'package:lovecats/domain/model/liked_cat.dart';
import 'package:lovecats/domain/repository/likes_repository.dart';
import 'package:lovecats/presentation/cubit/cat_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockLikedCatsRepository extends Mock implements LikedCatsRepository {}

class FakeCatModel extends Fake implements CatModel {
  @override
  String get imageUrl => 'fake_url';
  @override
  String get breed => 'fake_breed';
  @override
  String get description => 'fake_description';
}

class FakeLikedCat extends Fake implements LikedCat {
  @override
  CatModel get cat => FakeCatModel();
}

void main() {
  late MockLikedCatsRepository mockRepository;

  final testCat = CatModel(
    'https://example.com/cat1.jpg',
    'Test Breed',
    'Test Description',
  );
  final testLikedCat = LikedCat(testCat);

  setUpAll(() {
    registerFallbackValue(FakeCatModel());
    registerFallbackValue(FakeLikedCat());
  });

  setUp(() {
    mockRepository = MockLikedCatsRepository();

    when(() => mockRepository.watchChanges()).thenAnswer((_) => const Stream.empty());
    when(() => mockRepository.getAll()).thenAnswer((_) async => []);
    when(() => mockRepository.getCounts()).thenAnswer((_) async => {'likes': 0, 'dislikes': 0});
    when(() => mockRepository.add(any())).thenAnswer((_) async {});
    when(() => mockRepository.dislike(any())).thenAnswer((_) async {});
    when(() => mockRepository.remove(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    reset(mockRepository);
  });

  group('CatCubit', () {
    blocTest<CatCubit, LikedCatsState>(
      'should initialize with empty state',
      build: () => CatCubit(mockRepository, skipInitialLoad: true),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockRepository.getAll());
        verifyNever(() => mockRepository.getCounts());
      },
    );

    blocTest<CatCubit, LikedCatsState>(
      'should dislike cat',
      build: () => CatCubit(mockRepository, skipInitialLoad: true),
      act: (cubit) => cubit.dislikeCat(testCat),
      verify: (_) {
        verify(() => mockRepository.dislike(testCat)).called(1);
      },
    );

    blocTest<CatCubit, LikedCatsState>(
      'should remove liked cat',
      build: () => CatCubit(mockRepository, skipInitialLoad: true),
      act: (cubit) => cubit.removeCat(testLikedCat),
      verify: (_) {
        verify(() => mockRepository.remove(testLikedCat)).called(1);
      },
    );

    blocTest<CatCubit, LikedCatsState>(
      'should handle repository errors',
      setUp: () {
        when(() => mockRepository.getAll()).thenThrow(Exception('DB Error'));
      },
      build: () => CatCubit(mockRepository, skipInitialLoad: true),
      act: (cubit) => cubit.refreshState(),
      errors: () => [isA<Exception>()],
    );
  });
}
