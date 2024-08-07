import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/shared/app_widget.dart';
import 'src/shared/user_model.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Captura de exceções de Flutter Widgets
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      sendExceptionDetails(details.exception, details.stack!);
    };

    await FlutterMapTileCaching.initialise(
      settings: FMTCSettings(
        databaseMaxSize: 20480,
        defaultTileProviderSettings: FMTCTileProviderSettings(
          cachedValidDuration: const Duration(days: 1000),
          obscuredQueryParams: ['token_geo'],
          errorHandler: (exception) {
            print('exeption on FMTCTileProviderSettings');
            print(exception);
          },
        ),
      ),
    );

    await FMTC.instance('mapStore').manage.createAsync();

    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(
        ['flutter_map_tile_caching', 'fmtc_plus_background_downloading'],
        "'e-comBR' holds an alternative proprietary license with the author of the 'flutter_map_tile_caching' library/package and its official modules, which overrides their GPL licenses.",
      );
    });

    // runApp(AppWidget());

    runApp(AppWidget());
  }, (error, stackTrace) {
    sendExceptionDetails(error, stackTrace);
  });
}

Future<void> sendExceptionDetails(Object error, StackTrace stackTrace) async {
  try {
    // debugPrint("ERRO:");
    // debugPrint(error.toString());
    var s = await SharedPreferences.getInstance();

    var usuarioLogado =
        s.getString("UserModel") ?? '{"usuario": "", "dominmio": ""}';
    var um = UserModel.fromMap(jsonDecode(usuarioLogado));

    final Uri endpoint = Uri.parse(
        'https://www.sishabi.com/mobile_exceptions/index.php?usuario=${um.email}&dominio=${um.dominio}');
    final String message = 'Erro: $error\nStackTrace: $stackTrace';

    http.post(
      endpoint,
      headers: {
        'Content-Type': 'text/plain',
      },
      body: message,
    );
  } catch (e) {
    debugPrint("ERRO2:");
    debugPrint(e.toString());
  }
}
