import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ImageCropperPage extends StatefulWidget {
  final String title;
  final File imageFile;

  const ImageCropperPage({required this.title, required this.imageFile});

  @override
  _ImageCropperPageState createState() => _ImageCropperPageState(imageFile);
}

enum CropperState {
  free,
  picked,
  cropped,
}

class _ImageCropperPageState extends State<ImageCropperPage> {
  late CropperState state;
  File? imageFile;

  _ImageCropperPageState(this.imageFile);

  @override
  void initState() {
    print('iniststate image cropper');
    super.initState();
    state = CropperState.picked;
  }

  @override
  Widget build(BuildContext context) {
    print('build image cropper');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: imageFile != null ? Image.file(imageFile!) : Container(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: () {
          if (state == CropperState.free) {
            _pickImage();
          } else if (state == CropperState.picked) {
            _cropImage();
          } else if (state == CropperState.cropped) {
            _clearImage();
          }
        },
        child: _buildButtonIcon(),
      ),
    );
  }

  Widget _buildButtonIcon() {
    if (state == CropperState.free) {
      return const Icon(Icons.add);
    } else if (state == CropperState.picked) {
      return const Icon(Icons.crop);
    } else if (state == CropperState.cropped) {
      return const Icon(Icons.clear);
    } else {
      return Container();
    }
  }

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    imageFile = pickedImage != null ? File(pickedImage.path) : null;
    if (imageFile != null) {
      setState(() {
        state = CropperState.picked;
      });
    }
  }

  Future<void> _cropImage() async {
    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile!.path,
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
          toolbarTitle: 'Recortar Imagem',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Recortar Imagem',
        )
      ],
    );
    if (croppedFile != null) {
      imageFile = croppedFile as File;
      setState(() {
        state = CropperState.cropped;
      });
    }
  }

  void _clearImage() {
    imageFile = null;
    setState(() {
      state = CropperState.free;
    });
  }
}
