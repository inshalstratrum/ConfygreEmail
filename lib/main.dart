import 'package:Confygre_Email/models/oauth_model.dart';
import 'package:Confygre_Email/pages/oAuth_setting_page.dart';
import 'package:flutter/material.dart';

import 'components/objectBox.dart';
import 'objectbox.g.dart';
import 'pages/intro_screen_page.dart';
import 'pages/login_page.dart';
import 'components/GlobalVariables.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBox = await ObjectBox.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    bool toHome = true;
    Widget widget = OauthSettingPage();
    final OauthModel? oauthModel = objectBox?.getOAuthData();
    if (oauthModel != null) widget = LoginPage();
    if (!toHome) widget = IntroScreenPage();

    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF496A8F),
      brightness: Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Confygre Email',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          titleTextStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withOpacity(.55),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.primary, width: 2)),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          side: BorderSide.none,
        ),
        listTileTheme: const ListTileThemeData(minVerticalPadding: 8),
      ),
      home: widget,
    );
  }
}
