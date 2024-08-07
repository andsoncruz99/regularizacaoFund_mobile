import 'dart:convert';
import 'dart:io';

// import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:provider/provider.dart';

import '../../shared/vars_controller.dart';
import 'ec_image_input.dart';

class EcImages extends StatefulWidget {
  final String doque;
  final int id;
  final String dados;
  final bool usarAppBar;

  const EcImages({
    super.key,
    required this.doque,
    required this.id,
    required this.dados,
    required this.usarAppBar,
  });

  @override
  _EcImagesState createState() => _EcImagesState();
}

class _EcImagesState extends State<EcImages> {
  var files;
  List<Map<String, dynamic>> itensDoFiles = [];

  @override
  void initState() {
    print('initstate do ecimages');
    _carregaDados();
    super.initState();
  }

  Future<void> _carregaDados() async {
    final VarsController varsController =
        Provider.of<VarsController>(context, listen: false);

    files = varsController.readVars('files_${widget.doque}');

    // print(files);
    itensDoFiles = [];

    if (files != null)
      for (final f in files) {
        // print(f["id"].toString());
        final Map<String, dynamic> i = {
          'label': f['name'],
          'id': f['id'],
          'fieldName': f['id'],
          'formato_captura': f['formato_captura'] ?? 'foto',
          'campo_para_mostrar': f['campo_para_mostrar'] ?? 'id',
          'exibir_quando_nulo': f['exibir_quando_nulo'],
        };
        itensDoFiles.add(i);
      }

    setState(() {});
  }

/*
  Future<Widget?> _dirStats(String f) async {
    // filesize();

    print('appDir');
    var appDir = await syspaths.getApplicationDocumentsDirectory();
    print(appDir);

    var _dirName = '${appDir.path}/imagens/${widget.doque}/${widget.id}/$f';

    var totais = dirStatSync(_dirName);

    return Text(
        '${totais['fileNum']} arquivos, total de ${filesize(totais['size'])}');
  }
  */

  Future<Widget?> _totalArquivosDir(String f) async {
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final dirName = '${appDir.path}/imagens/${widget.doque}/${widget.id}/$f';
    final totais = dirStatSync(dirName);
    return Container(
      decoration: BoxDecoration(
        color: (int.parse(totais['fileNum'].toString()) > 0)
            ? Colors.green.withOpacity(0.35)
            : Colors.red.withOpacity(0.35),
        border: Border.all(
          color: Theme.of(context).primaryColor,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      width: 40,
      height: 40,
      child: Center(child: Text('${totais['fileNum']}')),
    );
  }

  Map<String, int> dirStatSync(String dirPath) {
    int fileNum = 0;
    int totalSize = 0;
    final dir = Directory(dirPath);
    try {
      if (dir.existsSync()) {
        dir
            .listSync(recursive: true, followLinks: false)
            .forEach((FileSystemEntity entity) {
          if (entity is File) {
            fileNum++;
            totalSize += entity.lengthSync();
          }
        });
      }
    } catch (e) {
      print(e.toString());
    }

    return {'fileNum': fileNum, 'size': totalSize};
  }

  Widget _buildFilesTypesList() {
    final dados = jsonDecode(widget.dados);
    print('dados para usar');
    print(dados);

    print('itensdofiles:');
    print(itensDoFiles);

    // var data = [
    //   {"title": 'Avengers', "release_date": '10/01/2019'},
    //   {"title": 'Creed', "release_date": '10/01/2019'},
    //   {"title": 'Jumanji', "release_date": '30/10/2019'},
    // ];
    // var newMap = groupBy(data, (Map obj) => obj['release_date']);
    // print(newMap);
    // var newMap = groupBy(itensDoFiles, (Map obj) => obj['itensDoFiles']);
    // print(newMap);

    final itensDoFiles2 = [];

    for (final i in itensDoFiles) {
      i['campo_para_mostrar'] =
          (dados[i['campo_para_mostrar']] ?? i['exibir_quando_nulo']) ?? '';

      if (i['campo_para_mostrar'].toString().isNotEmpty) {
        itensDoFiles2.add(i);
      }
    }

    //TODO: fazer isso buscável
    return GroupedListView<dynamic, String>(
      elements: itensDoFiles2,
      groupBy: (element) => element['campo_para_mostrar'],
      //groupComparator: (value1, value2) => value2.compareTo(value1),
      itemComparator: (item1, item2) =>
          item1['campo_para_mostrar'].compareTo(item2['campo_para_mostrar']),
      order: GroupedListOrder.DESC,
      useStickyGroupSeparators: true,

      groupSeparatorBuilder: (String value) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      itemBuilder: (c, element) => Card(
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Container(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: FutureBuilder<Widget?>(
              future: _totalArquivosDir(element['fieldName']),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data!;
                } else {
                  return const Text('_');
                }
              },
            ),
            title: Text(
              "${element["label"]}",
              style: const TextStyle(fontSize: 18),
            ),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EcImageInput(
                    doque: widget.doque,
                    id: widget.id,
                    fileId: element['fieldName'],
                    fileLabel: element['label'],
                    fileDescr: element['campo_para_mostrar'],
                    fileFormatoCaptura: element['formato_captura'],
                  ),
                ),
              ).whenComplete(_carregaDados);
            },
          ),
        ),
      ),
    );

    // return SingleChildScrollView(
    //   child: Column(
    //     children: itensDoFiles.map((e) {
    //       String textoFileNaListagem = (dados[e["campo_para_mostrar"]] ??
    //               e["exibir_quando_nulo"] ??
    //               '${e["campo_para_mostrar"]}') +
    //           " - ${e["label"]}";
    //       return Column(
    //         children: [
    //           Card(
    //             child: TextButton(
    //               onPressed: () {
    //                 Navigator.push(
    //                   context,
    //                   MaterialPageRoute(builder: (context) {
    //                     return EcImageInput(
    //                         doque: widget.doque,
    //                         id: widget.id,
    //                         fileId: e["fieldName"],
    //                         fileLabel: e["label"],
    //                         fileFormatoCaptura: e["formato_captura"]);
    //                   }),
    //                 ).whenComplete(() => _carregaDados());
    //               },
    //               child: Container(
    //                 color: Colors.green,
    //                 child: ListTile(
    //                   // title: Text("${e["fieldName"]}: ${e["label"]}"),
    //                   title: Text(textoFileNaListagem),
    //                   subtitle: FutureBuilder<Widget?>(
    //                     future: _dirStats(e["fieldName"]),
    //                     builder: (context, snapshot) {
    //                       if (snapshot.hasData) {
    //                         return snapshot.data!;
    //                       } else {
    //                         return Text('_');
    //                       }
    //                     },
    //                   ),
    //                 ),
    //               ),
    //             ),
    //           ),
    //         ],
    //       );
    //     }).toList(),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    print('widget.usarappbar = ${widget.usarAppBar}');
    return Scaffold(
      appBar: widget.usarAppBar
          ? AppBar(
              title: Text(
                'Fotos / Images ${widget.doque.toUpperCase()} ${widget.id}',
              ),
              actions: const [],
            )
          : null,
      body: _buildFilesTypesList(),
      // body: EcImagesFilesList(
      //   itensDoFiles: itensDoFiles,
      //   doque: widget.doque,
      //   id: widget.id,
      // ),
      // body: SingleChildScrollView(
      //   child: Column(
      //     children: itensDoFiles
      //         .map((e) => Column(
      //               children: [
      //                 Text(
      //                   e["label"],
      //                   style: Theme.of(context).textTheme.subtitle1,
      //                 ),
      //                 EcImageInput(
      //                   doque: widget.doque,
      //                   id: widget.id,
      //                   fileId: e["fieldName"],
      //                 ),
      //               ],
      //             ))
      //         .toList(),
      //     // children: [EcImageInput()],
      //   ),
      // ),
    );
  }
}
