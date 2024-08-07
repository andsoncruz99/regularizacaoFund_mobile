import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

// import 'package:path_provider/path_provider.dart';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mapstoolkit;
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:provider/provider.dart';

import '../../shared/client_http.dart';
import '../../shared/ec_online.dart';
import '../../shared/preferences_provider.dart';
import '../../shared/user_model.dart';
import '../../shared/utilitarios_para_mapas.dart';
import '../../shared/vars_controller.dart';
import '../ec_icons.dart';
import '../listagem/listagem_provider.dart';
// import 'seletor_de_camadas.dart';

// import 'package:flutter_map/plugin_api.dart';

class EcGpsPage extends StatefulWidget {
  EcGpsPage({
    super.key,
    required this.title,
    this.salvarPosicaoGps,
    this.gpsInicial,
    this.salvarGeom,
    this.geomInicial,
    this.icone_item_no_mapa,
    this.online,
    this.tipo = 'ponto',
  });

  final String title;
  final Future Function(double lat, double long)? salvarPosicaoGps;
  final Future Function(List<dynamic> posicoesGeom)? salvarGeom;
  late LatLng? gpsInicial;
  late List<dynamic>? geomInicial;
  late String? icone_item_no_mapa;
  final online;
  final String tipo;

  int? pontomovel;

  //   List<dynamic> pontospoligono = [
  //   [-27.099518, -52.61494],
  //   [-27.091333, -52.609524],
  //   [-27.090257, -52.608338],
  // ];
  // List<dynamic> pontospoligonooriginal = [
  //   [-27.099518, -52.61494],
  //   [-27.091333, -52.609524],
  //   [-27.090257, -52.608338],
  // ];

  // final tipo = "ponto"; //"ponto"
  // final tipo = "poligono"; //"poligono"

  @override
  _GpsPageState createState() => _GpsPageState();
}

class _GpsPageState extends State<EcGpsPage> {
  bool isLoading = true;
  bool currentCenterCarregado = false;
  bool dirCarregado = false;

  late ListagemProvider listagemProvider;
  List<RegistroListagem> listagem = [];
  late final ClientHttp clientHttp;
  late final VarsController varsController;
  late final PreferencesProvider preferencesProvider;

  final List<Polygon> polygonsOutrosLotes = [];

  late TileLayer tileLayer2;

  // final String _text = 'initial';
  late TextEditingController _c;

  late List<dynamic> pontospoligono = widget.geomInicial ?? [];
  late final List<dynamic> pontospoligonooriginal = widget.geomInicial ?? [];

  var camadas;

  late List<Map<String, dynamic>> camadasTileLayer = [];
  List<dynamic> camadasVetoriais = [];

  double currentZoom = 19;
  MapController mapController = MapController();
  // late LatLng currentCenter = widget.gpsInicial ??
  //     LatLng(-27.09, -52.61);
  late LatLng currentCenter, pinGps;

  String? geoToken;
  late String? geoHost;
  late Directory? appDir;

  String mensagemorientativa =
      'Clique em um ponto para selecioná-lo.\nClique no mapa para criar novos pontos.';

  @override
  void initState() {
    if (widget.geomInicial != null && widget.geomInicial!.length > 1) {
      print('entrou aqui 1');
      currentCenter = LatLng(
        double.parse(widget.geomInicial![0][0].toString()),
        double.parse(widget.geomInicial![0][1].toString()),
      );
      pinGps = currentCenter;
      currentCenterCarregado = true;
    }

    if (widget.gpsInicial != null) {
      print('entrou aqui 2');
      currentCenter = widget.gpsInicial!;
      pinGps = currentCenter;
      currentCenterCarregado = true;
    }

    _c = TextEditingController();

    _setaGeoTokenEDir();
    print('entrou aqui 3');
    super.initState();
  }

  Future<void> _setaGeoTokenEDir() async {
    setState(() {
      isLoading = true;
    });

    if (!currentCenterCarregado) {
      print('current nulll precisamos inicializar.');
      await getPosition();
    }
    clientHttp = context.read<ClientHttp>();
    preferencesProvider = context.read<PreferencesProvider>();

    // final String camadasativassalvasstr =
    //     preferencesProvider.getString('camadas_ativas') ?? ' ';
    // List<dynamic> camadasativassalvas = ['ecombr:streetview'];
    // if (camadasativassalvasstr.toString().length > 1) {
    //   camadasativassalvas = jsonDecode(camadasativassalvasstr.toString());
    // }

    //if (widget.online)
    geoToken = preferencesProvider.getGeoToken();
    geoToken = preferencesProvider.getGeoToken();
    //geoHost = clientHttp.dominio;
    var usuarioLogado = preferencesProvider.getString("UserModel");
    var um = UserModel.fromMap(jsonDecode(usuarioLogado!));
    geoHost = um.dominio;

    varsController = context.read<VarsController>();
    camadas = varsController.readVars('camadas2');
    print('asdf');
    print(camadas);

    camadasVetoriais = varsController.readVars('camadas_vetoriais') ?? [];
    print('tot camadasVetoriais: ${camadasVetoriais.length}');

    // camadas.forEach((c) {
    //   camadasTileLayer.add(
    //     {
    //       'tlo': TileLayer(
    //         //maxZoom: double.parse(c['max_zoom'].toString()),
    //         maxZoom: double.parse(c['max_zoom'].toString()),
    //         maxNativeZoom: int.parse(c['max_zoom'].toString()),
    //         //tileProvider: FMTC.instance('store').getTileProvider(),
    //         wmsOptions: WMSTileLayerOptions(
    //           baseUrl:
    //               'https://${clientHttp.dominio}/geo/wms?&token_geo=$geoToken&',
    //           // 'http://95.217.214.123:8080/geoserver/wms?',
    //           // layers: ['larlegal.inbru:Buenopolis_11_21'],
    //           layers: [c['layer']],
    //         ),
    //         backgroundColor: Colors.transparent,
    //       ),
    //       'ativo': camadasativassalvas.contains(c['layer']) ? true : false,
    //       'nome': c['nome'],
    //     },
    //   );
    // });
    // if (camadasativassalvas.isEmpty) camadas[0]['ativo'] = true;

    await syspaths.getApplicationDocumentsDirectory().then((value) {
      appDir = value;
      dirCarregado = true;
    });

    final opcoes = varsController.getOpcoes();
    print(opcoes);
    for (final o in opcoes) {
      var formheaders = o['headers'];

      if (formheaders.containsKey('sempre_mostra_poligonais') &&
          formheaders['sempre_mostra_poligonais'] == true) {
        //cada o é um tipo de formulário
        listagemProvider = ListagemProvider(tipo: formheaders['form']);
        await listagemProvider.open();

        String filtroBusca =
            Provider.of<PreferencesProvider>(context, listen: false)
                .filtroBusca;
        bool filtroSomenteFaltaSubir =
            Provider.of<PreferencesProvider>(context, listen: false)
                .filtroSomenteFaltaSubir;
        listagem = await listagemProvider.getAll(
            busca: filtroBusca,
            somenteFaltaSubir: filtroSomenteFaltaSubir,
            limit: formheaders['limite_itens_listagem']);

        for (final item in listagem) {
          final dadosdoitem = jsonDecode(item.dados);

          if (formheaders.containsKey('geoms_gps')) {
            if (formheaders['geoms_gps'] != null &&
                formheaders['geoms_gps'].length > 0) {
              formheaders['geoms_gps'].forEach((i) {
                // print('geoms_gps: ${i['fieldName']}');
                // print(jsonDecode(dadosdoitem[i['fieldName']]));
                if (dadosdoitem[i['fieldName']] != null) {
                  polygonsOutrosLotes.add(
                    UtilitariosParaMapas().criaPolygon(
                      jsonDecode(dadosdoitem[i['fieldName']]),
                      corBorda: i['corBorda'], //[200, 100, 200, 30],
                      corPreenchimento: i['corPreenchimento'],
                    ),
                  );
                }
              });
            }
          }
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  // void _zoom(double salto) {
  //   //TODO: colocar limites nos zoom+ e -
  //   setState(() {
  //     currentZoom = currentZoom + salto;
  //   });
  //   // print('currentZoom: $currentZoom');
  //   // mapController.move(currentCenter, currentZoom);
  //   mapController.move(mapController.center, currentZoom);
  // }

  // centerToMyPosition() async {
  //   Location location = new Location();

  //   bool _serviceEnabled;
  //   PermissionStatus _permissionGranted;

  //   _serviceEnabled = await location.serviceEnabled();
  //   if (!_serviceEnabled) {
  //     _serviceEnabled = await location.requestService();
  //     if (!_serviceEnabled) {
  //       return;
  //     }
  //   }

  //   _permissionGranted = await location.hasPermission();
  //   if (_permissionGranted == PermissionStatus.denied) {
  //     _permissionGranted = await location.requestPermission();
  //     if (_permissionGranted != PermissionStatus.granted) {
  //       return;
  //     }
  //   }
  //   LocationData _locationData;
  //   _locationData = await location.getLocation();
  //   print(_locationData);

  //   setState(() {
  //     currentCenter = LatLng(
  //         _locationData.latitude as double, _locationData.longitude as double);
  //   });
  //   mapController.move(currentCenter, currentZoom);
  // }

  atualizaCamadas(List<Map<String, dynamic>> camadas) {
    print('chamouatualizacamdas');
    print(camadas);
    setState(() {
      camadasTileLayer = camadas;
    });
  }

  Future<void> getPosition() async {
    setState(() {
      isLoading = true;
    });

    Position position;
    position = await _determinePosition();
    print('position: ');
    print(position);
    debugPrint('meiodo getpositionnnn3333');
    setState(() {
      currentCenter = LatLng(position.latitude, position.longitude);
      pinGps = currentCenter;
      isLoading = false;
      currentCenterCarregado = true;
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

  Future<void> _displayTextInputDialog(BuildContext context) async =>
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Digite o Texto'),
          content: TextField(
            autofocus: true,
            controller: _c,
            decoration: const InputDecoration(
              helperText:
                  'Este texto NÃO será salvo, fica somente \nnesta tela, e até ela ser fechada.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                });
              },
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    debugPrint('build ecgps');
    //TODO: se tudo funcionando da pra remover essas duas linhas abaixo, foram colocadas pra não dar pau no hotreload enquando desenvolvendo a tela
    // pontospoligonooriginal = widget.geomInicial ?? [];
    // pontospoligono = widget.geomInicial ?? [];

    // final tileProvider1 = Provider.of<StorageCachingTileProvider>(context);
    // var tileProvider1 =
    //     StorageCachingTileProvider(cachedValidDuration: Duration(days: 90));
    debugPrint(
      'isLoading = $isLoading \n currentCenterCarregado = $currentCenterCarregado \n !dirCarregado = $dirCarregado',
    );

    if (isLoading || !currentCenterCarregado || !dirCarregado) {
      debugPrint('ASDF');
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      final dirName = '${appDir!.path}/mapasoffline';
      final mapsDir = Directory(dirName);
      print('mapsDir $mapsDir');

      // var tileProvider1 = StorageCachingTileProvider(
      //     cachedValidDuration: Duration(days: 90), cacheName: "adicional1");

      // final tileProvider2 = StorageCachingTileProvider(
      //     cachedValidDuration: Duration(days: 90), cacheName: "B");
      // final tileProvider = StorageCachingTileProvider();
      // print(
      //     'tileprovider1 hashcode no build do gps page: ${tileProvider1.hashCode}');

      // print(
      //     'tileprovider2 hashcode no build do gps page: ${tileProvider1.hashCode}');

      // final tileLayer = TileLayerOptions(
      //   tileProvider: tileProvider1,
      //   urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
      //   subdomains: ['a', 'b', 'c'],
      // );

      // if (!widget.online) {
      print('geoToken: ' + geoToken.toString());
      tileLayer2 = TileLayer(
        maxZoom: 23,
        maxNativeZoom: 23,
        tileProvider: FMTC.instance('mapStore').getTileProvider(),
        wmsOptions: WMSTileLayerOptions(
          baseUrl: 'https://$geoHost/geo/wms?token_geo=$geoToken',
          layers: ['unificada'],
          transparent: true,
        ),
        //backgroundColor: Colors.transparent,
      );
      // }

      final List<Polygon> polygonsDosNucleos = [];
      final List<Polygon> polygonOriginalLoteAtual = [];
      final List<Polygon> polygonAtualDezenhando = [];

      // try {
      for (final element in camadasVetoriais) {
        if (element['geom'] != null && element['geom'].length > 0) {
          // print('geoms: ${element['nome']}');
          polygonsDosNucleos.add(
            UtilitariosParaMapas().criaPolygon(
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

      polygonAtualDezenhando.add(UtilitariosParaMapas()
          .criaPolygon(pontospoligono, corBorda: [0, 255, 0, 1]));

      polygonOriginalLoteAtual.add(
        UtilitariosParaMapas().criaPolygon(
          pontospoligonooriginal,
          corBorda: [0, 0, 0, 1],
          corPreenchimento: [100, 100, 100, 0],
        ),
      );

      final List<Marker> markersdopoligono = [];

      pontospoligono.asMap().forEach(
        (index, e) {
          markersdopoligono.add(
            Marker(
              width: 50,
              height: 50,
              point: LatLng(e[0], e[1]),
              child: Container(
                child: (index == widget.pontomovel)
                    ? InkWell(
                        onTap: () {
                          print('onTap inkwell');
                          //se toca no ponto já selecionado desmarca
                          setState(() {
                            widget.pontomovel = null;
                            mensagemorientativa =
                                'Clique em um ponto para selecioná-lo.\nClique no mapa para criar novos pontos.';
                          });
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const EcIcon('0xf0570', cor: Colors.red),
                            Text(
                              (index + 1).toString(),
                            ),
                          ],
                        ),
                      )
                    : InkWell(
                        //se clica num ponto seleciona ele
                        onTap: () {
                          print('onTap');
                          setState(() {
                            widget.pontomovel = index;
                            mensagemorientativa =
                                'Clique no mapa para nova posição do ponto.\nClique nele novamente para remover da seleção.';
                          });
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const EcIcon('0xf0570', cor: Colors.black),
                            Text(
                              (index + 1).toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      );

      LatLng computeCentroid(List<LatLng> points) {
        double latitude = 0;
        double longitude = 0;
        final int n = points.length;

        for (final LatLng point in points) {
          latitude += point.latitude;
          longitude += point.longitude;
        }

        return LatLng(latitude / n, longitude / n);
      }

      final List<Marker> infosAdicionaisDosPontos = [];

      final int totalPontos = pontospoligono.length;
      pontospoligono.forEachIndexed((i, element) {
        final List<LatLng> distancias = [];

        if (i < (totalPontos - 1)) {
          distancias.add(
            LatLng(pontospoligono[i][0], pontospoligono[i][1]),
          );
          distancias.add(
            LatLng(
              pontospoligono[i + 1][0],
              pontospoligono[i + 1][1],
            ),
          );
        } else {
          distancias.add(
            LatLng(pontospoligono[i][0], pontospoligono[i][1]),
          );
          distancias.add(
            LatLng(pontospoligono[0][0], pontospoligono[0][1]),
          );
        }

        if (distancias.length > 0)
          infosAdicionaisDosPontos.add(
            Marker(
              width: 60,
              point: computeCentroid(distancias),
              child: Container(
                // color: Colors.white.withAlpha(80),
                child: FittedBox(
                  child: Center(
                    child: (i < (totalPontos - 1))
                        ? _criaTextosMapa(
                            '${mapstoolkit.SphericalUtil.computeDistanceBetween(
                              mapstoolkit.LatLng(
                                pontospoligono[i][0],
                                pontospoligono[i][1],
                              ),
                              mapstoolkit.LatLng(
                                pontospoligono[i + 1][0],
                                pontospoligono[i + 1][1],
                              ),
                            ).toStringAsFixed(2)}m',
                          )
                        : _criaTextosMapa(
                            '${mapstoolkit.SphericalUtil.computeDistanceBetween(
                              mapstoolkit.LatLng(
                                pontospoligono[i][0],
                                pontospoligono[i][1],
                              ),
                              mapstoolkit.LatLng(
                                pontospoligono[0][0],
                                pontospoligono[0][1],
                              ),
                            ).toStringAsFixed(2)}m',
                          ),
                  ),
                ),
              ),
            ),
          );
      });

      if (pontospoligono.length > 0)
        infosAdicionaisDosPontos.add(
          Marker(
            width: 80,
            point: computeCentroid(
              pontospoligono.map((e) => LatLng(e[0], e[1])).toList(),
            ),
            child: Container(
              child: FittedBox(
                child: Center(
                  child: _criaTextosMapa(_areaPoligono(), cor: Colors.white),
                ),
              ),
            ),
          ),
        );

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              onPressed: () {
                _displayTextInputDialog(context);
              },
              icon: const Icon(Icons.text_fields),
            ),
            IconButton(
              onPressed: () {
                getPosition();
                mapController.move(currentCenter, currentZoom);
                // mapController.move(
                //     LatLng(-3.2146033982466697, -52.2370083922232), 19);
              },
              icon: const Icon(Icons.gps_fixed),
            ),
            // EcOnline(
            //   child: IconButton(
            //     onPressed: () {
            //       showDialog(
            //         context: context,
            //         builder: (_) => SeletorDeCamadas(
            //           camadas: camadasTileLayer,
            //           retorno: atualizaCamadas,
            //         ),
            //       );
            //     },
            //     icon: const Icon(Icons.layers),
            //   ),
            // ),
            IconButton(
              onPressed: () async {
                if (widget.tipo == 'ponto') {
                  await widget.salvarPosicaoGps!(
                    pinGps.latitude,
                    pinGps.longitude,
                  );
                } else {
                  await widget.salvarGeom!(pontospoligono);
                }

                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
            ),
          ],
        ),
        body: Stack(
          children: [
            FlutterMap(
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
                onTap: (pos, latlng) {
                  // setState(() {
                  //   currentCenter = latlng;
                  // });
                  print('onTap do build em:');
                  print(latlng);
                  if (widget.tipo == 'poligono') {
                    if (widget.pontomovel != null) {
                      final novospontos = [];
                      pontospoligono.asMap().forEach((index, e) {
                        if (index == widget.pontomovel) {
                          novospontos.add([latlng.latitude, latlng.longitude]);
                        } else {
                          novospontos.add(e);
                        }
                      });

                      setState(() {
                        pontospoligono = novospontos;
                      });
                    } else {
                      final novospontos = [];
                      pontospoligono.asMap().forEach((index, e) {
                        novospontos.add(e);
                      });
                      novospontos.add([latlng.latitude, latlng.longitude]);

                      setState(() {
                        pontospoligono = novospontos;
                      });
                    }
                  }
                  setState(() {
                    pinGps = latlng;
                  });
                },
                center: currentCenter,
                zoom: currentZoom,
                maxZoom: 23,
                minZoom: 2,
                interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              children: [
                // tileLayer1Options,
                // tileLayer,
                tileLayer2,

                // if (!widget.online) tileLayer2!,
                // if (widget.online)
                //   ...camadasTileLayer
                //       .where((w) => w['ativo'])
                //       .map((c) => c['tlo']),
                PolygonLayer(polygons: [...polygonsOutrosLotes]),
                if (widget.tipo == 'ponto')
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: pinGps,
                        // point: LatLng(51.5, -0.09),
                        child: Container(
                          // color: Colors.red,
                          child: Stack(
                            children: <Widget>[
                              Positioned(
                                left: 1,
                                top: 2,
                                child: EcIcon(
                                  widget.icone_item_no_mapa.toString(),
                                  cor: Colors.black,
                                  tamanho: 38,
                                ),
                              ),
                              EcIcon(
                                widget.icone_item_no_mapa.toString(),
                                cor: Colors.yellow,
                                tamanho: 38,
                              ),
                            ],
                          ),
                          // child: Stack(
                          //   alignment: Alignment.center,
                          //   children: [
                          //     EcIcon(
                          //       widget.icone_item_no_mapa.toString(),
                          //       cor: Colors.black,
                          //       tamanho: 38,
                          //     ),
                          //     EcIcon(
                          //       widget.icone_item_no_mapa.toString(),
                          //       cor: Colors.yellow,
                          //       tamanho: 30,
                          //     )
                          //   ],
                          // ),
                        ),
                      ),
                    ],
                  ),
                PolygonLayer(polygons: [...polygonsDosNucleos]),
                // if (widget.tipo == 'poligono') PolygonLayer(polygons: [...polygonOriginalLoteAtual]),
                if (widget.tipo == 'poligono')
                  PolygonLayer(polygons: [...polygonAtualDezenhando]),
                if (widget.tipo == 'poligono')
                  MarkerLayer(markers: [...infosAdicionaisDosPontos]),
                if (widget.tipo == 'poligono')
                  MarkerLayer(markers: [...markersdopoligono]),
              ],
            ),
            // if (widget.tipo == 'poligono') _mostraBoxDistancias(),

            const Positioned(
              right: 1,
              bottom: 1,
              child: Text('(c) OpenStreetMap', style: TextStyle(fontSize: 12)),
            ),
            EcOffline(
              child: Positioned(
                top: 1,
                left: 1,
                child: Container(
                  color: Color.fromRGBO(250, 250, 0, 0.4),
                  padding: EdgeInsets.all(1),
                  child: Text(
                    'Somente mapa offline (baixado) disponível! \nMedições e pontos são aproximados, e não \nsubstituem o trabalho topográfico de precisão.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
            EcOnline(
              child: Positioned(
                top: 1,
                left: 1,
                child: Container(
                  color: Color.fromRGBO(250, 250, 0, 0.4),
                  padding: EdgeInsets.all(1),
                  child: Text(
                    'Medições e pontos são aproximados, e não \nsubstituem o trabalho topográfico de precisão.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
            if (widget.tipo == 'poligono')
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  color: Colors.white.withOpacity(0.8),
                  margin: const EdgeInsets.all(0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.undo),
                        onPressed: () {
                          setState(() {
                            pontospoligono = pontospoligonooriginal;
                          });
                        },
                      ),
                      const Text(
                        'Reiniciar  ',
                        style: TextStyle(fontSize: 16),
                      )
                    ],
                  ),
                ),
              ),
            if (widget.pontomovel != null)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  margin: const EdgeInsets.all(0),
                  color: Colors.white.withOpacity(0.8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            pontospoligono.removeAt(widget.pontomovel as int);
                            widget.pontomovel = null;
                          });
                        },
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                      ),
                      const Text(
                        'Apagar ponto selecionado ',
                        style: TextStyle(fontSize: 16),
                      )
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 40,
              child: Container(
                color: Colors.white.withOpacity(0.8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.tipo == 'poligono')
                      Text(mensagemorientativa,
                          style: const TextStyle(fontSize: 18)),
                    Row(
                      children: const [
                        Text(
                          'Clique em ',
                          style: TextStyle(fontSize: 18),
                        ),
                        Icon(Icons.save),
                        Text(
                          ' para Salvar e Sair',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_c.text.isNotEmpty)
              Positioned(
                top: 55,
                left: 5,
                child: Container(
                  color: Theme.of(context).primaryColor.withAlpha(100),
                  width: MediaQuery.of(context).size.width - 10,
                  child: InkWell(
                    onTap: () => _displayTextInputDialog(context),
                    child: _criaTextosMapa(_c.text, size: 24),
                  ),
                ),
              ),
          ],
        ),
        // floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 14, left: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
          ),
        ),
      );
    } //else
  }

  Stack _criaTextosMapa(
    String txt, {
    Color cor = Colors.yellow,
    double size = 40,
  }) =>
      Stack(
        children: [
          Text(
            txt,
            style: TextStyle(
              fontSize: size,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 6
                ..color = Colors.black,
            ),
          ),
          Text(
            txt,
            style: TextStyle(
              fontSize: size,
              foreground: Paint()..color = cor,
            ),
          ),
        ],
      );

  String _areaPoligono() {
    final List<mapstoolkit.LatLng> pontos = [];
    pontospoligono.forEachIndexed((i, e) {
      pontos.add(mapstoolkit.LatLng(e[0], e[1]));
    });
    return '${mapstoolkit.SphericalUtil.computeArea(pontos).toStringAsFixed(2)}m2';
  }

  // _mostraBoxDistancias() {
  //   List<Text> textos = [];
  //   int totalPontos = pontospoligono.length;
  //   List<mapstoolkit.LatLng> pontos = [];

  //   pontospoligono.forEachIndexed(
  //     (i, e) {
  //       pontos.add(mapstoolkit.LatLng(e[0], e[1]));

  //       if (i < (totalPontos - 1)) {
  //         textos.add(
  //           Text('Ponto ${i + 1} ao ${i + 2}: ' +
  //               mapstoolkit.SphericalUtil.computeDistanceBetween(
  //                       mapstoolkit.LatLng(pontospoligono[i][0], pontospoligono[i][1]),
  //                       mapstoolkit.LatLng(pontospoligono[i + 1][0], pontospoligono[i + 1][1]))
  //                   .toStringAsFixed(2) +
  //               'm'),
  //         );
  //       } else {
  //         textos.add(
  //           Text('Ponto ${i + 1} a 1: ' +
  //               mapstoolkit.SphericalUtil.computeDistanceBetween(
  //                       mapstoolkit.LatLng(pontospoligono[i][0], pontospoligono[i][1]),
  //                       mapstoolkit.LatLng(pontospoligono[0][0], pontospoligono[0][1]))
  //                   .toStringAsFixed(2) +
  //               'm'),
  //         );
  //       }
  //     },
  //   );

  //   return Positioned(
  //     top: 55,
  //     left: 4,
  //     child: Container(
  //       padding: EdgeInsets.all(5),
  //       decoration: BoxDecoration(
  //           color: Colors.white.withAlpha(180),
  //           border: Border.all(
  //             color: Colors.white,
  //           ),
  //           borderRadius: BorderRadius.all(Radius.circular(6))),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           ...textos,
  //           Text('Área: ' + mapstoolkit.SphericalUtil.computeArea(pontos).toStringAsFixed(2) + 'm2'),
  //           // Text(mapstoolkit.SphericalUtil.computeHeading(
  //           //         mapstoolkit.LatLng(pontospoligono[0][0], pontospoligono[0][1]),
  //           //         mapstoolkit.LatLng(pontospoligono[1][0], pontospoligono[1][0]))
  //           //     .toString()),
  //           // Text(mapstoolkit.SphericalUtil.computeHeading(
  //           //         mapstoolkit.LatLng(pontospoligono[0][0], pontospoligono[0][1]),
  //           //         mapstoolkit.LatLng(pontospoligono[2][0], pontospoligono[2][0]))
  //           //     .toString()),
  //           // Text(mapstoolkit.SphericalUtil.computeHeading(
  //           //         mapstoolkit.LatLng(pontospoligono[0][0], pontospoligono[0][1]),
  //           //         mapstoolkit.LatLng(pontospoligono[3][0], pontospoligono[3][0]))
  //           //     .toString()),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
