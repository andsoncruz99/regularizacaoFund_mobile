import 'dart:developer';

import 'package:flutter/material.dart';
import 'user_model.dart';

class UsuarioController extends ChangeNotifier {
  UserModel? usuarioLogado;
  bool _isNetworkDisponible = false;

  bool get isNetworkDisponible => _isNetworkDisponible;

  set isNetworkDisponible(bool s) {
    _isNetworkDisponible = s;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  UsuarioController() {
    log('usuarios constructor haschCode: $hashCode');
  }
}
