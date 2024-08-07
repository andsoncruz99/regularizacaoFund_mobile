//TODO: estudar scanner especifico, esses 3 parecem promissores
//1) https://github.com/Ethereal-Developers-Inc/OpenScan
//2)
//3)

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'dart:developer';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sishabi/src/shared/usuario_controller.dart';
import 'package:uuid/uuid.dart';

import '../../shared/client_http.dart';
import '../../shared/ec_online.dart';
import '../../shared/preferences_provider.dart';
import '../../shared/texto_para_mapa.dart';
import '../../shared/user_model.dart';
import '../../shared/vars_controller.dart';
import '../auth/auth_controller.dart';
import '../ec_icons.dart';
import '../formularios/formulario_page.dart';
// import '../mapas/seletor_de_camadas.dart';
import 'download_page.dart';
import 'listagem_item.dart';
import 'listagem_provider.dart';

class ListagemPage extends StatefulWidget {
  final String doque;
  final String descr;
  final formheaders;

  const ListagemPage({
    super.key,
    required this.doque,
    required this.descr,
    required this.formheaders,
  });

  @override
  _ListagemPageState createState() => _ListagemPageState();
}

class _ListagemPageState extends State<ListagemPage>
    with TickerProviderStateMixin {
  List<RegistroListagem> listagem = [];
  int total = 0;

  final TextEditingController _searchController = TextEditingController();
  bool _somenteQueFaltaSubir = false;

  AuthState state = AuthState.idle;

  late final ListagemProvider listagemProvider;
  late final ClientHttp clientHttp;

  late final VarsController varsController;
  late final PreferencesProvider preferencesProvider;
  late final UsuarioController usuarioController;

  late TileLayer tileLayer1;

  bool isLoading = false;
  bool mapajacriado = false;

  late Map<String, dynamic> abasDisponiveis;

  final mapController = MapController();
  double currentZoom = 5;

  String? geoToken;
  String? geoHost;
  // late Directory appDir;

  var camadas;
  late List<Map<String, dynamic>> camadasTileLayer = [];
  List<dynamic> camadasVetoriais = [];

  //TODO: movimentar sempre na localizacao atual
  LatLng currentCenter = LatLng(-14.577994257190609, -56.57571085099204);

  var varsConfigs;

  @override
  void initState() {
    super.initState();

    if (widget.formheaders['navegar_via_mapa']) {
      _tabController = TabController(length: 2, vsync: this);
    } else {
      _tabController = TabController(length: 1, vsync: this);
    }

    listagemProvider = ListagemProvider(tipo: widget.doque);

    clientHttp = context.read<ClientHttp>();
    preferencesProvider = context.read<PreferencesProvider>();
    usuarioController = context.read<UsuarioController>();

    _carregaBaseDados();
    _setaGeoTokenEDir();
  }

  _carregaBaseDados() async {
    // print('_carregaBaseDados ${widget.doque}');

    setState(() {
      _searchController.text =
          Provider.of<PreferencesProvider>(context, listen: false).filtroBusca;
      _somenteQueFaltaSubir =
          Provider.of<PreferencesProvider>(context, listen: false)
              .filtroSomenteFaltaSubir;

      isLoading = true;
    });

    varsController = Provider.of<VarsController>(context, listen: false);
    varsConfigs = varsController.readVars('configs');

    camadasVetoriais = varsController.readVars('camadas_vetoriais') ?? [];
    print('tot camadasVetoriais: ${camadasVetoriais.length}');

    abasDisponiveis = varsController.abasDisponiveis(widget.doque);

    await listagemProvider.open();

    await atualizaListagem();
  }

  // Future<bool> _atualizaGeoToken() async {
  //   if (clientHttp.isNewtorkDisponible) {
  //     geoToken = await clientHttp.getGeoToken();
  //     debugPrint('geoToken: $geoToken');
  //     geoHost = clientHttp.dominio;
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }

  Future<void> _setaGeoTokenEDir() async {
    // var clientHttp = Provider.of<ClientHttp>(context, listen: false);
    setState(() {
      isLoading = true;
    });

    geoToken = preferencesProvider.getGeoToken();
    geoToken = preferencesProvider.getGeoToken();
    //geoHost = clientHttp.dominio;
    var usuarioLogado = preferencesProvider.getString("UserModel");
    var um = UserModel.fromMap(jsonDecode(usuarioLogado!));
    geoHost = um.dominio;

    // if (clientHttp.isNewtorkDisponible) {
    //   geoToken = preferencesProvider.getGeoToken();
    //   geoHost = clientHttp.dominio;
    // } else {
    //   geoHost = '';
    //   geoToken = '';
    // }

    // if (await _atualizaGeoToken()) {
    // } else {
    //   // EasyLoading.showSuccess('Somente mapa offline (baixado) disponível!');
    //   geoHost = '';
    //   geoToken = '';
    // }

    // final String camadasativassalvasstr =
    //     preferencesProvider.getString('camadas_ativas') ?? ' ';
    // List<dynamic> camadasativassalvas = ['ecombr:streetview'];
    // if (camadasativassalvasstr.toString().length > 1) {
    //   camadasativassalvas = jsonDecode(camadasativassalvasstr.toString());
    // }
    // debugPrint(camadasativassalvasstr);

    final varsController = Provider.of<VarsController>(context, listen: false);
    camadas = varsController.readVars('camadas');

    camadasTileLayer = [];
/*    camadas.forEach((c) {
      camadasTileLayer.add(
        {
          'tlo': TileLayer(
            maxZoom: 23,
            tileProvider: FMTC.instance('store').getTileProvider(),
            wmsOptions: WMSTileLayerOptions(
              baseUrl: 'https://${clientHttp.dominio}/geo/wms?&token_geo=$geoToken&',
              // layers: ['larlegal.inbru:Buenopolis_11_21'],
              layers: [c['layer']],
            ),
            backgroundColor: Colors.transparent,
          ),
          'ativo': camadasativassalvas.contains(c['layer']) ? true : false,
          'nome': c['nome'],
        },
      );
    });
    if (camadasativassalvas.isEmpty) camadas[0]['ativo'] = true;
*/

    //appDir = await syspaths.getApplicationDocumentsDirectory();
    //getPosition();

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    if (listagemProvider.isOpen) listagemProvider.close();
    _tabController!.dispose();
    debugPrint('dispose listagem');
    super.dispose();
  }

  Future<void> getPosition() async {
    Position position;
    position = await _determinePosition();
    print('position: ');
    print(position);
    debugPrint('meiodo getpositionnnn444');
    setState(() {
      currentCenter = LatLng(position.latitude, position.longitude);
      isLoading = false;
      //currentCenterCarregado = true;
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position? position;
    position = await Geolocator.getLastKnownPosition();

    if (position != null) {
      return position;
    } else {
      return await Geolocator.getCurrentPosition();
    }
  }

  Future<void> atualizaListagem() async {
    debugPrint('atualizando listagem');
    setState(() {
      isLoading = true;
    });

    listagem = await listagemProvider.getAll(
        busca: _searchController.text,
        somenteFaltaSubir: _somenteQueFaltaSubir,
        limit: widget.formheaders['limite_itens_listagem']);

    final t = await listagemProvider.getTotal(
      busca: _searchController.text,
      somenteFaltaSubir: _somenteQueFaltaSubir,
    );

    await Provider.of<PreferencesProvider>(context, listen: false)
        .setFiltroBusca(_searchController.text);
    await Provider.of<PreferencesProvider>(context, listen: false)
        .setFiltroSomenteFaltaSubir(_somenteQueFaltaSubir);

    setState(() {
      //listagem = listagem;
      total = t;
      isLoading = false;
    });
  }

  Future<void> salvarPosicaoGps(double lat, double long) async {
    print('$lat, $long');
  }

  Map<String, dynamic> preparaRegistro(var formData, var varsConfigs) {
    String primaryKey;
    if (varsConfigs[widget.doque]['primaryKey'] == 'id') {
      var uuid = Uuid();
      primaryKey = uuid.v4();
      // print('primaryKey RANDOMICA $primaryKey');
    } else {
      primaryKey = (formData[varsConfigs[widget.doque]['primaryKey']] != null)
          ? formData[varsConfigs[widget.doque]['primaryKey']].toString()
          : '';
    }

    final String primaryKeyQuente =
        formData[varsConfigs[widget.doque]['primaryKeyQuente']] ?? '';
    final String temporarioIdQuente = formData['Temporario.id'] ?? '';

    // String title =
    //     formData[varsConfigs[widget.doque]['listView']['title']] ?? '';

    // String title = '';
    // varsConfigs[widget.doque]['listView']
    //     ['title'] = ['Lead.nome', 'Lead.bairro', 'Lead.id'];
    // varsConfigs[widget.doque]['listView']['title'].forEach((campo) {
    //   title += formData[campo] ?? '';
    //   title += ' - ';
    // });
    // varsConfigs[widget.doque]['listView']
    //     ['title'] = ['Lead.id', 'Lead.bairro', 'Lead.nome'];

    final String title =
        criaSubtitulo(formData, varsConfigs[widget.doque]['listView']['title']);
    final String subtitle1 = criaSubtitulo(
      formData,
      varsConfigs[widget.doque]['listView']['subtitle1'],
    );
    final String subtitle2 = criaSubtitulo(
      formData,
      varsConfigs[widget.doque]['listView']['subtitle2'],
    );
    final String subtitle3 = criaSubtitulo(
      formData,
      varsConfigs[widget.doque]['listView']['subtitle3'],
    );
    final String subtitle4 = criaSubtitulo(
      formData,
      varsConfigs[widget.doque]['listView']['subtitle4'],
    );

    // if (primaryKey.length > 1 && title.length > 1) {
    if (title.length >= 0) {
      final registro = RegistroListagem(
        primaryKey: primaryKey,
        primaryKeyQuente: primaryKeyQuente,
        temporarioIdQuente: temporarioIdQuente,
        title: title,
        subtitle1: subtitle1,
        subtitle2: subtitle2,
        subtitle3: subtitle3,
        subtitle4: subtitle4,
        dados: jsonEncode(formData),
        sincronizado: false,
      );

      // print('registro que foi preparado');
      // print(registro.title);

      return {'deucerto': true, 'registro': registro};
    } else {
      // // ${[
      //     varsConfigs[widget.doque]['primaryKey']
      //   ]},
      return {
        'msg': "Preencha o campo obrigatório: ${[
          varsConfigs[widget.doque]['listView']['title']
        ]} .",
        'deucerto': false,
      };
    }
  }

  String criaSubtitulo(var formData, var campos) {
    if (campos is List) {
      return campos
          .where((campo) => formData[campo] != null)
          .map((campo) => formData[campo])
          .join(' - ');
    }
    return formData[campos] ?? '';
  }

  Future<Map<String, dynamic>> salvar({
    required int id,
    required Map<String, dynamic> formData,
  }) async {
    print('form na listagem vindo do formulario');
    print(formData);
    print('id vindo pg formulario');
    print(id);

    final varsConfigs = varsController.readVars('configs');

    Map<String, dynamic> _registro;
    RegistroListagem registro;
    //SE JA EXISTE REGISTRO E VAMOS ATUALIZAR
    if (id > 0) {
      final registroAtual = await listagemProvider.getRegistroListagem(id);
      final dadosNoBanco = jsonDecode(registroAtual.dados);
      final dadosMesclados = dadosNoBanco;
      dadosMesclados.addAll(formData);
      formData = dadosMesclados;
      print('formData no Salvar apos mesclagem');
      print(formData);
      _registro = preparaRegistro(formData, varsConfigs);
      registro = _registro['registro'];
      registro.id = id;
    } else {
      //SENÃO, VAMOS INSERIR
      _registro = preparaRegistro(formData, varsConfigs);
      registro = _registro['registro'];
    }

    if (_registro['deucerto']) {
      bool foiProBanco;
      print('registro.id aqui ${registro.id} ');

      if (registro.id > 0) {
        print('registro que vai ser ATUALIZADO registro.primaryKey');
        print(registro.primaryKey);
        print('registro que vai ser ATUALIZADO id ${registro.id}');
        foiProBanco = await listagemProvider.update(registro.id, registro);
      } else {
        registro.id = 0;
        print('registro que vai ser INSERIDO registro.primaryKey');
        print(registro.primaryKey);
        foiProBanco = await listagemProvider.insert(registro);
      }
      print('foiProBanco deu $foiProBanco');

      if (foiProBanco) {
        return {
          'msg': 'Registro salvo com sucesso!',
          'dados': registro,
          'deucerto': true,
        };
      } else {
        return {
          'msg':
              "PROBLEMA BANCO DE DADOS, tem certeza que é o único registro de ${[
            varsConfigs[widget.doque]['primaryKey']
          ]}?",
          'deucerto': false,
        };
      }
    } else {
      return _registro;
    }
  }

  Future<Map<String, dynamic>> subirRegistro(int id) async {
    final r = await listagemProvider.getRegistroListagem(id);
    final addid = jsonDecode(r.dados);
    addid.addAll({'id': id});

    final List<String> arquivos = [];

    final listaParaEnviar = [];

    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final dirName = '${appDir.path}/imagens/${widget.doque}/$id/';

    if (await Directory(dirName).exists()) {
      final Directory dir = Directory(dirName);
      print('tem diretorio de arquivos para subir');
      final Map<String, dynamic> pasta = {};
      try {
        String lastDir = '';
        await dir.list(recursive: true).forEach((f) async {
          if (f is Directory) {
            final dirN = f.path.split('/').last;
            pasta.addAll({dirN: []});
            lastDir = dirN;
          }
          if (f is File) {
            final fileN = f.path.split('/').last;
            pasta[lastDir].add(fileN);
            arquivos.add(f.path);
          }
        });
      } catch (e) {
        EasyLoading.instance.dismissOnTap = false;
        await EasyLoading.show(
          status: 'Problema ao listar arquivos: $e',
        );
      }
      addid.addAll({'imagens': pasta});
    }
    listaParaEnviar.add(addid);

    print('r.dados que vai subir (id $id)');
    print(listaParaEnviar.last);

    return await postarTodosArquivos(arquivos).then((value) async {
      final envio = await clientHttp.postRegistros(
        '/mobile/salvar_dados_formulario/${widget.doque}',
        data: {'registros': listaParaEnviar},
      );

      if (envio['type'] != 'error') {
        for (var j = 0; j < envio['registros'].length; j++) {
          // var registroEnviar = [listaParaEnviar[j]]; //lista de 1 item
          final aux = envio['registros'][j];
          final registroAtualizar =
              await listagemProvider.getRegistroListagem(aux['id']);
          final novosDados = jsonDecode(registroAtualizar.dados);
          novosDados.addAll(aux);
          registroAtualizar.dados = jsonEncode(novosDados);
          registroAtualizar.primaryKeyQuente =
              aux[varsConfigs[widget.doque]['primaryKeyQuente']] ??
                  ''; //pkq que vai depender do vars
          registroAtualizar.temporarioIdQuente = aux['Temporario.id'];
          await listagemProvider.update(aux['id'], registroAtualizar);
          await listagemProvider.marcaSincronizado(aux['id']);
        }

        return envio['contagem'];
      } //do if do envio
      else {
        //Remove a mensagem que estava subindo.
        EasyLoading.dismiss();

        print('erro feio no envio dos dados: ' + envio['msg']);
        EasyLoading.instance.dismissOnTap = true;
        await EasyLoading.showError(envio['msg'], duration: Duration(days: 1));

        return {
          'msg': envio['msg'],
          'deucerto': false,
        };
      }
    });
  }

  Future<Map<String, dynamic>> subirParaNuvem(
    id,
    bool forcarTudo,
  ) async {
    print('id pra subir = $id');

    List idsParaSubir;

    //se id for zero, vamos subir todos que não estão sincronizados
    (id != 0)
        ? idsParaSubir = [id]
        : idsParaSubir = await listagemProvider.listaQueFaltaSubir(forcarTudo);

    EasyLoading.instance.dismissOnTap = false;
    await EasyLoading.show(
      status: '🚀 subindo ${idsParaSubir.length} cadastros para nuvem',
    );

    int totalSucesso = 0;
    int totalPendente = 0;

    for (var i = 0; i < idsParaSubir.length; i++) {
      id = idsParaSubir[i];

      await EasyLoading.show(
        status:
            '🚀 subindo cadastro ${i + 1} de ${idsParaSubir.length} \n NÃO SAIA DESTA TELA - AGUARDE ',
      );

      final subido = await subirRegistro(id);
      totalSucesso =
          totalSucesso + int.parse(subido['sincronizados'].toString());
      totalPendente =
          totalPendente + int.parse(subido['faltando_sincronizar'].toString());
    } //foreach id encontrado pra subir

    await atualizaListagem();

    return {
      'msg':
          '$totalSucesso cadastros subidos com sucesso, e $totalPendente com alguma pendência a ser corrigida pelo ambiente web.',
      'deucerto': true,
    };
  }

  Future<List<bool>> postarTodosArquivos(List<String> caminhosArquivos) async =>
      Future.wait<bool>(
        caminhosArquivos.map((caminho) {
          var fileN = caminho.split('/').last;

          //correção do bug das assinaturas
          if (fileN == 'assinatura.png') {
            const chars =
                'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
            final math.Random rnd = math.Random();

            String getRandomString(int length) => String.fromCharCodes(
                  Iterable.generate(
                    length,
                    (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
                  ),
                );

            fileN = 'assinatura${getRandomString(7)}.png';
          }

          return clientHttp.postArquivo(fileN, caminho);
        }),
      );

  Future<void> batchAdd(var dadosRegistroNaNuvem) async {
    // print('dadosRegistroNaNuvem');
    // print(dadosRegistroNaNuvem);

    final String primaryKeyQuente =
        dadosRegistroNaNuvem[varsConfigs[widget.doque]['primaryKeyQuente']];

    final String temporarioIdQuente =
        dadosRegistroNaNuvem['Temporario.id'] ?? '';

    //TODO: IMPORTANTE importante ver sobre a questao dos arquivos na pasta do ID

    //criar um registro baseado nos dados da nuvem vs varsbuscavis
    final registro =
        preparaRegistro(dadosRegistroNaNuvem, varsConfigs)['registro'];
    registro.sincronizado = true;

    // print('registro.dados no batchadd  ');
    // print(registro.dados);

    int? id;

    if (primaryKeyQuente.isNotEmpty) {
      id = await listagemProvider
          .getRegistroIdByPrimaryKeyQuente(primaryKeyQuente);
    }

    if (id == null && temporarioIdQuente.isNotEmpty) {
      id = await listagemProvider
          .getRegistroIdByTemporarioIdQuente(temporarioIdQuente);
    }
    //TODO: tentar voltar para batchupdate e batchinsert
    if (id != null) {
      listagemProvider.batchUpdate(id, registro);
    } else {
      listagemProvider.batchInsert(registro);
    }

    //listagemProvider.batchInsert(registro);
  }

  batchCommit() async {
    try {
      log('inicio try batckCommit');
      await listagemProvider.batchCommit();
    } catch (e) {
      inspect(e);

      EasyLoading.instance
        ..displayDuration = const Duration(days: 1)
        ..dismissOnTap = true
        ..userInteractions = true;

      var msg =
          usuarioController.usuarioLogado!.email == 'suporte@e-combr.com.br'
              ? e.toString()
              : "Contate o Suporte!";

      await EasyLoading.showError(msg);
    }
  }

  Future<bool> adicionarRegistro(RegistroListagem registro) async {
    print('adicionarRegistro');
    // print(registro.subtitle1);
    final ok = await listagemProvider.insert(registro);
    return ok;
  }

  Future<bool> deleteItem(id) async {
    // print('deleteItem');
    // print(id);
    if (await listagemProvider.delete(id)) {
      // print('appDir');
      final appDir = await syspaths.getApplicationDocumentsDirectory();
      // print(appDir);
      final dirName = '${appDir.path}/imagens/${widget.doque}/$id/';
      final bool diretorioExiste = await Directory(dirName).exists();
      if (diretorioExiste) {
        final Directory dir = Directory(dirName);
        await dir.delete(recursive: true);
        // print('depois');
        // await dir.list(recursive: true).forEach((f) {
        //   print(f);
        // });
      }
      return true;
    } else {
      return false;
    }
  }

  Future<void> confirmaSubir(BuildContext context, id) async {
    if (await confirm(
      context,
      title: const Text('Subir os dados pode ser demorado!'),
      content: const Text(
        'Necessária conexão com internet, e isso pode levar vários minutos. Tem certeza que deseja fazer isso agora?',
      ),
      textOK: const Text('Sim'),
      textCancel: const Text('Cancelar'),
    )) {
      EasyLoading.instance.dismissOnTap = false;
      await EasyLoading.show(status: 'Subindo 🚀');
      final r = await subirParaNuvem(id, false);

      EasyLoading.instance
        ..displayDuration = const Duration(days: 1)
        ..dismissOnTap = true
        ..userInteractions = true;

      if (r['deucerto']) {
        await EasyLoading.showSuccess(r['msg']);
      } else {
        await EasyLoading.showError(r['msg']);
      }

      await atualizaListagem();
    } else {
      return print('pressedCancel');
    }
  }

  Future<void> confirmaSubirForcado(BuildContext context, id) async {
    if (await confirm(
      context,
      title: const Text('Subir TODOS os dados pode ser BEM demorado!'),
      content: const Text('Tem certeza que deseja fazer isso agora?'),
      textOK: const Text('Sim'),
      textCancel: const Text('Cancelar'),
    )) {
      EasyLoading.instance.dismissOnTap = false;
      await EasyLoading.show(status: 'Subindo 🚀');
      final r = await subirParaNuvem(id, true);

      EasyLoading.instance
        ..displayDuration = const Duration(days: 1)
        ..dismissOnTap = true
        ..userInteractions = true;

      if (r['deucerto']) {
        await EasyLoading.showSuccess(r['msg']);
      } else {
        await EasyLoading.showError(r['msg']);
      }

      await atualizaListagem();
    } else {
      return print('pressedCancel');
    }
  }

  drop() {
    listagemProvider.dropDatabase();
  }

  TabController? _tabController;

  atualizaCamadas(List<Map<String, dynamic>> camadas) {
    setState(() {
      camadasTileLayer = camadas;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.descr),
          actions: [
            // IconButton(onPressed: baixarDaNuvem, icon: Icon(Icons.refresh))
            EcOnline(
              child: (widget.formheaders['permite_baixar'])
                  ? ElevatedButton(
                      onPressed: () async {
                        if (await listagemProvider.existemItensParaSubir()) {
                          await EasyLoading.showError(
                            'Só é possível baixar a base para trabalho offline, quando não houverem mais dados para subir.',
                          );
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DownloadPage(
                                doque: widget.doque,
                                salvarItem: batchAdd,
                                commit: batchCommit,
                                forcado: false,
                                filtrosDownload:
                                    widget.formheaders['filtros_download'] ??
                                        {},
                              ),
                            ),
                          ).then((value) => atualizaListagem());
                        }
                      },
                      onLongPress: () async {
                        if (await listagemProvider.existemItensParaSubir()) {
                          await EasyLoading.showError(
                            'FORÇADO: Só é possível baixar a base para trabalho offline, quando não houverem mais dados para subir.',
                          );
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DownloadPage(
                                doque: widget.doque,
                                salvarItem: batchAdd,
                                commit: batchCommit,
                                forcado: true,
                                filtrosDownload:
                                    widget.formheaders['filtros_download'],
                              ),
                            ),
                          ).then((value) => atualizaListagem());
                        }
                      },
                      child: const Icon(Icons.download_for_offline_rounded),
                    )
                  : const SizedBox(),
            ),

            EcOnline(
              child: ElevatedButton(
                child: const Icon(
                  Icons.upload_rounded,
                ),
                onPressed: () async {
                  if (await listagemProvider.existemItensParaSubir()) {
                    await confirmaSubir(context, 0);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Não existem ítens para subir.'),
                        padding: const EdgeInsets.all(10),
                        backgroundColor: Colors.red[900],
                      ),
                    );
                  }
                },
                onLongPress: () async {
                  await confirmaSubirForcado(context, 0);
                },
              ),
            )
          ],
        ),
        bottomNavigationBar: (widget.formheaders['navegar_via_mapa'])
            ? Container(
                color: Theme.of(context).primaryColor,
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.list, size: 30, color: Colors.white),
                          SizedBox(width: 5),
                          Text('Listagem')
                        ],
                      ),
                    ),
                    if (widget.formheaders['navegar_via_mapa'])
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.map, size: 30, color: Colors.white),
                            SizedBox(width: 5),
                            Text('Mapa')
                          ],
                        ),
                      ),
                  ],
                ),
              )
            : null,
        body: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    // autofocus: true,
                    // key: const Key('filter'),
                    // inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
                    keyboardType: TextInputType.text,
                    onChanged: (value) async {
                      await Future.delayed(const Duration(milliseconds: 200));
                      setState(atualizaListagem);
                    },

                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'buscar',
                      suffixIcon: _searchController.text.length > 0
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  atualizaListagem();
                                });
                                FocusScope.of(context).unfocus();
                              },
                              icon: Icon(
                                Icons.clear,
                                color: Colors.red,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                Checkbox(
                  checkColor: Colors.white,
                  // fillColor: MaterialStateProperty.resolveWith(getColor),
                  value: _somenteQueFaltaSubir,
                  onChanged: (bool? value) {
                    setState(() {
                      _somenteQueFaltaSubir =
                          _somenteQueFaltaSubir ? false : true;
                      atualizaListagem();
                    });
                  },
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 14, 0),
                  child: Text('falta subir'),
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: atualizaListagem,
                child: isLoading
                    ? _criaMsgCarregando()
                    // : DefaultTabController(length: 2, child: Text('2')),
                    : TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: _tabController,
                        children: [
                          ListView.builder(
                            itemCount: listagem.length,
                            itemBuilder: (ctx, index) {
                              final e = listagem[index];
                              return ListagemItem(
                                item: e,
                                salvar: salvar,
                                doque: widget.doque,
                                abasDisponiveis: abasDisponiveis,
                                atualizar: atualizaListagem,
                                deletar: deleteItem,
                                subir: confirmaSubir,
                                varsConfigs: varsConfigs,
                                salvarPosicaoGps: salvarPosicaoGps,
                              );
                            },
                          ),
                          if (widget.formheaders['navegar_via_mapa'])
                            _criaMapa()
                          // TODO: continuar isso aqui, é pra poder usar o mapcontroller sem dar problema
                          // (mapajacriado) ? Text('asdf') : _criaMapa(),
                        ],
                      ),
              ),
            ),
            Text('Mostrando ${listagem.length} de $total itens.'),
          ],
        ),
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.formheaders['permite_novo'])
                      _criaBotaoNovoCadastro(),
                  ],
                ),
              )
            ],
          ),
        ),
      );

  // _criaBotaoNavegarViaMapa(bool statusconexao) {
  //   return FloatingActionButton(
  //     heroTag: null,
  //     onPressed: () async {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => CadastroViaMapa(
  //             title: 'Cadastro Via Mapa',
  //             listagem: listagem,
  //             salvar: salvar,
  //             doque: widget.doque,
  //             varsConfigs: varsConfigs,
  //             salvarPosicaoGps: salvarPosicaoGps,
  //             online: statusconexao,
  //           ),
  //         ),
  //       ).then((_) => atualizaListagem());
  //     },
  //     child: Icon(
  //       Icons.map,
  //       color: (statusconexao) ? Colors.white : Colors.redAccent,
  //     ),
  //   );
  // }

  FloatingActionButton _criaBotaoNovoCadastro() => FloatingActionButton(
        heroTag: null,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormularioPage(
                salvar: salvar,
                id: 0,
                primaryKey: 'Pessoafisica.cpf',
                doque: widget.doque,
                atualizarListagem: atualizaListagem,
                //TODO: tem que pegar a primeria aba do form
                //aba: args.params['form'] ?? 'Ocupante'),
              ),
            ),
          ).then((_) {
            _setaGeoTokenEDir();
            atualizaListagem();
          });
        },
        child: const Icon(Icons.add),
      );

  Padding _criaMsgCarregando() => Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.secondary,
            highlightColor: Colors.white,
            child: const Text(
              'Carregando...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );

  Stack _criaMapa() {
    log(
        name: "store size",
        FMTC.instance('mapStore').stats.storeLength.toString());
    log(
        name: "store size",
        FMTC.instance('mapStore').stats.storeSize.toString());

    print('geoToken: ' + geoToken.toString());
    tileLayer1 = TileLayer(
      maxZoom: 23,
      maxNativeZoom: 23,
      tileProvider: FMTC.instance('mapStore').getTileProvider(),
      wmsOptions: WMSTileLayerOptions(
        baseUrl: 'https://$geoHost/geo/wms?token_geo=$geoToken',
        layers: ['unificada'],
        transparent: true,
      ),
      // backgroundColor: Colors.transparent,
    );

    Polygon _criaPolygon2(
      List<dynamic> pontos, {
      List<dynamic> corBorda = const [0, 0, 0, 90.1],
      List<dynamic> corPreenchimento = const [0, 0, 0, 90.1],
    }) {
      Color? _corPreenchimento, _corBorda;

      try {
        _corPreenchimento = Color.fromRGBO(
          corPreenchimento[0],
          corPreenchimento[1],
          corPreenchimento[2],
          double.parse(corPreenchimento[3].toString()),
        );
      } catch (e) {
        _corPreenchimento = Colors.purple.withOpacity(0.30);
      }

      try {
        _corBorda = Color.fromRGBO(
          corBorda[0],
          corBorda[1],
          corBorda[2],
          double.parse(corBorda[3].toString()),
        );
      } catch (e) {
        _corBorda = Colors.green.withOpacity(0.30);
      }

      return Polygon(
        points: <LatLng>[
          ...pontos
              .map(
                (e) => LatLng(
                  double.parse(e[0].toString()),
                  double.parse(e[1].toString()),
                ),
              )
              .toList(),
        ],
        color: _corPreenchimento,
        // color: Colors.primaries[Random().nextInt(Colors.primaries.length)]
        //     .withOpacity(0.3),
        borderColor: _corBorda,
        borderStrokeWidth: 2,
      );
    }

    final List<Marker> markers = [];

    final List<Polygon> polygons = [];

    // try {
    for (final element in camadasVetoriais) {
      if (element['geom'] != null && element['geom'].length > 0) {
        //print('geoms: ${element['nome']}');
        polygons.add(
          _criaPolygon2(
            element['geom'],
            corBorda: element['corBorda'],
            corPreenchimento: element['corPreenchimento'],
          ),
        );
      }
    }
    // } catch (e) {
    //   EasyLoading.showError(
    //     'Alguma inconsistência ao desenhar Geoms do Nucleo. Baixe os dados novamente. Detalhes: \n' + e.toString(),
    //     duration: Duration(days: 1),
    //   );
    // }

    for (final item in listagem) {
      final dadosdoitem = jsonDecode(item.dados);

      try {
        if (widget.formheaders.containsKey('geoms_gps')) {
          if (widget.formheaders['geoms_gps'] != null &&
              widget.formheaders['geoms_gps'].length > 0) {
            widget.formheaders['geoms_gps'].forEach((i) {
              // print('geoms_gps: ${i['fieldName']}');
              // print(jsonDecode(dadosdoitem[i['fieldName']]));
              if (dadosdoitem[i['fieldName']] != null) {
                polygons.add(
                  _criaPolygon2(
                    jsonDecode(dadosdoitem[i['fieldName']]),
                    corBorda: i['corBorda'],
                    corPreenchimento: i['corPreenchimento'],
                  ),
                );
              }
            });
          }
        }
      } catch (e) {
        EasyLoading.showError(
          'Incompatibiliade de geometrias (Geoms). Baixe os dados novamente. Detalhes: \n$e',
          duration: const Duration(days: 1),
        );
      }

      // if (dadosdoitem['Lote.geom'] != null) polygons.add(_criaPolygon2(dadosdoitem['Lote.geom']));

      if (widget.formheaders.containsKey('pontos_gps')) {
        if (widget.formheaders['pontos_gps'].length > 0) {
          widget.formheaders['pontos_gps'].forEach((i) {
            // print('ponto: ${i['fieldName']}');

            String textoPontoGps = '';

            final List<dynamic> listaCampos =
                i['campo_para_mostrar'].split(',');
            final List<dynamic> listaTextosMostrar = [];

            for (final campo in listaCampos) {
              if (dadosdoitem[campo].toString() != 'null') {
                listaTextosMostrar.add(dadosdoitem[campo].toString());
              }
            }

            for (var n = 0; n < listaTextosMostrar.length; n++) {
              if (n == 0) {
                textoPontoGps += listaTextosMostrar[n];
              } else {
                textoPontoGps += '\n' + listaTextosMostrar[n];
              }
            }

            if (dadosdoitem[i['fieldName']].toString().split(',').length == 2) {
              final List latlng =
                  dadosdoitem[i['fieldName']].toString().split(',');
              if (latlng[0] != 'null') {
                markers.add(
                  Marker(
                    width: double.tryParse(
                          widget.formheaders['width_pin_ponto_gps'].toString(),
                        ) ??
                        80.0,
                    height: double.tryParse(
                          widget.formheaders['height_pin_ponto_gps'].toString(),
                        ) ??
                        80.0,
                    point: LatLng(
                      double.parse(latlng[0].toString()),
                      double.parse(latlng[1].toString()),
                    ),
                    child: Container(
                      // color: Colors.amber.withAlpha(30),
                      child: InkWell(
                        child: Container(
                          // color: item.sincronizado ? Colors.white : Colors.red[600],
                          color: item.sincronizado
                              ? Colors.white.withOpacity(0)
                              : Colors.red.withOpacity(0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              EcIcon(
                                i['icone_item_no_mapa'].toString(),
                                cor: item.sincronizado
                                    ? Colors.yellow
                                    : Colors.red,
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Expanded(
                                child: TextoParaMapa(
                                  // txt: dadosdoitem[i['campo_para_mostrar']].toString(),
                                  txt: textoPontoGps.toString(),
                                  cor: item.sincronizado
                                      ? Colors.yellow
                                      : Colors.yellow,
                                  // child: Text(
                                  //   dadosdoitem[i['campo_para_mostrar']].toString(),
                                  //   style: TextStyle(
                                  //       fontSize: 11, color: item.sincronizado ? Colors.yellow : Colors.red),
                                  //   textAlign: TextAlign.center,
                                ),
                              )
                            ],
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            //ASDFASDF
                            currentZoom = mapController.zoom;
                            currentCenter = mapController.center;
                            return FormularioPage(
                              id: item.id,
                              primaryKey: varsConfigs[widget.doque]
                                  ['primaryKey'],
                              salvar: salvar,
                              doque: widget.doque,
                              dados: item.dados,
                              atualizarListagem: atualizaListagem,
                              aba: null,
                            );
                          }),
                        ).then((value) {
                          _setaGeoTokenEDir();
                          atualizaListagem();
                        }),
                      ),
                    ),
                  ),
                );
              }
            }
          });
        }
      }
      mapajacriado = true;
    }

    return Stack(
      children: [
        FlutterMap(
          key: UniqueKey(),
          mapController: mapController,
          options: MapOptions(
            onLongPress: (_, __) async {
              print(mapController.camera.zoom);

              var dtgeo = DateFormat('dd/MM/yyyy HH:mm:ss').format(
                DateTime.fromMicrosecondsSinceEpoch(
                  preferencesProvider.getTimestampUltimoGeoToken(),
                ),
              );

              EasyLoading.showSuccess(
                'Zoom: ${mapController.camera.zoom}\n Posição central: $currentCenter\n geoToken: ${geoToken!} \n dtGeo: $dtgeo',
              );
            },
            onPositionChanged: (pos, b) {
              //print(pos);
              currentZoom = double.parse(pos.zoom.toString());
            },
            initialCenter: currentCenter,
            initialZoom: currentZoom,
            maxZoom: 23,
            minZoom: 2,
            interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          children: [
            tileLayer1,
            // if (!connected) tileLayer1,
            // if (connected) ...camadasTileLayer.where((w) => w['ativo']).map((c) => c['tlo']),
            PolygonLayer(polygons: [...polygons]),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 70,
                //size: Size(40, 40),
                // fitBoundsOptions: const FitBoundsOptions(
                //   padding: EdgeInsets.all(50),
                // ),
                markers: [
                  ...markers,
                ],
                polygonOptions: const PolygonOptions(
                  borderColor: Colors.blueAccent,
                  color: Colors.black12,
                  borderStrokeWidth: 3,
                ),
                builder: (context, markers) => FloatingActionButton(
                  heroTag: null,
                  onPressed: null,
                  child: Text(markers.length.toString()),
                ),
              ),
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 80,
                  height: 80,
                  point: currentCenter,
                  // point: LatLng(51.5, -0.09),
                  child: Container(
                    child: Shimmer.fromColors(
                      baseColor: Theme.of(context).colorScheme.secondary,
                      highlightColor: Colors.white10,
                      child: const Icon(Icons.gps_fixed, size: 35),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Positioned(
          right: 1,
          bottom: 1,
          child: Text('(c) OpenStreetMap', style: TextStyle(fontSize: 12)),
        ),
        const EcOffline(
          child: Positioned(
            top: 1,
            left: 1,
            child: Text(
              'Somente mapa offline (baixado) disponível!',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        Positioned(
          top: 1,
          right: 1,
          child: Row(
            children: [
              // EcOnline(
              //   child: Container(
              //     decoration: BoxDecoration(
              //       borderRadius: BorderRadius.circular(360),
              //       color: Theme.of(context).primaryColor.withOpacity(0.75),
              //     ),
              //     child: IconButton(
              //       onPressed: () {
              //         //hhhhh
              //         currentZoom = mapController.zoom;
              //         currentCenter = mapController.center;
              //         showDialog(
              //           context: context,
              //           builder: (_) => SeletorDeCamadas(
              //             camadas: camadasTileLayer,
              //             retorno: atualizaCamadas,
              //           ),
              //         );
              //       },
              //       icon: const Icon(Icons.layers, color: Colors.white),
              //     ),
              //   ),
              // ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(360),
                  color: Theme.of(context).primaryColor.withOpacity(0.75),
                ),
                child: IconButton(
                  onPressed: () {
                    getPosition();
                    mapController.move(currentCenter, currentZoom);
                    // mapController.move(
                    //     LatLng(-3.2146033982466697, -52.2370083922232), 19);
                  },
                  icon: const Icon(Icons.gps_fixed, color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
