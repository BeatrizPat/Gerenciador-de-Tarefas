import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_trabalho_final/app_localizations.dart';
import 'package:flutter_trabalho_final/login_screen.dart';
import 'package:flutter_trabalho_final/firebase_options.dart';
import 'package:flutter_trabalho_final/app_screen.dart';

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

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
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
          title: Text("Gerenciador de Tarefas - Login"),
          actions: [
            IconButton(
              icon: Icon(_themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
              onPressed: toggleTheme,
            ),
          ],
        ),
        // body: Center(
        //   child: LoginScreen(),
        // ),
        body: Column(children: [
          LoginScreen(),
          SizedBox(height: 40),
          Text("Feito por:"),
          SizedBox(height: 10),
          Text("Beatriz Patricio Santos"),
          Text("Carlos Henrique de França")
        ],),
      ),
    );
  }
}
