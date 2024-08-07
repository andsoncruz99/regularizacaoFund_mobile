import 'dart:developer';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sishabi/src/shared/preferences_provider.dart';
import 'package:provider/provider.dart';

import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart' as syspaths;

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  var isLoading = true;
  bool _isUploading = false;

  //   late String directory;
  List dbsfiles = [];

  String prefsdata = '';

  late PreferencesProvider preferencesProvider;

  // void _listofFiles() async {
  //     directory = (await getApplicationDocumentsDirectory()).path;
  //     setState(() {
  //       file = io.Directory("$directory/resume/").listSync();  //use your folder name insted of resume.
  //     });

  Future<void> _listarDatabases() async {
    setState(() {
      isLoading = true;
    });

    final databasesPath = await getDatabasesPath();

    dbsfiles = Directory(databasesPath).listSync().where((file) {
      return file is File && file.path.toLowerCase().endsWith('.db');
    }).toList();

    dbsfiles.sort((a, b) {
      return a.uri
          .toFilePath()
          .toLowerCase()
          .compareTo(b.uri.toFilePath().toLowerCase());
    });

    preferencesProvider = context.read<PreferencesProvider>();
    final keys = preferencesProvider.getKeys();
    final prefsMap = Map<String, dynamic>();
    for (String key in keys) {
      prefsMap[key] = preferencesProvider.get(key);
    }

    setState(() {
      prefsdata = keys.toString();
      isLoading = false;
    });
  }

  Future<String> _getFileSize(File file) async {
    int size = await file.length();
    return filesize(size);
  }

  @override
  void initState() {
    super.initState();
    _listarDatabases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [], title: Text("Sobre este APP")),
      body: _isUploading
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), Text('aguarde...')],
            ))
          : Container(
              margin: EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(
                    'Este aplicativo faz parte da plataforma sisHABI / LarLEGAL.  \n\nRegistros no INPI com protocolos: \n   - 925077038\n   - 925077208   \n   - 925961728   \n\ne-comBR - Soluções em Tecnologia\nCNPJ: 07.635.117/0001-90 \nContato: (49) 3328-4065',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 30),
                  InkWell(
                    onTap: _listarDatabases,
                    child: Text('Bancos de Dados'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Column(children: [
                        ...dbsfiles.map(
                          (e) => Row(
                            children: [
                              InkWell(
                                onLongPress: () async {
                                  setState(() {
                                    _isUploading = true;
                                  });
                                  log(e.path);
                                  var msg = await simpleUploadFile(e.path);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(msg)));

                                  setState(() {
                                    _isUploading = false;
                                  });
                                },
                                child: Text(path.basename(e.path) + " "),
                              ),
                              FutureBuilder<String>(
                                initialData: "-",
                                future: _getFileSize(e),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: const CircularProgressIndicator(),
                                    );
                                  } else {
                                    if (snapshot.hasError) {
                                      return Icon(Icons.error);
                                    } else {
                                      return Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: Text('(${snapshot.data!})'),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        )
                      ]),
                    ),
                  ),
                  InkWell(
                    onLongPress: () async {
                      setState(() {
                        _isUploading = true;
                      });

                      final appDir =
                          await syspaths.getApplicationDocumentsDirectory();
                      final sourceDir = '${appDir.path}/imagens/';
                      print(sourceDir);

                      final zipFilePath =
                          '${appDir.path}/imagens.zip'; // Replace with the desired zip file path
                      await createZipFile(sourceDir, zipFilePath);
                      print('Zip file created at: $zipFilePath');
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Zip criado em:  $zipFilePath')));

                      var msg = await simpleUploadFile(zipFilePath);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));

                      // Apagando arquivo depois de subir
                      final zipFile = File(zipFilePath);
                      if (zipFile.existsSync()) {
                        await zipFile.delete();
                      }

                      setState(() {
                        _isUploading = false;
                      });
                    },
                    child: Text('Imagens'),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        "Detalhes para nerds: " + prefsdata,
                        style: TextStyle(fontSize: 12.0),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}

Future<void> createZipFile(String sourceDir, String zipFilePath) async {
  final encoder = ZipFileEncoder();
  encoder.create(zipFilePath);

  final sourceDirUri = Directory(sourceDir);
  if (!sourceDirUri.existsSync()) {
    throw FileSystemException("Source directory does not exist: $sourceDir");
  }

  await _addFilesToArchive(sourceDirUri, encoder, '');

  encoder.close();
}

Future<void> _addFilesToArchive(
    Directory dir, ZipFileEncoder encoder, String parentDir) async {
  final files = dir.listSync();

  for (final file in files) {
    if (file is File) {
      final fileName = file.path.substring(parentDir.length);
      encoder.addFile(file, fileName);
    } else if (file is Directory) {
      await _addFilesToArchive(file, encoder, parentDir);
    }
  }
}

Future<String> simpleUploadFile(String filePath) async {
  final url = 'https://www.sishabi.com.br/mobile_upload.php';

  try {
    final file = File(filePath);

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        //filename: file.path.split('/').last,
        // contentType: 'application/octet-stream',
      ),
    });

    final dio = Dio();
    final response = await dio.post(
      url,
      data: formData,
      // options: Options(
      //   contentType: 'multipart/binary',
      //   method: 'POST',
      // ),
    );

    if (response.statusCode == 200) {
      return 'Sucesso: ${response.data}';
    } else {
      return 'Falha: ${response.data}';
    }
  } catch (e) {
    return 'Error uploading file: $e';
  }
}
