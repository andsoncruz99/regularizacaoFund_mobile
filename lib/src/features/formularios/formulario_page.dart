import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'ec_components.dart';
import '../../shared/vars_controller.dart';
// import 'package:deep_collection/deep_collection.dart';

import '../anexos/ec_images.dart';

String criaSubtitulo(var formData, var campos) {
  if (campos is List) {
    return campos
        .where((campo) => formData[campo] != null)
        .map((campo) => formData[campo])
        .join(' - ');
  }
  return formData[campos] ?? '';
}

class FormularioPage extends StatefulWidget {
  final int initialId;
  final String primaryKey;
  final String? initialDados;
  final String doque;
  final String? aba;
  final atualizarListagem;

  final Future<Map<String, dynamic>> Function({
    required int id,
    required Map<String, dynamic> formData,
  }) salvar;

// era onsta antes de mexer com o valor default
  const FormularioPage({
    super.key,
    required this.salvar,
    required int id,
    required this.primaryKey,
    required this.doque,
    String? dados,
    required this.atualizarListagem,
    this.aba,
  })  : initialDados = dados,
        initialId = id;

  @override
  _FormularioPageState createState() => _FormularioPageState();
}

class _FormularioPageState extends State<FormularioPage> {
  bool isLoading = true;
  bool isProcessing = false;
  bool confirmTabNavigation = false;
  late String? dados = widget.initialDados;
  late int id = widget.initialId;

  Map<String, dynamic> formAba = {};
  var vars;
  var files;
  var configs;
  var form;

  @override
  void initState() {
    _carregaForm();
    super.initState();
  }

  _carregaForm() async {
    setState(() {
      isLoading = true;
    });

    // await Future.delayed(Duration(milliseconds: 300));

    final VarsController varsController =
        Provider.of<VarsController>(context, listen: false);
    // print('vars do init form ${varsController.hashCode}');
    print('widget.doque ${widget.doque}');

    bool formTemAba = false;

    form = varsController.readVars('forms_${widget.doque}');

    var primeiraAba;
    for (final i in form['form']) {
      // print(i['id']);
      if (i['type'] == 'aba') {
        formTemAba = true;
        primeiraAba ??= i;
        if (i['id'] == widget.aba) {
          print('form aba i tem ${widget.aba}');
          formAba = i;
          continue;
        }
      }
    }

    if (widget.aba == null) formAba = primeiraAba;

    /*formAba ??= {
        'id': 'Aba1',
        'label': 'Aba1',
        'type': 'aba',
        'childrens': form['form'],
      };*/

    vars = varsController.readVars('vars');
    files = varsController.readVars('files');

    configs = varsController.readVars('configs');
    if (configs[widget.doque] == null) {
      EasyLoading.showError(
        'Faltam configurações para este formulário. Contate o administrador.',
      );
      Navigator.pop(context);
    } else {
      print(configs[widget.doque]);
    }

    //await Future.delayed(Duration(milliseconds: 100));

    setState(() {
      isLoading = false;
    });
  }

  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    //testes
    // Map<String, Object> aux = ; //.cast()['childrens'];
    // formAba['childrens'] = aux;
    // formAba = {
    //   "type": "gps",
    //   "label": "GPS 1",
    //   "id": "GPS",
    //   "fieldName": "gps1",
    // }; //.cast()['childrens'];

    //se tem pk e id > 0 entaõ disable no fieldName PK => type FieldPK
    //TODO: continuar estudando https://pub.dev/packages/deep_collection/example
    //pra deixar somente leitura quando for editar um registro , pra não deixar alterar a pk
    // if (widget.id > 0) {
    //   var x = formAba;
    // }

    // var vars = {
    //   "area_ocupadas": {
    //     "2": "VILA BORMAN",
    //     "5": "MONTE BELO",
    //     "6": "AREA IRREGULAR EXEMPLO",
    //     "7": "AREA ROUXINOL ",
    //     "8": "EFAPI - 25 DE JULHO",
    //     "9": "LOTEAMENTO VILAS BOAS",
    //     "10": "MEMORIAL GEOLINE",
    //     "11": "TESTE ESBOÇO"
    //   },
    //   "sexo.complemento": ["O", "M"],
    //   "sexo": {
    //     "M": "Masculino",
    //     "F": "Feminino",
    //     "O": "Outros",
    //   },
    //   "escolaridades.complemento": ["11", "22"],
    //   "escolaridades": {
    //     "11": "Analfabeto",
    //     "13": "Primeiro Grau Completo",
    //     "15": "Segundo Grau Completo",
    //     "16": "Ensino Fundamental Completo",
    //     "18": "Ensino Médio Completo",
    //     "20": "Ensino Superior Completo",
    //     "22": "Pós Graduado",
    //     "23": "Cursando Ensino Fundamental",
    //     "24": "Cursando o Ensino Médio",
    //     "25": "Cursando o Ensino Superior",
    //     "29": "Técnico - Ens. Pós-Secundário Não Superior"
    //   }
    // };

    // formAba = {
    //   "id": "Aba1",
    //   "label": "Aba1",
    //   "type": "aba",
    //   "childrens": [
    //     {
    //       "label": "Nome do Ocupante",
    //       "type": "TextField",
    //       "id": "PessoaNome",
    //       "fieldName": "Pessoa.nome",
    //       "validations": [
    //         {
    //           "type": "required",
    //           "message": "'Nome do Ocupante' deve ser preenchido"
    //         }
    //       ]
    //     },
    //     {
    //       "type": "TextArea",
    //       "label": "Apelidos",
    //       "id": "PessoafisicaApelido",
    //       "after":
    //           "texto depois do input text texto depois do input text texto depois do input text ",
    //       "fieldName": "Pessoafisica.apelido",
    //       "validations": [
    //         {"type": "required", "message": "'apelidos' devem ser preenchido"}
    //       ]
    //     },
    //     {
    //       "options": "escolaridades",
    //       "type": "SelectField",
    //       "label": "Escolaridade",
    //       "after":
    //           "texto do after do forma asdfa sdfa sdf asdf asdfasd bem comprido bem comprido bem comprido bem comprido bem comprido bem comprido bem comprido bem comprido",
    //       "id": "Pessoaescolaridade",
    //       "fieldName": "Pessoafisica.escolaridade",
    //       "complemento": {
    //         "type": "TextField",
    //         "label": "Escolaridade (Complemento)",
    //         "after": "A opção acima obrigado escrever aqui o complemento.",
    //         "id": "Pessoaescolaridadecomplemento",
    //         "fieldName": "Pessoafisica.escolaridade.complemento",
    //         "validations": [
    //           {
    //             "type": "required",
    //             "message": "'Escolaridade (Complemento)' deve ser preenchido"
    //           }
    //         ]
    //       }
    //     },
    //     {
    //       "options": "sexo",
    //       "type": "RadioField",
    //       "label": "Sexo",
    //       "after":
    //           "sexo sexo sexosexo sexo sexosexo sexo sexosexo sexo sexosexo sexo sexosexo sexo sexosexo sexo sexosexo sexo sexo",
    //       "id": "Pessoasexo",
    //       "fieldName": "Pessoafisica.sexo",
    //       "validations": [
    //         {"type": "required", "message": "'Sexo' deve ser preenchido"}
    //       ],
    //       "complemento": {
    //         "type": "TextField",
    //         "label": "Sexo (Complemento)",
    //         "after": "A opção acima obrigado escrever aqui o complemento.",
    //         "id": "Pessoasexocomplemento",
    //         "fieldName": "Pessoafisica.sexo.complemento",
    //         "validations": [
    //           {
    //             "type": "required",
    //             "message": "'Sexo (Complemento)' deve ser preenchido"
    //           }
    //         ]
    //       }
    //     },
    //     {
    //       "options": "sexo",
    //       "type": "CheckboxField",
    //       "label": "Preferencias",
    //       "id": "Pessoapreferencias",
    //       "fieldName": "Pessoafisica.preferencias",
    //     },
    //     {
    //       "type": "html",
    //       "label": 'HTMLxxxxx',
    //       "fieldName": "htmlhtml",
    //       //  "value": "<h2>Aga Dois aqui</h2>",
    //       "value":
    //           "<h1>a</h1><b>asdf</b><iframe width='560' height='315' src='https://www.youtube.com/embed/rCb46fuEahA' title='YouTube video player' frameborder='0' allow='accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture' allowfullscreen></iframe>",
    //     }
    //   ],
    // };
    // dados =
    //     '{"Pessoafisica.sexo": "3", "Pessoafisica.sexo.complemento":"xxx", "Pessoafisica.escolaridade": "11", "Pessoafisica.escolaridade.complemento": "yyy" }';

    // formAba = {
    //   "id": "anexos",
    //   "fieldName": "aba",
    //   "label": "Aba1",
    //   "type": "aba",
    //   "childrens": [
    //     {
    //       "label": "Nome do Ocupante",
    //       "type": "DateField",
    //       "id": "PessoaNome",
    //       "fieldName": "Pessoa.nome",
    //       "mask": "99/99/9999",
    //       "validations": [
    //         {
    //           "type": "required",
    //           "message": "'Nome do Ocupante' deve ser preenchido"
    //         },
    //         {
    //           "type": "date",
    //           // "param": 3,
    //           // "message": "data inválida 2",
    //         },
    //         {
    //           "type": "maxLength",
    //           "message": "'PessoaNome' é muito grande, tamanho máximo: 14",
    //           "param": 5
    //         },
    //         {
    //           "type": "minLength",
    //           "message": "'PessoaNome' muito curto, mínimo: 2",
    //           "param": 2
    //         }
    //       ]
    //     },
    //     {
    //       "label": "Data Nascimento",
    //       "type": "DateField",
    //       "id": "PessoaNascimento",
    //       "fieldName": "Pessoa.data_nascimento",
    //     },
    //     {
    //       "type": "GpsField",
    //       "label": "Gps",
    //       "id": "LeadGps",
    //       "fieldName": "gps"
    //     },
    //     {
    //       "type": "GpsField",
    //       "label": "Gps2",
    //       "icone_item_no_mapa": "0xe328",
    //       "id": "LeadGps2",
    //       "fieldName": "Lead.gps"
    //     }
    //   ],
    // };
    // dados =
    //     '{"Pessoafisica.sexo": "3", "Pessoafisica.sexo.complemento":"xxx", "Pessoafisica.escolaridade": "11", "Pessoafisica.escolaridade.complemento": "yyy", "Pessoa.data_nascimento" : "2005-09-22"}';

    String subtituloAba = '';

    Map<String, dynamic> initialValues = {};

    if (!isLoading) {
      Map<String, dynamic> defaults = {};
      defaults = pegaItensComDefaults(formAba['childrens']);

      defaults.addAll((dados != null) ? jsonDecode(dados.toString()) : {});

      print('defaults');
      print(defaults);
      print('id local: $id');

      subtituloAba =
          criaSubtitulo(defaults, configs[widget.doque]['listView']['title']);

      initialValues = defaults;
      dados = jsonEncode(defaults);

      confirmTabNavigation = form['headers']['confirm_tab_navigation'] ?? false;
    } //IF NOT LOADING
    //fazer o loop nos valores já salvos, e mesclar as opções do que tem o tipo checkbox

    // Map<String, dynamic> initialValuesMap = jsonDecode(dados.toString());

    // dynamic retornaCampoCaso(String tipo, Map<String, dynamic> map) {
    //   List<String> lista = [];
    //   map.forEach((key, value) {
    //     print('$key:$value');
    //     if (key == 'type' && value == tipo)
    //       lista.add(map['fieldName']);
    //     else if (key == 'childrens') retornaCampoCaso(tipo, map['childrens']);
    //     // else
    //     //   return null;
    //   });
    //   return lista;
    // }

    // var camposDateField = retornaCampoCaso('DateField', formAba)!;

    // // formAba.forEach((key, value) {
    // //   if (key == 'childrens') {
    // //     value.forEach((k, v) {
    // //       camposDateField.add(retornaCampoCaso('DataField', v)!);
    // //     });
    // //   }
    // // });

    // //var x = camposDateField.m ap((e) => initialValuesMap[e]!);
    // print('asdf');

    //TODO: deixar a pk não alteravel
    //dados tem os dados atuais, incluindo o valor atual da primarykey.
    //o plano é alterar o type da primerykey para textfieldkey - e la dentro readonly

    final Widget listaItensDoForm = (formAba != null)
        ? EcComponente(
            elemento: formAba,
            vars: vars,
            formKey: _formKey,
            notifyParent: () {},
          )
        : const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.fitWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(widget.doque.toUpperCase()),
                  if (formAba != null)
                    if (formAba.containsKey('label'))
                      Text(' / ${formAba['label']}')
                ],
              ),
              Text(
                'De: $subtituloAba',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    // width: 200.0,
                    // height: 100.0,
                    child: Shimmer.fromColors(
                      baseColor: Theme.of(context).colorScheme.secondary,
                      highlightColor: Colors.white,
                      child: const Text(
                        'Carregando...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : (formAba.containsKey('anexos'))
              ? EcImages(
                  doque: widget.doque,
                  id: id,
                  dados: dados.toString(),
                  usarAppBar: false,
                )
              : FormBuilder(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  initialValue: initialValues,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(2),
                    child: listaItensDoForm,
                  ),
                ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.background,
        child: isProcessing
            ? const CircularProgressIndicator()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (formAba != null)
                    if (formAba['aba_anterior'] != null && id > 0)
                      ElevatedButton(
                        onPressed: () async {
                          if (confirmTabNavigation) {
                            await _confirmarNavegacao(
                              context,
                              widget,
                              formAba,
                              'aba_anterior',
                            );
                          } else {
                            await Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FormularioPage(
                                  id: id,
                                  primaryKey: widget.primaryKey,
                                  salvar: widget.salvar,
                                  doque: widget.doque,
                                  dados: dados,
                                  atualizarListagem: widget.atualizarListagem,
                                  aba: formAba['aba_anterior'],
                                ),
                              ),
                            ).then((_) => widget.atualizarListagem());
                          }
                        },
                        child: const Text('<'),
                      ),
                  const SizedBox(width: 10),
                  if (formAba != null)
                    (formAba.containsKey('anexos'))
                        ? (formAba.containsKey('aba_proxima'))
                            ? ElevatedButton(
                                onPressed: () => {},
                                child: const Text('SALVAR'),
                              )
                            : ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('SALVAR DADOS!'),
                              )
                        : ElevatedButton(
                            onPressed: () async {
                              await salvarDadosForm(context, 'aba_proxima');
                            },
                            child: const Text('SALVAR DADOS'),
                          ),
                  const SizedBox(width: 10),
                  if (formAba != null)
                    if (formAba['aba_proxima'] != null && id > 0)
                      ElevatedButton(
                        onPressed: () async {
                          print(
                            'vou dar pushReplacement, formAba[aba_proxima] = ' +
                                formAba['aba_proxima'],
                          );
                          // await salvarDadosForm(context);

                          if (confirmTabNavigation) {
                            await _confirmarNavegacao(
                              context,
                              widget,
                              formAba,
                              'aba_proxima',
                            );
                          } else {
                            await Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FormularioPage(
                                  id: id,
                                  primaryKey: widget.primaryKey,
                                  salvar: widget.salvar,
                                  doque: widget.doque,
                                  dados: dados,
                                  atualizarListagem: widget.atualizarListagem,
                                  aba: formAba['aba_proxima'],
                                ),
                              ),
                            ).then((_) => widget.atualizarListagem());
                          }
                        },
                        child: const Text('>'),
                      )
                ],
              ),
      ),
    );
  }

  Future<void> salvarDadosForm(BuildContext context, String sentido) async {
    setState(() {
      isProcessing = true;
    });

    print('onpressed do form');
    //TODO: ver sobre estar chegando null como string do formulario {Temporario.id: null, Lead.id: null, Lead.area_ocupada_id: null, Lead.bairro: , Lead.nome: null, Lead.cpf_cnpj: null, Lead.estadocivil_id: null, Lead.telefones: null, Lead.ponto_referencia: null, Lead.gps: null}
    _formKey.currentState!.save();

    // if (_formKey.currentState!.validate()) {
    final formData = _formKey.currentState!.value;
    print('formData');
    print(formData);

    if (_formKey.currentState!.validate()) {
      print(_formKey.currentState!.value);

      // var resultadoTentativaDeInserir = await widget.salvar(formData);
      final resultadoTentativaDeInserir =
          await widget.salvar(id: id, formData: formData);

      if (resultadoTentativaDeInserir['deucerto']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultadoTentativaDeInserir['msg']),
            padding: const EdgeInsets.all(10),
            // backgroundColor: Colors.yellow[200],
          ),
        );

        id = resultadoTentativaDeInserir['dados'].id;
        dados = resultadoTentativaDeInserir['dados'].dados;

        if (formAba[sentido] != null) if (formAba.containsKey('anexos')) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EcImages(
                doque: widget.doque,
                id: id,
                dados: dados.toString(),
                usarAppBar: true,
              ),
            ),
          ).then((_) => widget.atualizarListagem());
        } else {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FormularioPage(
                id: id,
                primaryKey: widget.primaryKey,
                salvar: widget.salvar,
                doque: widget.doque,
                dados: resultadoTentativaDeInserir['dados'].dados,
                atualizarListagem: widget.atualizarListagem,
                aba: formAba[sentido],
              ),
            ),
          ).then((_) => widget.atualizarListagem());
        }
        else {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultadoTentativaDeInserir['msg']),
            padding: const EdgeInsets.all(10),
            backgroundColor: Colors.red[900],
          ),
        );
      }

      // await Future.delayed(Duration(milliseconds: 150));

      setState(() {
        isProcessing = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Revise os campos destacados deste formulário.'),
          padding: const EdgeInsets.all(10),
          backgroundColor: Colors.red[900],
        ),
      );
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _confirmarNavegacao(
    BuildContext context,
    widget,
    formAba,
    sentido,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('O que você deseja fazer?'),
        // content: const Text('Are you sure to remove the box?'),
        actions: [
          // The "Yes" button
          TextButton(
            onPressed: () async {
              // Remove the box
              // setState(() {
              //   _isShown = false;
              // });

              // Close the dialog
              Navigator.of(context).pop();
              await salvarDadosForm(context, sentido);
            },
            child: Text(
              (sentido == 'aba_proxima')
                  ? 'Salvar e Continuar'
                  : 'Salvar e Voltar Seção Anterior',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              print('nada acontece');
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              // Close the dialog
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => FormularioPage(
                    id: widget.id,
                    primaryKey: widget.primaryKey,
                    salvar: widget.salvar,
                    doque: widget.doque,
                    dados: dados,
                    atualizarListagem: widget.atualizarListagem,
                    aba: formAba[sentido],
                  ),
                ),
              ).then((_) => widget.atualizarListagem());
            },
            child: Text(
              (sentido == 'aba_proxima')
                  ? 'Somente ir para Próxima Seção'
                  : 'Somente Voltar Seção Anterior',
              style: const TextStyle(color: Colors.black),
            ),
          )
        ],
      ),
    );
  }
}

Map<String, dynamic> pegaItensComDefaults(List<dynamic> lista) {
  final Map<String, dynamic> defs = {};

  for (var i in lista) {
    if (i.containsKey('defaultValue')) {
      defs.addAll({i['fieldName']: i['defaultValue']});
    }

    if (i.containsKey('childrens')) {
      defs.addAll(pegaItensComDefaults(i['childrens']));
    }
  }

  return defs;
}

// void pegaDefaultsChildrens(List<dynamic> campos) {
//   campos.forEach((e) {
//     print(e);
//     pegaDefaults(e);
//   });
// }
