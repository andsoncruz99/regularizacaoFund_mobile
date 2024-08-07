import 'package:flutter/material.dart';

class TextoParaMapa extends StatelessWidget {
  const TextoParaMapa({
    super.key,
    required this.txt,
    this.cor = Colors.yellow,
    this.tamanho = 12,
  });

  final double tamanho;
  final String txt;
  final Color cor;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Text(
            txt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tamanho,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4
                ..color = Colors.black,
            ),
          ),
          Text(
            txt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tamanho,
              foreground: Paint()..color = cor,
            ),
          ),
        ],
      );
}
