import 'dart:developer';
// import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

// import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;
// import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:provider/provider.dart';
import 'package:sishabi/src/shared/preferences_provider.dart';

import '../../shared/client_http.dart';
import '../../shared/vars_controller.dart';

class GpsBaixarCachePage extends StatefulWidget {
  @override
  _AutoCachedTilesPageContentState createState() =>
      _AutoCachedTilesPageContentState();
}

class _AutoCachedTilesPageContentState extends State<GpsBaixarCachePage> {
  final northController = TextEditingController();
  final eastController = TextEditingController();
  final westController = TextEditingController();
  final southController = TextEditingController();
  final centerLatController = TextEditingController();
  final centerLngController = TextEditingController();
  final radiusController = TextEditingController(text: '0.5');
  final minZoomController = TextEditingController(text: '1');
  final maxZoomController = TextEditingController(text: '19');

//TODO:talvez colocar a ultima localizacao valida
  LatLng currentCenter = LatLng(-28.04605385516952, -49.0140434212992);

  final MapController mapController = MapController();
  String? geoToken;
  // late Directory appDir;

  bool isLoading = true;

  bool isLoadingEstimativas = true;

  bool isQualidadeMaxima = false;

  bool cancelamentoEmAndamento = false;

  late TileLayer tileLayer1;

  late final ClientHttp clientHttp;
  late final PreferencesProvider preferencesProvider;

  late String? geoHost;

  List<dynamic> camadasVetoriais = [];
  late final VarsController varsController;

  List<double>? _selectedBoundsCir;

  final decimalInputFormatter = FilteringTextInputFormatter(
    RegExp(r'^-?\d{0,3}\.?\d{0,6}$'),
    allow: true,
  );

  var tilesEstim = 0;

  @override
  void initState() {
    _setaGeoTokenEDir();

    Future.delayed(Duration(seconds: 1)).then((_) {
      _centraliza().then(
        (value) =>
            atualizaEstimativa(double.tryParse(radiusController.text) ?? 0.5),
      );
    });

    // SchedulerBinding.instance.addPostFrameCallback(
    //     (_) => atualizaEstimativa(double.tryParse(radiusController.text) ?? 1));

    centerLatController.addListener(_handleCircleInput);
    centerLngController.addListener(_handleCircleInput);
    radiusController.addListener(_handleCircleInput);

    super.initState();
  }

  Future<void> _setaGeoTokenEDir() async {
    setState(() {
      isLoading = true;
    });

    clientHttp = context.read<ClientHttp>();
    preferencesProvider = context.read<PreferencesProvider>();

    geoToken = preferencesProvider.getGeoToken();
    print('geoToken: $geoToken');
    geoHost = clientHttp.dominio;

    varsController = Provider.of<VarsController>(context, listen: false);
    camadasVetoriais = varsController.readVars('camadas_vetoriais') ?? [];
    print('tot camadasVetoriais: ${camadasVetoriais.length}');

    // appDir = await syspaths.getApplicationDocumentsDirectory();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _centraliza() async {
    Position position;
    position = await _determinePosition();
    log('position: $position');

    // setState(() {
    currentCenter = LatLng(position.latitude, position.longitude);
    // });

    centerLatController.text = position.latitude.toString();
    centerLngController.text = position.longitude.toString();

    mapController.move(currentCenter, currentZoom);
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

  @override
  void dispose() {
    debugPrint('disposou');
    northController.dispose();
    eastController.dispose();
    westController.dispose();
    southController.dispose();
    centerLatController.dispose();
    centerLngController.dispose();
    radiusController.dispose();
    minZoomController.dispose();
    maxZoomController.dispose();
    mapController.dispose();
    FMTC.instance('mapStore').download.cancel();
    super.dispose();
  }

  void _handleCircleInput() {
    final lat =
        double.tryParse(centerLatController.text) ?? _selectedBoundsCir?[0];
    final lng =
        double.tryParse(centerLngController.text) ?? _selectedBoundsCir?[1];
    final rad =
        double.tryParse(radiusController.text) ?? _selectedBoundsCir?[2];
    if (lat == null || lng == null || rad == null) {
      return;
    }
    setState(() => _selectedBoundsCir = [lat, lng, rad]);
  }

  Future<void> _showErrorSnack(String errorMessage) async {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    });
  }

  Future<void> _loadMap(
    TileLayer options,
    bool background,
  ) async {
    _hideKeyboard();
    final zoomMin = int.tryParse(minZoomController.text);
    if (zoomMin == null) {
      await _showErrorSnack(
        'Invalid zoom level. Minimum zoom level must be defined.',
      );
      return;
    }
    final zoomMax = int.tryParse(maxZoomController.text) ?? zoomMin;
    if (zoomMin < 1 || zoomMin > 23 || zoomMax < 1 || zoomMax > 23) {
      await _showErrorSnack(
        'Invalid zoom level. Must be inside 1-23 range (inclusive).',
      );
      return;
    }
    if (zoomMax < zoomMin) {
      await _showErrorSnack(
        'Invalid zoom level. Maximum zoom must be larger than or equal to minimum zoom.',
      );
      return;
    }
    if ((_selectedBoundsCir == null)) {
      await _showErrorSnack(
          'Invalid bounds area. Region bounds must be defined.');
      return;
    }

    if (!background) {
      final _region = CircleRegion(
          LatLng(
            _selectedBoundsCir![0],
            _selectedBoundsCir![1],
          ),
          _selectedBoundsCir![2]);

      final _downloadable = _region.toDownloadable(
        minZoom: zoomMin,
        maxZoom: zoomMax,
        options: options,

        // parallelThreads: 16,
        //preventRedownload: true,
      );

      // var te = await FMTC.instance('mapStore').download.check(_downloadable);
      // log(name: "tiles estimados: ", te.toString());

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.7),
          title: const Text('Baixando Área:'),
          content: StreamBuilder<DownloadProgress>(
            // initialData: DownloadProgress.placeholder(),

            stream: FMTC.instance('mapStore').download.startForeground(
                  parallelThreads: 10,
                  disableRecovery: true,
                  region: _downloadable,
                  skipExistingTiles: true,
                  //instanceId: math.Random().nextInt(50000),
                  //bufferMode: DownloadBufferMode.disabled,
                  //bufferLimit: 1000,
                ),
            builder: (ctx, snapshot) {
              if (snapshot.hasError) {
                debugPrint(snapshot.error.toString());

                FMTC.instance('mapStore').download.cancel();

                cancelarDownload().then((value) {
                  setState(() {
                    cancelamentoEmAndamento = false;
                  });
                });
                return Text(
                    'Falha ao iniciar download. Por gentileza repita a ação novamente.');

                //return Text('Falha: ${snapshot.error.toString()}');
              }
              final tileIndex = snapshot.data?.successfulTiles ?? 0;
              final tilesAmount = snapshot.data?.maxTiles ?? 0;
              final tilesErrored = snapshot.data?.failedTiles ?? 0;

              final progressPercentage = snapshot.data?.percentageProgress ?? 0;
              return getLoadProgresWidget(
                ctx,
                tileIndex,
                tilesAmount,
                tilesErrored,
                progressPercentage,
              );
            },
          ),
          actions: <Widget>[
            TextButton(
                child: const Text('Sair'),
                onPressed: () {
                  log("Sair");
                  setState(() {
                    cancelamentoEmAndamento = true;
                  });
                  cancelarDownload().then((value) {
                    setState(() {
                      cancelamentoEmAndamento = false;
                    });
                  });
                  Navigator.of(ctx).pop();
                })
          ],
        ),
      );
    }
    // else {
    //   // FMTC.instance('store').download.requestIgnoreBatteryOptimizations();
    //   FMTC.instance('mapStore').download.startForeground(
    //         region: CircleRegion(
    //           LatLng(_selectedBoundsCir![0], _selectedBoundsCir![1]),
    //           _selectedBoundsCir![2],
    //         ).toDownloadable(
    //           zoomMin,
    //           zoomMax,
    //           options,
    //           parallelThreads: 8,
    //           preventRedownload: false,
    //         ),
    //       );
    // }
  }

  Future<void> cancelarDownload() async {
    if (FMTC.instance('mapStore').download.isPaused())
      await FMTC.instance('mapStore').download.cancel();

    FMTC.instance('mapStore').download.mataInstancia(0);
  }

  Future<void> _deleteCachedMap() async {
    _hideKeyboard();
    final currentCacheSize =
        await FMTC.instance('mapStore').stats.storeSizeAsync / 1024;

    final currentCacheItems =
        await FMTC.instance('mapStore').stats.storeLengthAsync;

    // String currentCacheAmountString = '';
    // final List<String> cacheNames = [];
    // for (final store
    //     in await FMTC.instance.rootDirectory.stats.storesAvailableAsync) {
    //   currentCacheAmountString +=
    //       "Cached Tiles In '${store.storeName}': ${await FMTC.instance(store.storeName).stats.storeLengthAsync}";
    //   cacheNames.add(store.storeName);
    // }
    // print(cacheNames.length);
    // log(currentCacheAmountString);
    final List<TextButton> buttons = [
      TextButton(
        child: const Text('Cancelar'),
        onPressed: () => Navigator.pop(context, 'false'),
      ),
      TextButton(
        child: const Text('Limpar todos os caches'),
        onPressed: () => Navigator.pop(context, 'all'),
      ),
    ];

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Cache'),
        content: Text(
          'Tem certeza que quer apagar os ${currentCacheSize.toStringAsFixed(2)} MB / $currentCacheItems tiles do cache?'
          // '$currentCacheAmountString'
          ,
        ),
        actions: buttons,
      ),
    );
    if (result != 'false') {
      await FMTC.instance('mapStore').manage.resetAsync();

      debugPrint('limpeza ok');

      await _showErrorSnack('Limpeza de Cache concluída!');
      setState(() {});
    }
  }

  void _hideKeyboard() => FocusScope.of(context).requestFocus(FocusNode());

  Widget getBoundsInputWidget(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boundsSectionWidth = size.width * 0.8;
    final zoomSectionWidth = size.width - boundsSectionWidth;

    final zoomInputWidth = zoomSectionWidth - 32;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Raio (dist. km do ponto central)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            width: (boundsSectionWidth / 4 * 1.6) - 7.2,
                            child: TextField(
                              textAlign: TextAlign.center,
                              decoration:
                                  const InputDecoration(hintText: 'Center Lat'),
                              inputFormatters: [decimalInputFormatter],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              controller: centerLatController,
                            ),
                          ),
                          SizedBox(
                            width: (boundsSectionWidth / 4 * 1.6) - 7.2,
                            child: TextField(
                              textAlign: TextAlign.center,
                              decoration:
                                  const InputDecoration(hintText: 'Center Lng'),
                              inputFormatters: [decimalInputFormatter],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              controller: centerLngController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: (boundsSectionWidth / 4 * 1.6) - 7.2,
                        child: TextField(
                          textAlign: TextAlign.center,
                          decoration:
                              const InputDecoration(hintText: 'Radius (km)'),
                          inputFormatters: [decimalInputFormatter],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          controller: radiusController,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          Container(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 2),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('ZOOM', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(
                  width: zoomInputWidth,
                  child: TextField(
                    textAlign: TextAlign.center,
                    maxLength: 2,
                    decoration:
                        const InputDecoration(counterText: '', hintText: 'min'),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: const TextInputType.numberWithOptions(),
                    controller: minZoomController,
                  ),
                ),
                SizedBox(
                  width: zoomInputWidth,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: 'max',
                    ),
                    maxLength: 2,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: const TextInputType.numberWithOptions(),
                    controller: maxZoomController,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget getZoomBox() {
    return Container(
      width: 10,
      height: 30,
      // width: MediaQuery.of(context).size.width,
      color: Colors.amber,
      // child: Row(
      //   // mainAxisSize: MainAxisSize.min,
      //   children: <Widget>[
      //     //Text('ZOOM', style: Theme.of(context).textTheme.titleMedium),
      //     TextField(
      //       textAlign: TextAlign.center,
      //       maxLength: 2,
      //       decoration: const InputDecoration(
      //           label: Text("Zoom (min)"), counterText: '', hintText: 'min'),
      //       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      //       keyboardType: const TextInputType.numberWithOptions(),
      //       controller: minZoomController,
      //     ),
      //     TextField(
      //       textAlign: TextAlign.center,
      //       decoration: const InputDecoration(
      //           label: Text("Zoom (max)"), counterText: '', hintText: 'max'),
      //       maxLength: 2,
      //       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      //       keyboardType: const TextInputType.numberWithOptions(),
      //       controller: maxZoomController,
      //     )
      //   ],
      // ),
    );
  }

  Widget getLoadProgresWidget(
    BuildContext context,
    int tileIndex,
    int tileAmount,
    int tilesErrored,
    double progress,
  ) {
    if (tileAmount == 0) {
      tileAmount = 1;
    }
    return progress == 0
        ? Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: Text(
                  "Preparando área...",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Text(
                "Pode levar alguns segundos... mas já já aceleramos.",
                style: TextStyle(fontSize: 12),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  children: <Widget>[
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.grey,
                        value: progress / 100,
                      ),
                    ),
                    Align(
                      child: Text(
                        progress == 100.0
                            ? '100%'
                            : ('${progress.toStringAsFixed(1)}%'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                progress == 100.0
                    ? 'Download Finalizado com Sucesso!'
                    : '$tileIndex de $tileAmount\nAguarde',
                // : '${tilesErrored > 0 ? '' : ('${tileIndex - tilesErrored}/')}$tileIndex/$tileAmount\nAguarde',
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Visibility(
                visible: tilesErrored > 0,
                child: Text(
                  'Tivemos falha no download de $tilesErrored dos $tileAmount pedacinhos do mapa (${((tilesErrored / tileAmount) * 100).toStringAsFixed(3)}%). Ao finalizar, navegue pela região de interesse e confira se eles irão fazer falta. Se sim, faça o download novamente.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Visibility(
                visible: false, //tilesErrored.isNotEmpty,
                child: Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Errored Tiles: $tilesErrored',
                        style: Theme.of(context).textTheme.titleSmall!.merge(
                              const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            reverse: true,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              String test = '';
                              try {
                                //test = tilesErrored.reversed.toList()[index];
                              } finally {
                                // ignore: control_flow_in_finally
                                return Column(
                                  children: [
                                    Text(
                                      test
                                          .replaceAll('https://', '')
                                          .replaceAll('http://', '')
                                          .split('/')[0],
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .merge(const TextStyle(
                                              color: Colors.red)),
                                      textAlign: TextAlign.start,
                                    ),
                                    Text(
                                      test
                                          .replaceAll(
                                            test
                                                .replaceAll('https://', '')
                                                .replaceAll('http://', '')
                                                .split('/')[0],
                                            '',
                                          )
                                          .replaceAll('https:///', '')
                                          .replaceAll('http:///', ''),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .merge(const TextStyle(
                                              color: Colors.red)),
                                      textAlign: TextAlign.start,
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
  }

  double currentZoom = 11;
  void _zoom(double salto) {
    setState(() {
      currentZoom = currentZoom + salto;
      mapController.move(currentCenter, currentZoom);
    });
    // print('currentZoom: $currentZoom');
  }

  @override
  Widget build(BuildContext context) {
    final List<Polygon> polygons = [];

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
        // color: Colors.primaries[math.Random().nextInt(Colors.primaries.length)]
        //     .withOpacity(0.3),
        borderColor: _corBorda,
        borderStrokeWidth: 2,
      );
    }

    for (final element in camadasVetoriais) {
      if (element['geom'] != null && element['geom'].length > 0) {
        // print('geoms: ${element['nome']}');
        polygons.add(
          _criaPolygon2(
            element['geom'],
            corBorda: element['corBorda'],
            corPreenchimento: element['corPreenchimento'],
          ),
        );
      }
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else {
      tileLayer1 = TileLayer(
        maxZoom: 23,
        maxNativeZoom: 23,
        tileProvider: FMTC.instance('mapStore').getTileProvider(),
        userAgentPackageName: "dart",
        wmsOptions: WMSTileLayerOptions(
          baseUrl: 'https://${geoHost!}/geo/wms?token_geo=$geoToken',
          layers: ['unificada'],
          transparent: true,
          // baseUrl:
          //     'https://prefeitura.sishabi.com.br/geo/wms?&token_geo=$geoToken&',
          // layers: 'ecombr:streetview,prefeitura:Vila_esperan_a'.split(','),
          // baseUrl: 'http://95.217.214.123:8080/geoserver/wms?',
          // baseUrl: 'http://95.217.214.123:8080/geoserver/wms?',
          // layers:
          //     "ecombr:streetview,larlegal.gruporms:Santa_Catarina__Itinga___Santa_Monica0,larlegal.gruporms:SC_Itinga,larlegal.gruporms:Otofoto__Itinga___Santa_Monica"
          //         .split(','),
        ),
        // backgroundColor: Colors.transparent,
      );

      return Scaffold(
        appBar: AppBar(
          title: const Text('Baixar Mapa'),
          actions: [
            IconButton(
              onPressed: _centraliza,
              icon: const Icon(Icons.gps_fixed),
            ),
            IconButton(
              onPressed: () async {
                await _deleteCachedMap();
              },
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
        body: Column(
          children: [
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.end,
            //   children: [
            //     TextButton(onPressed: () => _zoom(1), child: Text('mais')),
            //     TextButton(onPressed: () => _zoom(-1), child: Text('menos')),
            //   ],
            // ),
            Expanded(
              child: Stack(
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
                      initialCenter: currentCenter,
                      // maxZoom: (camadaAdicional.length > 1) ? 21 : 19,
                      maxZoom: 23,
                      minZoom: 3,
                      initialZoom: 10,
                      interactiveFlags:
                          InteractiveFlag.all & ~InteractiveFlag.rotate,
                      onTap: (_, latlng) {
                        setState(() {
                          centerLatController.text = latlng.latitude.toString();
                          centerLngController.text =
                              latlng.longitude.toString();
                          // shapeChooserResult = shapeChooser.onTapReciever(point);
                        });
                      },
                    ),
                    children: [
                      tileLayer1,
                      PolygonLayer(polygons: [...polygons]),
                      _selectedBoundsCir == null
                          ? PolygonLayer(
                              polygons: [],
                            )
                          : CircleRegion(
                              LatLng(
                                _selectedBoundsCir![0],
                                _selectedBoundsCir![1],
                              ),
                              _selectedBoundsCir![2],
                            ).toDrawable(
                              fillColor: Colors.green.withAlpha(128),
                              borderColor: Colors.green,
                            ),
                    ],
                  ),
                  Container(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: EdgeInsets.all(10),
//                      color: Theme.of(context).primaryColor.withOpacity(0.70),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).primaryColor.withOpacity(0.7),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: isLoadingEstimativas
                            ? Container(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(),
                              )
                            : Animate(
                                effects: [ShakeEffect()],
                                child: Text(
                                    "Pedacinhos a baixar: ${tilesEstim.toString()} (zoom ${minZoomController.text} a ${maxZoomController.text})"),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Padding(
            //   padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
            //   child: TextButton(
            //     onPressed: _centraliza,
            //     child: Text('centralizar minha posição'),
            //   ),
            // ),
            // getBoundsInputWidget(context),

            Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                    'Distância do ponto central (${double.tryParse(radiusController.text)!.toStringAsFixed(2).toString()} km):',
                    style: TextStyle(fontSize: 16))),

            Slider(
              value: double.parse(radiusController.text),
              min: 0.1,
              max: 2,
              divisions: 19,
              label:
                  '${double.parse(radiusController.text).toStringAsFixed(1)} km',
              onChanged: atualizaEstimativa,
            ),
            //getZoomBox(),

            SwitchListTile(
              title: Text('Qualidade máxima'),
              value: isQualidadeMaxima,
              onChanged: (value) {
                isQualidadeMaxima = value;

                maxZoomController.text = (isQualidadeMaxima) ? '23' : '19';

                log('isQualidadeMaxima: ' + value.toString());
                log('maxZoom: ' + maxZoomController.text);

                atualizaEstimativa(double.tryParse(radiusController.text) ?? 1);
              },
              secondary: Icon(Icons.high_quality),
              subtitle: Text('Permite ir até zoom 23 (padrão é 19).'),
            ),
            //Text(FMTC.instance('mapStore').stats.storeLength.toString() +
            //  ' tiles em cache.'),

            //getBoundsInputWidget(context),
            // Text(
            //     "Zoom de ${minZoomController.text} até ${maxZoomController.text}"),
            SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  cancelamentoEmAndamento
                      ? FloatingActionButton.extended(
                          onPressed: () {},
                          icon: const Icon(Icons.download),
                          label: const Text('Aguarde...'),
                        )
                      : FloatingActionButton.extended(
                          onPressed: () async {
                            setState(() {
                              cancelamentoEmAndamento = true;
                            });
                            await _loadMap(tileLayer1, false);
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Baixar Área Selecionada'),
                        ),
                ],
              ),
            ),
            SizedBox(height: 10)
          ],
        ),
      );
    } //else loading
  }

  void atualizaEstimativa(double n) async {
    log('atualizando estimativas para $n km e maxZoom ${maxZoomController.text}');

    setState(() {
      isLoadingEstimativas = true;
    });

    radiusController.text = n.toString();

    _handleCircleInput();
    final _region = CircleRegion(
        LatLng(
          _selectedBoundsCir![0],
          _selectedBoundsCir![1],
        ),
        _selectedBoundsCir![2]);

    final _downloadable = _region.toDownloadable(
      minZoom: int.tryParse(minZoomController.text) ?? 1,
      maxZoom: int.tryParse(maxZoomController.text) ?? 19,
      options: tileLayer1,
    );

    log('aqui');

    tilesEstim = await FMTC.instance('mapStore').download.check(_downloadable);

    setState(() {
      isLoadingEstimativas = false;
    });

    log(name: "tiles estimados: ", tilesEstim.toString());
  }
}
