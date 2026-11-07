import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/repository.dart';
import 'ui/controller.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  await initializeDateFormatting('tr_TR');
  runApp(const TokatEzanApp());
}

class TokatEzanApp extends StatefulWidget {
  const TokatEzanApp({super.key});

  @override
  State<TokatEzanApp> createState() => _TokatEzanAppState();
}

class _TokatEzanAppState extends State<TokatEzanApp> {
  late final PrayerController controller =
      PrayerController(PrayerRepository())..start();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vakt-i Salât',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeShell(controller: controller),
    );
  }
}
