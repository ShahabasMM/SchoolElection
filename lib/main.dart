import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/candidate_manager.dart';
import 'screens/control_screen.dart';
import 'screens/division_manager.dart';
import 'screens/hss_manager.dart';
import 'screens/home_screen.dart';
import 'services/election_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  final controller = ElectionController();
  await controller.load();

  runApp(ElectionApp(controller: controller));
}

class ElectionApp extends StatelessWidget {
  final ElectionController controller;
  const ElectionApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GHSS EVM',
      theme: appTheme(),
      routes: {
        '/home': (_) => HomeScreen(controller: controller),
        '/control': (_) => ControlScreen(controller: controller),
        '/candidate-manager': (_) => CandidateManager(controller: controller),
        '/division-manager': (_) => DivisionManager(controller: controller),
        '/hss-manager': (_) => HssManager(controller: controller),
      },
      home: HomeScreen(controller: controller),
    );
  }
}
