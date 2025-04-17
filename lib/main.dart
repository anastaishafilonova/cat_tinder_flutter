import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lovecats/presentation/cubit/cat_cubit.dart';
import 'package:lovecats/presentation/page/cat_home_page.dart';
import 'package:lovecats/utils/service_locator.dart';

Future<void> main() async {
  configureDependencies();
  await dotenv.load(fileName: ".env");

  runApp(BlocProvider(create: (_) => getIt<CatCubit>(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat Tinder',
      theme: ThemeData(scaffoldBackgroundColor: Colors.grey[100]),
      home: const CatHomePage(),
    );
  }
}
