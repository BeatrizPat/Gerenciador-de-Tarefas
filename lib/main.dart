import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_trabalho_final/app_localizations.dart';
import 'package:flutter_trabalho_final/login_screen.dart';
import 'package:flutter_trabalho_final/firebase_options.dart';
import 'package:flutter_trabalho_final/app_screen.dart';
import 'dart:math';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MainAppState? state = context.findAncestorStateOfType<_MainAppState>();
    state?.setLocale(newLocale);
  }

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Locale _locale = const Locale('en', 'US');
  ThemeMode _themeMode = ThemeMode.light;
  Color _themeColor = const Color.fromARGB(255, 209, 215, 219);

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.system;
        _themeColor = Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
      } else {
        _themeMode = ThemeMode.light;
        _themeColor = const Color.fromARGB(118, 200, 209, 209);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      themeMode: _themeMode,
      theme: ThemeData.light().copyWith(primaryColor: _themeColor),
      darkTheme: ThemeData.dark().copyWith(primaryColor: _themeColor),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('pt', 'BR'),
        const Locale('es', 'ES'),
      ],
      home: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.translate('gerenciador')),
          backgroundColor: _themeColor,
          actions: [
            IconButton(
              icon: Icon(_themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
              onPressed: toggleTheme,
            ),
          ],
          
        ),
        body: Column(children: [
          LoginScreen(),
          SizedBox(height: 40),
          Text(AppLocalizations.of(context)!.translate('feito_por')),
          SizedBox(height: 10),
          Text("Beatriz Patricio Santos"),
          Text("Carlos Henrique de França")
        ],),
        
      ),
    );
  }
}
