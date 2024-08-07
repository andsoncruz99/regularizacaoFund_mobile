import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'package:sishabi/src/shared/preferences_provider.dart';
import 'package:sishabi/src/shared/versao_widget.dart';

import '../../shared/client_http.dart';
import '../../shared/ec_online.dart';
import '../../shared/usuario_controller.dart';
import '../../shared/vars_controller.dart';
import '../auth/auth_controller.dart';
import '../listagem/listagem_page.dart';
import '../listagem/listagem_provider.dart';
import '../mapas/gps_baixar_cache_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // late AuthController authController;

  List<dynamic> opcoes = [];

  late VarsController varsController;
  late UsuarioController usuarioController;
  late ListagemProvider listagemProvider;
  late PreferencesProvider preferencesProvider;
  late ClientHttp clientHttp;

  bool isLoading = true;

  var vars;

  Timer? timerAtulizaGeoToken;

  @override
  initState() {
    super.initState();
    _carregaDados();
    timerAtulizaGeoToken =
        Timer.periodic(Duration(hours: 1), (Timer t) => atualizaGeoToken());
  }

  _carregaDados() async {
    setState(() {
      isLoading = true;
    });
    varsController = Provider.of<VarsController>(context, listen: false);
    usuarioController = context.read<UsuarioController>();
    preferencesProvider = context.read<PreferencesProvider>();
    clientHttp = context.read<ClientHttp>();

    atualizarOpcoes(context);

    usuarioController.addListener(() {
      if (usuarioController.isNetworkDisponible) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('estamos online...')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('caiu a internet...')));
      }
    });

    if (!varsController.temConfigs) {
      final opcoes = varsController.getOpcoes();
      setState(() {
        this.opcoes = opcoes;
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> atualizaGeoToken({bool forcado = false}) async {
    if (clientHttp.isNewtorkDisponible) {
      var dt1 = new DateTime.fromMicrosecondsSinceEpoch(
          preferencesProvider.getTimestampUltimoGeoToken());
      var dt2 = new DateTime.fromMicrosecondsSinceEpoch(
          DateTime.now().microsecondsSinceEpoch);
      Duration diff = dt2.difference(dt1);

      int horasAtualizar = int.tryParse(varsController
              .readCustom()['num_horas_para_atualizar_geotoken']
              .toString()) ??
          22;

      log('atualizar geoToken a cada $horasAtualizar horas, e fazem: ${diff.inHours} horas');

      //atualiza automaticamente uma vez por dia somente, e quando estiver online
      if (diff.inHours < horasAtualizar && !forcado) {
        log('não precisa atualizar geoToken');
        return;
      }

      log('precisamos atualizar geoToken');

      var geoToken = await clientHttp.getGeoToken() ?? '';
      await preferencesProvider.saveGeoToken(geoToken);
    } else {
      log('sem rede, não podemos atualizar geotoken');
    }
  }

  atualizarOpcoes(context, {bool forcado = false}) async {
    //sem internet nem segue
    if (!usuarioController.isNetworkDisponible) return;

    if (forcado) atualizaGeoToken(forcado: true);

    //se não for forçado, vê pela data se precisa atualizar as opções
    if (!forcado) {
      //calcula diferenca entre datas
      var dt1 = new DateTime.fromMicrosecondsSinceEpoch(
          preferencesProvider.getTimestampUltimoRefreshForms());
      var dt2 = new DateTime.fromMicrosecondsSinceEpoch(
          DateTime.now().microsecondsSinceEpoch);
      Duration diff = dt2.difference(dt1);

      int horasAtualizar = int.tryParse(varsController
              .readCustom()['num_horas_para_atualizar_funcoes_automaticamente']
              .toString()) ??
          24;

      log('atualizar funções disponíveis a cada $horasAtualizar horas, e fazem: ${diff.inHours}');

      //atualiza automaticamente uma vez por dia somente, e quando estiver online
      if (diff.inHours < horasAtualizar) {
        return;
      }
    }

    log('atualizar opcoes');
    setState(() {
      isLoading = true;
    });

    try {
      final value = await clientHttp.get(
        'https://${usuarioController.usuarioLogado!.dominio}/mobile/jsons_formularios',
      );

      inspect(value);

      for (final key in value.keys) {
        await varsController.save(key, value[key]);
      }

      //salva timestamp de quando atualizou
      preferencesProvider.setTimestampUltimoRefreshForms();
    } catch (e) {
      EasyLoading.instance.displayDuration = const Duration(days: 1);
      await EasyLoading.showError(e.toString());
    }

    final opcoes = varsController.getOpcoes();
    setState(() {
      this.opcoes = opcoes;
      isLoading = false;
    });
  }

  Widget _buildListagemOpcoes() => ListView(
        children: [
          ...opcoes.map(
            (e) => Container(
              height: 80,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ), // Set rounded corner radius
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.grey,
                    offset: Offset(0, 3),
                  )
                ], // Make rounded co
              ),
              child: ListTile(
                onTap: () {
                  // Navigator.of(context).pushNamed("/listagem");
                  //print(e);
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (context) => ListagemPage(
                        doque: e['destino'].toString(),
                        descr: e['label'].toString(),
                        formheaders: e['headers'],
                      ),
                    ),
                  )
                      .then((value) {
                    if (usuarioController.isNetworkDisponible) {
                      atualizarOpcoes(context);
                    }
                  });
                },
                leading: const Icon(Icons.grid_on_sharp, size: 40),
                title: Text(
                  e['label'].toString(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text('${e['detalhes']}'),
                trailing: _buildPopupMenu(context, e),
              ),
            ),
          ),
          EcOnline(
            child: Container(
              height: 80,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ), // Set rounded corner radius
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.grey,
                    offset: Offset(0, 3),
                  )
                ], // Make rounded co
              ),
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GpsBaixarCachePage(),
                    ),
                  );
                },
                leading: const Icon(Icons.cloud_download_sharp, size: 40),
                title: Text(
                  'Baixar mapa para uso OFFLINE',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: const Text('Download de áreas para usar offline.'),
                //trailing: _buildPopupMenu(context, e),
              ),
            ),
          ),
        ],
      );

  Widget _buildPopupMenu(BuildContext context, var doque) {
    final op = {
      'abrir': 'Abrir Listagem',
      'drop': 'Apagar Registros e Imagens',
      'apagarimagens': 'Apagar somente Imagens',
    };

    return PopupMenuButton(
      itemBuilder: (context) => op.entries
          .map(
            (e) => PopupMenuItem(
              value: e.key,
              child: Text(e.value),
            ),
          )
          .toList(),
      onSelected: (String value) async {
        log('You Click on po up menu item $value');
        switch (value) {
          case 'abrir':
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ListagemPage(
                  doque: doque['destino'].toString(),
                  descr: doque['label'].toString(),
                  formheaders: doque['headers'],
                ),
              ),
            );
            break;

          case 'drop':
            //dropar databse
            //limpar arquivos
            if (await confirm(
              context,
              title: Text(
                "Tem certeza que deseja apagar todos registros de ${doque['destino'].toString().toUpperCase()}s e suas respecitvas imagens/fotos/anexos?",
              ),
              content: const Text(
                'Isso ajudar liberar espaço, mas certifique-se de já ter subido as imagens.',
              ),
              textOK: const Text('Sim'),
              textCancel: const Text('Cancelar'),
            )) {
              await EasyLoading.show(status: 'Apagando...');

              //dropa database
              listagemProvider = ListagemProvider(tipo: doque['destino']);
              await listagemProvider.dropDatabase();

              //zerando a data ultimo download , pra poder baixar novamente
              try {
                await preferencesProvider
                    .removerDataUltimoDownload(doque['destino']);
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }

              //limpa arquivos
              final appDir = await syspaths.getApplicationDocumentsDirectory();
              log(appDir.toString());
              final dirName = '${appDir.path}/imagens/${doque['destino']}/';
              final bool diretorioExiste = await Directory(dirName).exists();
              if (diretorioExiste) {
                final Directory dir = Directory(dirName);
                await dir.delete(recursive: true);
              }

              EasyLoading.instance
                ..displayDuration = const Duration(days: 1)
                ..dismissOnTap = true
                ..userInteractions = true;

              await EasyLoading.showSuccess('Feito! Tudo limpo.');
            } else {
              return print('pressedCancel');
            }

            break;
          case 'apagarimagens':
            if (await confirm(
              context,
              title: Text(
                "Tem certeza que deseja apagar todas as imagens/fotos/anexos de ${doque['destino'].toString().toUpperCase()}s ?",
              ),
              content: const Text(
                'Isso ajudar liberar espaço, mas certifique-se de já ter subido as imagens.',
              ),
              textOK: const Text('Sim'),
              textCancel: const Text('Cancelar'),
            )) {
              await EasyLoading.show(status: 'Apagando arquivos...');

              final appDir = await syspaths.getApplicationDocumentsDirectory();
              print(appDir);
              final dirName = '${appDir.path}/imagens/${doque['destino']}/';
              final bool diretorioExiste = await Directory(dirName).exists();
              if (diretorioExiste) {
                // Directory dira = Directory(_dirName);
                // print('antes');
                // await dira.list(recursive: true).forEach((fa) {
                //   print(fa);
                // });
                final Directory dir = Directory(dirName);
                await dir.delete(recursive: true);
              }

              EasyLoading.instance
                ..displayDuration = const Duration(days: 1)
                ..dismissOnTap = true
                ..userInteractions = true;

              await EasyLoading.showSuccess('Feito! Imagens apagadas.');
            } else {
              return print('pressedCancel');
            }

            break;

          default:
            print('$value ' + doque['destino']);
        }
      },
    );
  }

  Future<bool> fazLogout() async {
    print('fazLogout');
    final forms = varsController.formsDisponiveis();

    for (var i = 0; i < forms.length; i++) {
      listagemProvider = ListagemProvider(tipo: forms[i]['destino']);
      await listagemProvider.open();
      final int t = await listagemProvider.getTotal(
        somenteFaltaSubir: true,
      );

      if (t > 0) {
        await EasyLoading.showError(
          'Só é possível sair após "subir" seu trabalho!! Confira os Cadastros de ${forms[i]['destino'].toString().toUpperCase()}s 😉 ',
        );

        return false;
      }
    }

    try {
      await preferencesProvider.limpaTudo();
      //TODO: ver o que ficara baixado quando trocar de usuário

      usuarioController.usuarioLogado = null;
      final authController = context.read<AuthController>();
      authController.authRequest.dominio = '';
      authController.authRequest.email = '';
      authController.authRequest.password = '';

      // authController.dispose();
      final clienteHttp = context.read<ClientHttp>();
      clienteHttp.token = '';
      clienteHttp.dominio = '';
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  @override
  void dispose() {
    timerAtulizaGeoToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint('build do home state');
    // UsuarioController usuarioController = context.read<UsuarioController>();
    usuarioController = context.watch<UsuarioController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tela Inicial'),
        actions: [
          // IconButton(
          //   onPressed: () => showLicensePage(context: context),
          //   icon: const Icon(Icons.gavel),
          // ),
          IconButton(
            onPressed: () async {
              if (!usuarioController.isNetworkDisponible) {
                if (await confirm(
                  context,
                  title: const Text(
                    'Você parece estar OFFLINE, tem certeza que quer sair?',
                  ),
                  content: const Text(
                    'Para acessar o sistema novamente será necessário estar online.',
                  ),
                  textOK: const Text('Sim'),
                  textCancel: const Text('Cancelar'),
                )) {
                  if (await fazLogout()) {
                    await Navigator.of(context).pushReplacementNamed('/auth');
                  }
                } else {
                  return print('pressedCancel');
                }
              } else {
                if (await fazLogout()) {
                  await Navigator.of(context).pushReplacementNamed('/auth');
                }
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          atualizarOpcoes(context, forcado: true);
        },
        child: Center(
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8),
                child: InkWell(
                  child: Column(
                    children: [
                      Text(
                          'Usuário: ${usuarioController.usuarioLogado!.email}'),
                      Text(usuarioController.usuarioLogado!.dominio),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Funções Disponíveis',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(width: 5),
                        EcOnline(
                          child: InkWell(
                            onTap: () =>
                                atualizarOpcoes(context, forcado: true),
                            child: Icon(
                              Icons.refresh,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // (usuarioController.isNetworkDisponible)?
                    // EcOnline(
                    //   child: IconButton(
                    //     onPressed: () {
                    //       if (usuarioController.isNetworkDisponible)
                    //         atualizarOpcoes(context);
                    //       else
                    //         EasyLoading.showError(
                    //             'Só possível estando online...');
                    //     },
                    //     icon: const Icon(
                    //       Icons.refresh,
                    //       color: Colors.green,
                    //     ),
                    //   ),
                    // )
                  ],
                ),
              ),
              (opcoes.isNotEmpty)
                  ? Expanded(
                      child: isLoading
                          ? _buildLoadingHome()
                          : _buildListagemOpcoes(),
                    )
                  // : _buildLoadingHome(),
                  : const Text('Sem opções disponíveis.'),
              Versao(licencas: true),
            ],
          ),
        ),
      ),
    );
  }

  Shimmer _buildLoadingHome() => Shimmer.fromColors(
        baseColor: Colors.grey.withOpacity(0.35),
        highlightColor: Colors.white.withOpacity(0.99),
        child: Column(
          children: [
            Container(
              height: 80,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ), // Set rounded corner radius
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.grey,
                    offset: Offset(0, 3),
                  )
                ], // Make rounded co
              ),
              child: ListTile(
                leading: const Icon(Icons.grid_on_sharp, size: 40),
                title: Text(
                  'Cadastro de Pessoas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: const Text('Permite cadastrar as pessoas.'),
              ),
            ),
            Container(
              height: 80,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ), // Set rounded corner radius
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.grey,
                    offset: Offset(0, 3),
                  )
                ], // Make rounded co
              ),
              child: ListTile(
                leading: const Icon(Icons.person, size: 40),
                title: Text(
                  'Visita técnica',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: const Text('Permite registrar as visitas.'),
              ),
            ),
            Container(
              height: 80,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ), // Set rounded corner radius
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.grey,
                    offset: Offset(0, 3),
                  )
                ], // Make rounded co
              ),
              child: ListTile(
                leading: const Icon(Icons.cloud_download_sharp, size: 40),
                title: Text(
                  'Baixar mapa para uso OFFLINE',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: const Text('Download de áreas para usar offline.'),
                //trailing: _buildPopupMenu(context, e),
              ),
            ),
          ],
        ),
      );
}
//TODO: estudar flutter_settings_screens  para configurações de tela.
