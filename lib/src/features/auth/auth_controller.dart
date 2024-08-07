import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:sishabi/src/shared/preferences_provider.dart';
import '../../shared/client_http.dart';
import '../../shared/user_model.dart';
import '../../shared/usuario_controller.dart';
// import '../../shared/vars_controller.dart';

import 'auth_request_model.dart';

enum AuthState { idle, success, error, loading }

class AuthController extends ChangeNotifier {
  AuthRequestModel authRequest =
      AuthRequestModel(email: '', dominio: '', password: '');
  // email: 'suporte@e-combr.com.br',
  // dominio: '_____.sisxhabi.com.br',
  // password: '3-c0mBR');

  AuthState state = AuthState.idle;
  String errMsg = '';

  // UserModel? usuarioLogado;

  final ClientHttp clientHttp;
  final PreferencesProvider preferencesProvider;

  AuthController(this.clientHttp, this.preferencesProvider);

  Future<void> loginAction(BuildContext context) async {
    log('loginAction', name: "AuthController");
    inspect(this);
    //para parar o debugger de forma programada em alguma condição
    debugger(when: false);

    // para computador o tempo de alguma coisa, aí só abrir o devtools e ir no performace timeline
    final timelineTask = TimelineTask();
    timelineTask.start('loginAction');
    timelineTask.finish();

    // print('email: ${authRequest.email}');
    // print('dominio: ${authRequest.dominio}');
    // print('senha: ${authRequest.password}');
    state = AuthState.loading;
    notifyListeners();

    // await Future.delayed(Duration(seconds: 2));
    authRequest.dominio = authRequest.dominio.toLowerCase();
    authRequest.email = authRequest.email.toLowerCase();

    if (authRequest.email.length < 3 ||
        authRequest.password.length < 3 ||
        authRequest.dominio.length < 10) {
      state = AuthState.error;
      notifyListeners();
      return;
    }

    // print('vai tentar com:');
    // print(authRequest.password);
    // print(authRequest.dominio);
    // if (!authRequest.dominio.contains('.')) {
    //   authRequest.dominio = '${authRequest.dominio}.sishabi.com.br';
    // }

    late final String? response;

    try {
      response = await clientHttp.getToken(
        'https://${authRequest.dominio.toLowerCase()}/mobile/autenticar',
        data: authRequest.toMap(),
      );

      if (response == null) {
        state = AuthState.error;
        notifyListeners();
      } else {
        log(response, name: 'Response no AuthController');

        clientHttp.token = response.toString();
        clientHttp.dominio = authRequest.dominio;

        final UsuarioController usuariosController =
            Provider.of<UsuarioController>(context, listen: false);

        usuariosController.usuarioLogado = UserModel(
            email: authRequest.email,
            dominio: authRequest.dominio,
            token: response.toString());

        // PreferencesProvider preferencesProvider = context.read<PreferencesProvider>();
        PreferencesProvider preferencesProvider =
            Provider.of<PreferencesProvider>(context, listen: false);
        await preferencesProvider
            .setLoggedUser(usuariosController.usuarioLogado!);

        var geoToken = await clientHttp.getGeoToken() ?? '';
        await preferencesProvider.saveGeoToken(geoToken);

        state = AuthState.success;
        notifyListeners();
        //navega pra home
        //Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          errMsg = e.response!.data.toString();
        } else {
          errMsg = "Confira se o domínio está escrito da forma correta. \n\n" +
              e.error.toString();
        }
      } else {
        errMsg = e.toString();
      }
      await EasyLoading.showError(errMsg);

      state = AuthState.error;
      notifyListeners();
    }
  }
}
