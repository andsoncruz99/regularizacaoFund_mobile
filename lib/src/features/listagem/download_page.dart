import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sishabi/src/features/formularios/ec_components.dart';
import 'package:sishabi/src/shared/funcoes_gerais.dart' as funcoesGerais;
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:sishabi/src/shared/preferences_provider.dart';
import 'package:sishabi/src/shared/vars_controller.dart';

import '../../shared/usuario_controller.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({
    super.key,
    required this.doque,
    required this.salvarItem,
    required this.commit,
    required this.forcado,
    this.filtrosDownload = const {},
  });

  final String doque;
  final Future<void> Function(Map<String, dynamic> i) salvarItem;
  final void Function() commit;
  final filtrosDownload;

  //usada para forçar o download da base inteira e não apenas das ultimas alterações
  final bool forcado;

  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  String downloadMessage =
      'Preparando... clique em "Baixar Dados" para iniciar';
  bool isDownloading = false;
  bool finalizou = false;
  bool isLoading = true;
  // double _percentage = 0;

  int numAtualizacoes = 0;
  int bons = 0;

  String ultimoDownload = '';

  late PreferencesProvider preferencesProvider;

  Dio dio = Dio();
  CancelToken token = CancelToken();
  String baixado = '';

  late Directory dir;
  String nomeArquivo = 'baixado.json';

  final _formKey = GlobalKey<FormBuilderState>();
  var vars;

  // _carregaBox() async {
  //   box = await Hive.openBox<ListagemData>(widget.doque);

  // }

  Future<String> readFile() async {
    debugPrint('readFile()');
    // dir = await getExternalStorageDirectory();
    final jsonText = await File('${dir.path}/$nomeArquivo').readAsString();
    // setState(() => baixado = json.decode(jsonText));
    setState(() => baixado = jsonText);
    return 'success';
  }

  // Future<List<String, dynamic>> listagem = [];

  Future<void> _processarJson() async {
    debugPrint('_processarJson()');
    final jsonText = await File('${dir.path}/$nomeArquivo').readAsString();
    final listagem = jsonDecode(jsonText);
    // print('listagem no json');
    // print(listagem['data']);

    try {
      // int count = 0;
      bons = 0;

      setState(() {
        numAtualizacoes = listagem['data'].length;
      });

      for (var i = 0; i < numAtualizacoes; i++) {
        await widget.salvarItem(listagem['data'][i]);
        bons++;
        setState(() {
          downloadMessage = 'Processando $bons de $numAtualizacoes';
        });
      }

      await Future.delayed(Duration(milliseconds: 10));

      widget.commit();
    } catch (e) {
      EasyLoading.showError(e.toString());
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    _carregaDados();

    super.initState();
  }

  Future<void> _carregaDados() async {
    setState(() {
      isLoading = true;
    });

    if (Platform.isIOS) {
      // Platform is imported from 'dart:io' package
      dir = await getApplicationDocumentsDirectory();
    } else if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory())!;
    }

    preferencesProvider = context.read<PreferencesProvider>();

    if (widget.forcado) {
      //se nunca baixou nada, setamos ai pra pegar tudo de 1900 pra cá...ta bom né.
      ultimoDownload = '01/01/1900';
    } else {
      ultimoDownload =
          await preferencesProvider.getDataUltimoDownload(widget.doque);
    }

    final VarsController varsController =
        Provider.of<VarsController>(context, listen: false);

    vars = varsController.readVars('vars');

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final UsuarioController usuariosController =
        Provider.of<UsuarioController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Base Offline'),
      ),
      body: Center(
        child: !finalizou
            ? Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Esse procedimento pode levar vários minutos dependendo de sua conexão. Então, só siga se tiver certeza que pode esperar e também possui espaço em seu dispositivo. (+/- 1 Mb para cada 100 registros).',
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.all(8.0),
                      //   child: Text(
                      //     'Serão baixadas as alterações nos registros de ${widget.doque.toUpperCase()} a partir de: $ultimoDownload.',
                      //   ),
                      // ),
                      isLoading
                          ? Text('carregando...')
                          : widget.filtrosDownload.length > 0
                              ? FormBuilder(
                                  key: _formKey,
                                  autovalidateMode: AutovalidateMode.disabled,
                                  // initialValue: initialValues,
                                  child: EcComponente(
                                    elemento: widget.filtrosDownload,
                                    vars: vars,
                                    formKey: _formKey,
                                    notifyParent: () {},
                                  ),
                                )
                              : SizedBox(width: 0),
                      const SizedBox(
                        height: 30,
                      ),
                      Text(downloadMessage),
                      if (isDownloading)
                        Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(),
                              // child: LinearProgressIndicator(
                              //   value: _percentage,
                              // ),
                            ),
                            IconButton(
                              onPressed: () {
                                isDownloading = false;
                                token.cancel('cancelled');

                                downloadMessage = 'cancelado';

                                // TOD O: `dio.clear()` was used here, but is deprecated.
                                // See https://pub.dev/documentation/dio/4.0.6/dio/Dio/clear.html
                                // and https://github.com/cfug/dio/issues/1308

                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.cancel),
                            ),
                          ],
                        ),
                      const SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            // isDownloading = !isDownloading;
                            isDownloading = true;
                            downloadMessage = 'Preparando para Baixar...';
                          });

                          //   dir = await getExternalStorageDirectory();

                          String queryString = '';
                          if (widget.filtrosDownload.length > 0) {
                            _formKey.currentState!.save();
                            final formData = _formKey.currentState!.value;
                            queryString =
                                funcoesGerais.formDataToQueryString(formData);
                          }

                          print('baixando em:');
                          print('${dir.path}/$nomeArquivo');
                          String url =
                              'https://${usuariosController.usuarioLogado!.dominio}/mobile/lista_dados_formulario/${widget.doque}?$queryString';
                          log(url);
                          await dio.download(
                            url,
                            '${dir.path}/$nomeArquivo',
                            onReceiveProgress: (actualbytes, totalbytes) {
                              // print('baixando em:');
                              // print('${dir!.path}/$nomeArquivo');
                              // var percentage = actualbytes / totalbytes * 100;
                              // _percentage = percentage / 100;
                              setState(() {
                                // downloadMessage = 'Baixando... ${percentage.floor()}%';

                                downloadMessage = (totalbytes >= 0)
                                    ? 'Baixando...${filesize(actualbytes)} de ${filesize(totalbytes)}'
                                    : 'Baixando...${filesize(actualbytes)}';
                              });
                            },
                            cancelToken: token,
                            options: Options(
                              headers: {
                                'Token': usuariosController.usuarioLogado!.token
                              },
                              contentType: 'application/json',
                              method: 'POST',
                            ),
                            // data: jsonEncode({'data': ultimoDownload}),
                          ).catchError((e) {
                            print('catch error ');
                            EasyLoading.showError(e.response.toString());
                            // print(e.toString());
                            setState(() {
                              isDownloading = false;
                              downloadMessage =
                                  'cancelado: '; // + e.toString();
                            });
                          });

                          // setState(() {
                          //   downloadMessage =
                          //       'Processando: $bons de $numAtualizacoes registros.';
                          // });

                          await _processarJson();
                          // try {
                          //   await _processarJson();
                          // } catch (e) {
                          //   print(e);
                          //   EasyLoading.show(status: e.toString());
                          // }

                          setState(() {
                            isDownloading = false;
                            //downloadMessage = "Arquivos processados com sucesso.";
                            downloadMessage =
                                '$numAtualizacoes registros processados ($bons bons)';
                          });

                          await preferencesProvider
                              .saveDataUltimoDownload(widget.doque);

                          final File f = File('${dir.path}/$nomeArquivo');
                          await f.delete();

                          finalizou = true;
                          ultimoDownload = await preferencesProvider
                              .getDataUltimoDownload(widget.doque);
                          _carregaDados();

                          setState(() {});
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.download),
                            Text('Baixar Dados (Atualizações)'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$numAtualizacoes registros de ${widget.doque.toUpperCase()} processados. ',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Voltar'),
                  )
                ],
              ),
      ),
    );
  }
}
