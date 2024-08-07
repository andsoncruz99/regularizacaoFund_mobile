import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:signature/signature.dart';

import '../listagem/listagem_provider.dart';
// import 'package:path/path.dart' as path;

class EcAssinaturaInput extends StatefulWidget {
  final doque;
  final id;
  final fileId;
  final fileLabel;

  const EcAssinaturaInput({
    super.key,
    this.doque,
    this.id,
    this.fileId,
    this.fileLabel,
  });

  @override
  _EcAssinaturaInputState createState() => _EcAssinaturaInputState();
}

class _EcAssinaturaInputState extends State<EcAssinaturaInput> {
  late SignatureController controller;

  // File? _storedImage;

  late String dirName;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _carregamentoInicial();

    controller = SignatureController(
      penStrokeWidth: 5,
      penColor: Colors.white,
    );
  }

  _carregamentoInicial() async {
    setState(() {
      isLoading = true;
    });

    final appDir = await syspaths.getApplicationDocumentsDirectory();
    print('appDir ec assinatura');
    print(appDir);

    dirName =
        '${appDir.path}/imagens/${widget.doque}/${widget.id}/${widget.fileId}';

    print('_dirName ec assinatura');
    print(dirName);

    final bool diretorioExiste = await Directory(dirName).exists();

    if (diretorioExiste) {
      final Directory dir = Directory(dirName);
      await dir.list().forEach((f) {
        print('loop');

        if (f is File) {
          print('f is File');
          print(f);
        }
      });
      // print('listadeimagens');
      // print(_listaDeImagens);
    }

    setState(() {
      dirName = dirName;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          //children: <Widget>[Text('asdf')],
          children: <Widget>[
            Expanded(
              child: Signature(
                controller: controller,
                backgroundColor: Colors.black,
              ),
            ),
            buildButtons(context),
            buildSwapOrientation(),
          ],
        ),
      );

  Widget buildSwapOrientation() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final newOrientation =
            isPortrait ? Orientation.landscape : Orientation.portrait;

        controller.clear();
        setOrientation(newOrientation);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPortrait
                  ? Icons.screen_lock_portrait
                  : Icons.screen_lock_landscape,
              size: 40,
            ),
            const SizedBox(width: 12),
            const Text(
              'Toque aqui para mudar a orientação.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButtons(BuildContext context) => Container(
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            buildCheck(context),
            //buildClear(),
            buildSair(),
          ],
        ),
      );

  Widget buildCheck(BuildContext context) => IconButton(
        iconSize: 36,
        icon: const Icon(Icons.check, color: Colors.green),
        onPressed: () async {
          if (controller.isNotEmpty) {
            // final signature = await exportSignature();
            await exportarImagemAssinatura();

            // await Navigator.of(context).push(MaterialPageRoute(
            //   builder: (context) => SignaturePreviewPage(signature: signature),
            // ));

            final ListagemProvider listagemProvider =
                ListagemProvider(tipo: widget.doque);
            await listagemProvider.open();
            await listagemProvider.marcaNaoSincronizado(widget.id);

            //controller.clear();
          }

          setOrientation(Orientation.portrait);
          Navigator.pop(context);
        },
      );

  // Widget buildClear() => IconButton(
  //       iconSize: 36,
  //       icon: Icon(Icons.restart_alt, color: Colors.blue),
  //       onPressed: () => controller.clear(),
  //     );

  Widget buildSair() => IconButton(
        iconSize: 36,
        icon: const Icon(Icons.close, color: Colors.red),
        onPressed: () => Navigator.pop(context),
      );

  Future<Uint8List?> exportSignature() async {
    final exportController = SignatureController(
      penStrokeWidth: 2,
      exportBackgroundColor: Colors.white,
      points: controller.points,
    );

    final signature = await exportController.toPngBytes();
    exportController.dispose();

    return signature;
  }

  Future<void> exportarImagemAssinatura() async {
    final exportController = SignatureController(
      penStrokeWidth: 2,
      exportBackgroundColor: Colors.white,
      points: controller.points,
    );

    // final signature = await exportController.toImage();
    final signature = await exportController.toPngBytes();

    print('indo gravar em $dirName');
    final Directory dir = await Directory(dirName).create(recursive: true);
    print('dir.path = ${dir.path}');

    // _storedImage = File(signature.path);
    // String fileName = path.basename(_storedImage!.path);
    // print('arquivo capturado: ' + fileName);

//===============
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final Random rnd = Random();

    String getRandomString(int length) => String.fromCharCodes(
          Iterable.generate(
            length,
            (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
          ),
        );

    final File assinaturaParaSalvar =
        File('$dirName/ass_${getRandomString(12)}.png');

    assinaturaParaSalvar
        .writeAsBytesSync(List<int>.from(signature!.buffer.asInt8List()));
    print(
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ASSINATURA QUE SERA SALVA',
    );
    print(assinaturaParaSalvar);
//===============
    // final savedImage =
    //     await assinaturaParaSalvar!.copy('$dirName/assinatura.png');
    // final savedImage = await signature!.copy('$dirName/assinatura.png');

    exportController.dispose();
    //return signature;
  }

  void setOrientation(Orientation orientation) {
    if (orientation == Orientation.landscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }
}

// class SignaturePreviewPage extends StatelessWidget {
//   final Uint8List signature;

//   const SignaturePreviewPage({
//     Key key,
//     @required this.signature,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) => Scaffold(
//         backgroundColor: Colors.black,
//         appBar: AppBar(
//           leading: CloseButton(),
//           title: Text('Store Signature'),
//           centerTitle: true,
//           actions: [
//             IconButton(
//               icon: Icon(Icons.done),
//               onPressed: () => storeSignature(context),
//             ),
//             const SizedBox(width: 8),
//           ],
//         ),
//         body: Center(
//           child: Image.memory(signature, width: double.infinity),
//         ),
//       );

//   Future storeSignature(BuildContext context) async {
//     final status = await Permission.storage.status;
//     if (!status.isGranted) {
//       await Permission.storage.request();
//     }

//     final time = DateTime.now().toIso8601String().replaceAll('.', ':');
//     final name = 'signature_$time.png';

//     final result = await ImageGallerySaver.saveImage(signature, name: name);
//     final isSuccess = result['isSuccess'];

//     if (isSuccess) {
//       Navigator.pop(context);

//       Utils.showSnackBar(
//         context,
//         text: 'Saved to signature folder',
//         color: Colors.green,
//       );
//     } else {
//       Utils.showSnackBar(
//         context,
//         text: 'Failed to save signature',
//         color: Colors.red,
//       );
//     }
//   }
// }
