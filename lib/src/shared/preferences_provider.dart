import 'dart:convert';
import 'dart:developer';
import 'package:intl/intl.dart'; //for date format
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sishabi/src/shared/user_model.dart';

class PreferencesProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  String _filtroBusca = "";
  bool _filtroSomenteFaltaSubir = false;
  bool sharedPrefsInicializado = false;

  String get filtroBusca => _filtroBusca;
  bool get filtroSomenteFaltaSubir => _filtroSomenteFaltaSubir;

  PreferencesProvider();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    _filtroBusca = _prefs.getString('filtroBusca') ?? "";
    _filtroSomenteFaltaSubir =
        _prefs.getBool('filtroSomenteFaltaSubir') ?? false;

    notifyListeners();
  }

  String? getString(String v) {
    return _prefs.getString(v);
  }

  Future<bool> setString(String k, String v) async {
    return await _prefs.setString(k, v);
  }

  Set<String> getKeys() {
    return _prefs.getKeys();
  }

  Object? get(String key) {
    return _prefs.get(key);
  }

  //
  int getTimestampUltimoRefreshForms() {
    return _prefs.getInt('timestampUltimoRefreshForms') ?? 0;
  }

  Future<bool> setTimestampUltimoRefreshForms() async {
    int timestamp = DateTime.now().microsecondsSinceEpoch;

    if (await _prefs.setInt('timestampUltimoRefreshForms', timestamp)) {
      return true;
    }
    return false;
  }

  Future<bool> setLoggedUser(UserModel user) async {
    if (await _prefs.setString('UserModel', user.toJson())) {
      return true;
    }
    return false;
  }

  // Future<UserModel> getLoggedUser() async {
  //   try {
  //     String? us = _prefs.getString('UserModel');
  //     log('us: ');
  //     log(us!);
  //     var u = UserModel.fromMap(jsonDecode(us));
  //     return u;
  //   } catch (e) {
  //     rethrow;
  //   }
  // }

  //Limpa todos os registros do sharedpreferences.
  Future<void> limpaTudo() async {
    if (!await _prefs.clear()) {
      throw ('Não foi possível limpar dados ao sair.');
    }
  }

  Future<void> setFiltroBusca(String value) async {
    await _prefs.setString('filtroBusca', value);
    _filtroBusca = value;
    notifyListeners();
  }

  Future<void> setFiltroSomenteFaltaSubir(bool value) async {
    await _prefs.setBool('filtroSomenteFaltaSubir', value);
    _filtroSomenteFaltaSubir = value;
    notifyListeners();
  }

  Future<String> getDataUltimoDownload(String doque) async {
    return _prefs.getString('ultimoDownload_$doque') ?? '01/01/1900';
  }

  Future<bool> saveDataUltimoDownload(String doque) async {
    final agora = DateFormat('dd/MM/yyyy')
        .format(DateTime.now().subtract(const Duration(days: 1)));
    // var agora = DateTime.now().toString();
    log(agora);

    await _prefs.setString(
      'ultimoDownload_$doque',
      agora,
    );
    return false;
  }

  Future<bool> removerDataUltimoDownload(String doque) async {
    if (doque.isEmpty)
      throw ArgumentError("Tipo de database destino inválido: $doque");

    try {
      if (await _prefs.remove('ultimoDownload_$doque')) {
        log('ultimoDownload_$doque removido com sucesso.');
        return true;
      }
    } catch (e) {
      rethrow;
    }

    return false;
  }

  int getTimestampUltimoGeoToken() {
    return _prefs.getInt('timestampUltimoGeoToken') ?? 0;
  }

  Future<bool> setTimestampUltimoGeoToken() async {
    int timestamp = DateTime.now().microsecondsSinceEpoch;

    if (await _prefs.setInt('timestampUltimoGeoToken', timestamp)) {
      return true;
    }
    return false;
  }

  String getGeoToken() {
    var geoToken = _prefs.getString('GeoToken');
    if (geoToken != null)
      return geoToken;
    else
      return '';
    // if (geoToken != null) return geoToken;
    //throw 'Estamos sem o geoToken.';
  }

  Future<bool> saveGeoToken(String geoToken) async {
    await setTimestampUltimoGeoToken();
    return await _prefs.setString('GeoToken', geoToken);
  }
}
