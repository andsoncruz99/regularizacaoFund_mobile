import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeletorDeCamadas extends StatefulWidget {
  const SeletorDeCamadas({super.key, required this.camadas, this.retorno});
  final camadas;
  final retorno;

  @override
  State<SeletorDeCamadas> createState() => _SeletorDeCamadasState();
}

class _SeletorDeCamadasState extends State<SeletorDeCamadas> {
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Camadas disponíveis:'),
        backgroundColor: Colors.white.withOpacity(0.75),
        content: Container(
          //TODO: selectall
          height: 350,
          //width: 200,
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Column(
            children: [
              // CheckboxListTile(
              //   contentPadding: EdgeInsets.all(0),
              //   title: Text("Inverter Todas"),
              //   controlAffinity: ListTileControlAffinity.leading,
              //   value: true,
              //   onChanged: (newValue) {
              //     print(newValue);

              //     widget.camadas.map((c) {
              //       setState(() {
              //         c['ativo'] = (c['ativo']) ? false : true;
              //       });
              //     });

              //     //camadasTileLayer.where((element) => element[''])
              //   },
              // ),
              SizedBox(
                height: 350,
                child: SingleChildScrollView(
                  //clipBehavior: Clip.none,
                  child: Column(
                    children: [
                      ...widget.camadas.map((c) {
                        var estaAtivo = c['ativo'];
                        return CheckboxListTile(
                          contentPadding: const EdgeInsets.all(0),
                          title: Text(c['nome']),
                          value: estaAtivo,
                          onChanged: (newValue) {
                            print(newValue);
                            setState(() {
                              //camadasTileLayer.where((element) => element[''])
                              c['ativo'] = newValue;
                              estaAtivo = newValue!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }).toList()
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Salvar'),
            onPressed: () async {
              final camadasativas = [];
              widget.camadas.forEach((c) {
                if (c['ativo'])
                  camadasativas.add(c['tlo'].wmsOptions.layers[0]);
              });

              print(camadasativas);

              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.setString(
                  'camadas_ativas', jsonEncode(camadasativas));

              widget.retorno(widget.camadas);
              Navigator.of(context).pop();
            },
          ),
          // TextButton(
          //   child: Text('Cancelar'),
          //   onPressed: () => setState(
          //     () {
          //       Navigator.of(context).pop();
          //     },
          //   ),
          // ),
        ],
      );
}
