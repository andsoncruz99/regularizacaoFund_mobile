import 'package:flutter/material.dart';

class EcIcon extends StatelessWidget {
  final String nomeicone;
  final Color? cor;
  final double? tamanho;

  const EcIcon(this.nomeicone, {this.cor, this.tamanho});

  @override
  Widget build(BuildContext context) => Icon(
        IconData(
          int.tryParse(nomeicone) ?? 0xf02a1,
          fontFamily: 'MaterialIcons',
        ),
        color: cor,
        size: tamanho,
      );
}
