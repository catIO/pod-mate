import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';

import 'router.dart';

const _seedColor = Color(0xFF6750A4);

class PodMateApp extends StatelessWidget {
  const PodMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp.router(
        title: 'Pod-Mate',
        theme: ThemeData(
          colorScheme:
              lightDynamic ?? ColorScheme.fromSeed(seedColor: _seedColor),
        ),
        darkTheme: ThemeData(
          colorScheme:
              darkDynamic ??
              ColorScheme.fromSeed(
                seedColor: _seedColor,
                brightness: Brightness.dark,
              ),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
