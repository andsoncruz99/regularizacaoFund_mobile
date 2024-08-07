import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UtilitariosParaMapas extends StatelessWidget {
  const UtilitariosParaMapas({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  Polygon criaPolygon(List<dynamic> pontos,
      {List<dynamic> corBorda = const [0, 0, 0, 0.1], List<dynamic> corPreenchimento = const [0, 0, 0, 0.0]}) {
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
      // color: Colors.green,
      isFilled: true,
      // color: Colors.primaries[Random().nextInt(Colors.primaries.length)].withOpacity(0.3),
      borderColor: _corBorda,
      borderStrokeWidth: 2,
    );
  }
}
