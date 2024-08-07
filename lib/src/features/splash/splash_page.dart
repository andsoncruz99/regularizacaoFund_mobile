//

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sishabi/src/shared/preferences_provider.dart';
import '../../shared/client_http.dart';
import '../../shared/user_model.dart';
import '../../shared/usuario_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final PreferencesProvider preferencesProvider =
          context.read<PreferencesProvider>();

      await preferencesProvider.init();

      final String? u = preferencesProvider.getString('UserModel');

      if (u != null) {
        print('u:');
        print(u);

        final UsuarioController usuariosController =
            Provider.of<UsuarioController>(context, listen: false);
        // print(usuariosController.hashCode);
        final ClientHttp clientHttp =
            Provider.of<ClientHttp>(context, listen: false);

        usuariosController.usuarioLogado = UserModel.fromMap(jsonDecode(u));
        clientHttp.token = usuariosController.usuarioLogado!.token;
        clientHttp.dominio = usuariosController.usuarioLogado!.dominio;
        await Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sem usuário autenticado. Faça login.")));

        await Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Falha no login. (${e.toString()})")));
      await Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    // usuariosController.carregar().then((value) {
    //   if (value) {
    //     Navigator.of(context).pushReplacementNamed('/home');
    //   } else {
    //     Navigator.of(context).pushReplacementNamed('/auth');
    //   }
    // });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
