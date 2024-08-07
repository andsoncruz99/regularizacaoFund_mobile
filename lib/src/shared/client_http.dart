import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:package_info_plus/package_info_plus.dart';

// class ClientHttp extends ChangeNotifier {
class ClientHttp {
  final dio = Dio();

  String? token;
  //String? geoToken;
  String? dominio;
  bool isNewtorkDisponible = true;
  int buildNumber = 0;

  ClientHttp() {
    _init();
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        // Don't trust any certificate just because their root cert is trusted.
        final HttpClient client =
            HttpClient(context: SecurityContext(withTrustedRoots: false));
        // You can test the intermediate / root cert here. We just ignore it.
        client.badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
        return client;
      },
    );
  }

  Future<void> _init() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    try {
      buildNumber = int.parse(packageInfo.buildNumber);
    } catch (e) {
      buildNumber = 0;
    }
  }

  Future<bool> postArquivo(
      String nomeArquivo, String caminhoArquivoLocal) async {
    log('*** SUBINDO $nomeArquivo ($caminhoArquivoLocal) ***');

    final File imageFile = File(caminhoArquivoLocal);
    final List<int> imageBytes = imageFile.readAsBytesSync();
    final String base64Image = base64Encode(imageBytes);

    final data = {
      'filename': nomeArquivo,
      'anexo': base64Image,
    };

    try {
      return dio
          .post(
            'https://$dominio/mobile/anexo_adicionar',
            data: data,
            options: Options(
              headers: {
                'Token': token,
                'buildNumber': buildNumber.toString(),
              },
              contentType: 'application/json',
              method: 'POST',
            ),
          )
          .then((value) => true);
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> postRegistros(String endPoint,
      {Map? data}) async {
    print('subindo para: https://$dominio$endPoint');

    try {
      final response = await dio.post(
        "https://$dominio$endPoint",
        data: data,
        options: Options(
          headers: {
            'Token': token,
            'buildNumber': buildNumber.toString(),
          },
          responseType: ResponseType.json,
          contentType: 'application/json',
          method: 'POST',
        ),
      );
      return response.data;
    } on DioException catch (e) {
      //TODO: talvez tratar e mostrar os erros na terra
      print(e.toString());
      return {
        'msg': '${e.response!.data} \n(em: https://$dominio$endPoint)',
        'type': 'error',
      };
    } on Error catch (e) {
      print(e.toString());
      return {
        'msg': '$e \n(em: https://$dominio$endPoint)',
        'type': 'error',
      };
    }
  }

  Future<String?> getToken(String url, {Map? data}) async {
    try {
      log('getToken - $url', name: 'getToken');
      final response = await dio.post(
        url,
        data: data,
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      inspect(e);
      log(e.response.toString(), name: 'getToken', error: e.toString());
      rethrow;
      //return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getGeoToken(
      {String endPoint = '/mobile/gerar_hash_geo'}) async {
    try {
      log('pegando $endPoint');
      final stopwatch = Stopwatch();
      stopwatch.start();

      final response = await dio.post(
        "https://$dominio$endPoint",
        options: Options(
          headers: {
            'Token': token,
          },
          contentType: 'application/json',
          method: 'POST',
        ),
      );

      stopwatch.stop();
      log('Post levou ${stopwatch.elapsedMilliseconds} milissegundos para ser executado.');

      // geoToken = response.data;
      return response.data;
    } catch (e) {
      //TODO: talvez tratar e mostrar os erros na tela
      print(e.toString());
      return null;
    }
  }

  Future<Map<String, dynamic>> get(String url) async {
    log('get $url');

    try {
      final stopwatch = Stopwatch();
      stopwatch.start();
      // final response = await dio.get(
      //   url,
      //   options: Options(
      //     headers: {
      //       'Token': token,
      //       'buildNumber': buildNumber.toString(),
      //     },
      //     responseType: ResponseType.json,
      //     contentType: 'application/json',
      //   ),
      // );
      // log('finalizou $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Token': token!,
          'buildNumber': buildNumber.toString(),
          'Content-Type': 'application/json',
        },
      );
      log('finalizou $url');

      stopwatch.stop();
      log('Get levou ${stopwatch.elapsedMilliseconds} milissegundos para ser executado.');

      if (response.statusCode == 200) return jsonDecode(response.body);

      if (response.statusCode == 401) throw Exception(response.body);

      throw ("Falha ao obter formulários. Tente novamente ou contate o suporte. (${response.body})");

      //return response.data;
    } on Exception catch (e) {
      //TODO: criar um endpoint no quente para jogar a ultima msg de erro
      //enviar datahora / usuario / dominio e msg de erro
      print(e);
      rethrow;
    }
  }
}
