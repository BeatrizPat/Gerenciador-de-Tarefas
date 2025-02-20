import 'package:flutter/material.dart';
import 'package:flutter_trabalho_final/autenticacao.dart';
import 'dart:async';
import 'package:flutter_trabalho_final/main.dart';
import 'package:flutter_trabalho_final/app_localizations.dart';
import 'package:flutter_trabalho_final/app_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedLanguage = 'en';
  Autenticacao _autenticacao = Autenticacao();

  void _changeLanguage(String languageCode) {
    Locale newLocale;
    switch (languageCode) {
      case 'pt':
        newLocale = Locale('pt', 'BR');
        break;
      case 'es':
        newLocale = Locale('es', 'ES');
        break;
      default:
        newLocale = Locale('en', 'US');
    }
    MainApp.setLocale(context, newLocale);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300, // Ajuste a largura do formulário
        height: 300, // Ajuste a altura do formulário
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white, // Cor de fundo do formulário
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2.0,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              DropdownButton<String>(
                value: _selectedLanguage,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguage = newValue!;
                    _changeLanguage(_selectedLanguage);
                  });
                },
                items: [
                  DropdownMenuItem(
                    value: 'en',
                    child: Row(
                      children: [
                        Image.asset('assets/flags/en.png', width: 24, height: 24),
                        SizedBox(width: 8),
                        Text('English'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'pt',
                    child: Row(
                      children: [
                        Image.asset('assets/flags/pt.png', width: 24, height: 24),
                        SizedBox(width: 8),
                        Text('Português'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'es',
                    child: Row(
                      children: [
                        Image.asset('assets/flags/es.png', width: 24, height: 24),
                        SizedBox(width: 8),
                        Text('Español'),
                      ],
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('username'),
                  labelStyle: TextStyle(color: Color.fromARGB(255, 124, 124, 124)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.translate('enter_username');
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('password'),
                  labelStyle: TextStyle(color: Color.fromARGB(255, 124, 124, 124)),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.translate('enter_password');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _autenticacao.logarUsuarios(
                    email: _usernameController.text,
                    senha: _passwordController.text,
                  ).then((String? erro) {
                    if (erro != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.translate('login_error')),
                        ),
                      );
                    } else {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.translate('processing_data')),
                          ),
                       );
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => AppScreen()),
                      );
                  }
                    }
                  });
                  /**/
                },
                child: Text(AppLocalizations.of(context)!.translate('login')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}