import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/theme/app_theme.dart';
import 'src/routing/app_router.dart';
import 'src/data/off/off_auth.dart';
import 'src/data/off/off_config.dart';
import 'src/data/fooddb_repository.dart';
import 'src/data/prefs/prefs_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  OffConfig.init();
  runApp(const EatInsightApp());
}

class EatInsightApp extends StatelessWidget {
  const EatInsightApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createRouter();
    return MultiProvider(
      providers: [
        Provider<FoodDbRepository>(create: (_) => FoodDbRepository()),
        ChangeNotifierProvider<OffAuth>(create: (_) => OffAuth()..init()),
        ChangeNotifierProvider(create: (_) => PrefsController(PrefsRepository())..load()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'EATINSIGHT',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
