import 'dart:convert';
import 'dart:developer';
import 'package:sishabi/src/shared/preferences_provider.dart';

class VarsController {
  bool _temConfigs = false;
  bool get temConfigs => _temConfigs;

  final PreferencesProvider preferencesProvider;

  VarsController(this.preferencesProvider);

  // save(Map<String, Map<String, String>> varsSalvar) async {
  Future<void> save(String varsName, varsSalvar) async {
    print('save vars_$varsName ');
    // print(varsSalvar);

    //Se for forms salva o form de cada tipo em chaves separadas
    if (varsName == 'forms') {
      print('eh form.');
      final List formsDisponiveis = [];

      for (final f in varsSalvar) {
        // print(f);

        formsDisponiveis.add({
          'destino': f['headers']['form'],
          'label': f['headers']['descr'],
          'detalhes': f['headers']['detalhes'] ?? ' ',
          'headers': f['headers']
        });

        print(f['headers']['form']);
        print('foi o form');

        await preferencesProvider.setString(
          'vars_files_${f['headers']['form']}',
          jsonEncode(f['files']),
        );

        await preferencesProvider.setString(
          'vars_${varsName}_${f['headers']['form']}',
          jsonEncode(f),
        );
      }

      //grava lista
      if (formsDisponiveis.isNotEmpty) {
        await preferencesProvider.setString(
            'vars_forms_lista', jsonEncode(formsDisponiveis));
      }
    } else {
      await preferencesProvider.setString(
          'vars_$varsName', jsonEncode(varsSalvar));
    }
  }

  // Future<Map<String, Map<String, String>>> read() async {
  //TODO: daria pra fazer voltar map/list ou null somente
  dynamic readVars(String varsName) {
    log('vars read $varsName');
    final String? v = preferencesProvider.getString('vars_$varsName');
    if (v != null) return jsonDecode(v);
    return null;
  }

  Map<String, dynamic> readCustom() {
    return readVars('custom') ?? {};
  }

  Map<String, dynamic> abasDisponiveis(String doque) {
    // print('abasdisponiveis formacao');
    final form = readVars('forms_$doque');
    final Map<String, dynamic> abasDisponiveis = {};
    for (final i in form['form']) {
      // print(i['id']);
      if (i['type'] == 'aba') {
        abasDisponiveis.putIfAbsent(i['id'], () => i['label']);
      }
    }
    return abasDisponiveis;
  }

  List<dynamic> formsDisponiveis() {
    final List<dynamic> formsDisponiveis = [];

    // print('forms disponiveis formacao');
    final v = readVars('forms_lista');
    if (v != null)
      for (final i in v) {
        formsDisponiveis.add(i);
      }

    return formsDisponiveis;
    // if (v != null)
    // return jsonDecode(v.toString());
    // else
    //   return {};
  }

  List<dynamic> getOpcoes() {
    _temConfigs = true;
    //as opçoes podem ser forms e mais outras coisas
    print('passou aqui getopcoes');
    return formsDisponiveis();

    // return {
    //   "Listagem de Pessoas REURB": "reurb",
    //   "Listagem de Pessoas HABITAÇÃO": "habitacao",
    //   "Listagem de ZeZe": "zzz",
    //   "Registrar Lead": "lead",
    // };
  }
}
