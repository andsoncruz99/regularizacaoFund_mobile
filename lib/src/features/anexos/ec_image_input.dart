import 'dart:io';

import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as syspaths;

import '../listagem/listagem_provider.dart';
import 'ec_assinatura_input.dart';

class EcImageInput extends StatefulWidget {
  final doque;
  final id;
  final fileId;
  final fileLabel;
  final fileDescr;
  final fileFormatoCaptura;

  const EcImageInput({
    super.key,
    this.doque,
    this.id,
    this.fileId,
    this.fileLabel,
    this.fileDescr,
    this.fileFormatoCaptura,
  });

  @override
  _EcImageInputState createState() => _EcImageInputState();
}

class _EcImageInputState extends State<EcImageInput> {
  File? _storedImage;

  late String dirName;
  late List<File> listaDeImagens;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregamentoInicial();
  }

  _carregamentoInicial() async {
    setState(() {
      listaDeImagens = [];
      isLoading = true;
    });

    // await Future.delayed(Duration(seconds: 2));

    print('appDir');
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    print(appDir);

    dirName =
        '${appDir.path}/imagens/${widget.doque}/${widget.id}/${widget.fileId}';

    final bool diretorioExiste = await Directory(dirName).exists();

    if (diretorioExiste) {
      final Directory dir = Directory(dirName);
      await dir.list().forEach((f) {
        // print('loop');

        if (f is File) {
          // print('f is File');
          // print(f);
          listaDeImagens.add(f);
        }
      });
      // print('listadeimagens');
      // print(_listaDeImagens);
    }

    setState(() {
      dirName = dirName;
      listaDeImagens = listaDeImagens; //.map((e) => e as File).toList();
      isLoading = false;
    });
  }

//TODO: quem sabe de tempos em tempos limpar as img temporarias /storage/emulated/0/Android/data/com.example.sishabi/files/Pictures
  Future<void> _takePicture({ImageSource src = ImageSource.camera}) async {
    final ImagePicker picker = ImagePicker();

    try {
      // PickedFile? imageFile = await _picker.getImage(
      //   source: src,
      //   maxWidth: 2048,
      // );

      final imageFile = await picker.pickImage(
        source: src,
        imageQuality: 99,
        maxHeight: 2048,
        maxWidth: 2048,
      );

      if (imageFile == null) return;

      print(imageFile.path);
      // setState(() {
      //   _storedImage = File(imageFile.path);
      // });

      final Directory dir = await Directory(dirName).create(recursive: true);
      print('dir.path = ${dir.path}');

      _storedImage = File(imageFile.path);
      final String fileName = path.basename(_storedImage!.path);
      print('arquivo capturado: $fileName');

      final savedImage = await _storedImage!.copy('$dirName/$fileName');
      setState(() {
        listaDeImagens.add(savedImage);
      });

      final CroppedFile? f = await _cropImage(savedImage);
      print('cropppedfile: ${f!.path}');

      //await f!.copy(savedImage.path);
      //await savedImage.copy(newPath);

      final file = File(f.path);
      await file.copy(savedImage.path);

      //await savedImage.delete();

      //marcando como não sincronizado quando salva imagem
      final ListagemProvider listagemProvider =
          ListagemProvider(tipo: widget.doque);
      await listagemProvider.open();
      await listagemProvider.marcaNaoSincronizado(widget.id);

      await _carregamentoInicial();
      // print('lista de arquivos em $dirName/:');
      // dir = Directory(dirName);
      // dir.list(recursive: false).forEach((f) {
      //   print(f);
      // });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao capturar imagem. Contate suporte.'),
          padding: const EdgeInsets.all(10),
          backgroundColor: Colors.red[900],
        ),
      );
    }
  }

  Future<void> deleteFile(File file) async {
    // print('deletando:' + file.path);
    await file.delete();
    setState(() {
      listaDeImagens = [];
    });

    //marcando como não sincronizado quando salva imagem
    final ListagemProvider listagemProvider =
        ListagemProvider(tipo: widget.doque);
    await listagemProvider.open();
    await listagemProvider.marcaNaoSincronizado(widget.id);

    await _carregamentoInicial();
  }

  Future<CroppedFile?> _cropImage(File imgOrig) async {
    //marcando como não sincronizado quando salva imagem
    final ListagemProvider listagemProvider =
        ListagemProvider(tipo: widget.doque);
    await listagemProvider.open();
    await listagemProvider.marcaNaoSincronizado(widget.id);

    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imgOrig.path,
      aspectRatioPresets: Platform.isAndroid
          ? [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ]
          : [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9
            ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Cropper',
        )
      ],
    );
    //if (croppedFile != null) {
    return croppedFile;
    //}
  }

  Widget _gridImagens() => Expanded(
        child: Container(
          child: GridView.count(
            primary: false,
            padding: const EdgeInsets.all(10),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            crossAxisCount: 3,
            children: listaDeImagens.map((e) {
              imageCache.clear();
              imageCache.clearLiveImages();
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        // print('arquivos antes/depois');
                        // print(e.path);
                        final CroppedFile? f = await _cropImage(e);
                        // print(f.path);
                        final file = File(f!.path);
                        await file.copy(e.path);

                        // if (f != null) {
                        //   await e.delete();
                        //   await f.copy(e.path);
                        // }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Erro2 ao capturar imagem. Contate suporte.'),
                            padding: const EdgeInsets.all(10),
                            backgroundColor: Colors.red[900],
                          ),
                        );
                      }
                      _carregamentoInicial();
                    },
                    child: Card(
                      child: Image.file(
                        e,
                        key: UniqueKey(),
                        width: double.infinity,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      color: Colors.redAccent,
                      child: GestureDetector(
                        onTap: () => deleteFile(e),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      height: 32,
                      color: const Color(0xDDFFFFFF),
                      child: TextButton(
                        onPressed: () {
                          EasyLoading.showSuccess(
                            e.path.toString(),
                            duration: const Duration(seconds: 1000),
                          );
                        },
                        child: Text(
                          filesize(e.lengthSync()),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // if (!isLoading)
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileLabel),
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.background,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('SALVAR E VOLTAR'),
        ),
      ),
      body: (!isLoading)
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    widget.fileDescr,
                    style: const TextStyle(fontSize: 18),
                  ),
                  (listaDeImagens.isNotEmpty)
                      ? _gridImagens()
                      : widget.fileFormatoCaptura.toString() != 'foto'
                          ? const SizedBox(
                              height: 1,
                            )
                          : TextButton(
                              onPressed: _takePicture,
                              child: _buildBoxSemImagem(),
                            ),

                  widget.fileFormatoCaptura.toString() == 'assinatura'
                      ? _buildColetarAssinatura()
                      : widget.fileFormatoCaptura.toString() == 'audio'
                          ? _buildColetarAudio()
                          : _buildColetarFoto(),

                  // const SizedBox(
                  //   height: 30,
                  // ),
                ],
              ),
            )
          : const SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(),
            ),
    );
  }

  Center _buildBoxSemImagem() => Center(
        child: Column(
          children: [
            Icon(
              Icons.photo_camera_back_rounded,
              size: 150,
              color: Colors.grey[350],
            ),
            const Text(
              'Sem anexos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );

  Column _buildColetarAssinatura() => Column(
        children: [
          // Text(
          //     'Atenção: havendo mais de uma assinatura coletada, somente a mais recente será considerada válida.'),
          // SizedBox(
          //   height: 30,
          // ),
          TextButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.create_outlined,
                  size: 40,
                ),
                Text('Coletar Assinatura'),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EcAssinaturaInput(
                    doque: widget.doque,
                    id: widget.id,
                    fileId: widget.fileId,
                    fileLabel: widget.fileLabel,
                  ),
                ),
              ).whenComplete(_carregamentoInicial);
            },
          )
        ],
      );

  Row _buildColetarFoto() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _takePicture,
            child: Row(
              children: const [
                Icon(
                  Icons.camera_alt,
                  size: 40,
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Tirar Foto',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              _takePicture(src: ImageSource.gallery);
            },
            child: Row(
              children: const [
                Icon(
                  Icons.file_copy,
                  size: 40,
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Pegar na Galeria',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              ],
            ),
          ),
        ],
      );

  Text _buildColetarAudio() {
    //TODO: feature de capturar audio https://pub.dev/packages/flutter_sound
    return const Text('Funcionalidade em Desenvolvimento.');
  }
}
