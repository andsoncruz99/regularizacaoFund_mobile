import 'dart:convert';
// import 'dart:html';

import 'package:collapsible/collapsible.dart';
import 'package:easy_mask/easy_mask.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
// import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
import 'package:collection/collection.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../ec_icons.dart';
import '../mapas/ec_gps_page.dart';
import 'package:validatorless/cnpj.dart';
import 'package:validatorless/cpf.dart';
import 'package:latlong2/latlong.dart';
import '../../shared/ec_online.dart';
//import 'package:fwfh_webview/fwfh_webview.dart';
//import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
//import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
// import 'package:maps_toolkit/maps_toolkit.dart';

Color? geraColor({List<dynamic>? cor}) {
  if (cor != null) {
    try {
      return Color.fromRGBO(
        cor[0],
        cor[1],
        cor[2],
        double.parse(cor[3].toString()),
      );
    } catch (e) {
      return null;
    }
  }
  return null;
}

class EcComponente extends StatefulWidget {
  final Map<String, dynamic> elemento;
  final vars;
  final formKey;

  final Function() notifyParent;

  const EcComponente({
    required this.elemento,
    required this.vars,
    required this.formKey,
    required this.notifyParent,
  });

  @override
  State<EcComponente> createState() => _EcComponenteState();
}

class _EcComponenteState extends State<EcComponente> {
  refresh() {
    print('refresh chamado do ${widget.elemento['fieldName']}');
    setState(() {});
    widget.notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    // print('build do ${widget.elemento['fieldName']}');
    // elemento = elemento;
    //todo elemento por padrão é visivel
    bool visivel = true;

    //TODO: showIf da ABA
    if (widget.elemento.containsKey('showIf') &&
        widget.elemento['type'] != 'aba') {
      // debugPrint('${widget.elemento['fieldName']} tem showIf');
      //MAS, SE TEM SHOWIF o padrão é escondido
      visivel = false;

      widget.elemento['showIf'].forEach((k, v) {
        debugPrint('k=$k, v=$v');

        if (widget.formKey.currentState.fields[k.toString()].value != null) {
          print(
            'formKey.currentState.fields[${k.toString()}].value => ' +
                widget.formKey.currentState.fields[k.toString()].value,
          );

          v.forEach((tipoCondicao, valorCondicao) {
            switch (tipoCondicao) {
              case 'OR':
                debugPrint('tipoCondicao: ' + tipoCondicao);
                valorCondicao.forEach((condicaoValor) {
                  if (condicaoValor ==
                      widget.formKey.currentState.fields[k.toString()].value) {
                    visivel = true;
                  }
                });

                break;
              default:
                debugPrint('tipoCondicao: ' + tipoCondicao);
            }
          });
        } else {
          // print('formKey.currentState.fields[${k.toString()}] tava null. ');
        }
      });
    }

    return Visibility(
      key: ValueKey(widget.elemento),
      visible: visivel,
      maintainState: true,
      child: _buildComponente(),
    );
  }

  Widget _buildComponente() {
    switch (widget.elemento['type']) {
      case 'fotos':
        return const Text('fotos');

      case 'aba':
        return EcAba(
          elemento: widget.elemento,
          vars: widget.vars,
          formKey: widget.formKey,
          notifyParent: refresh,
        );

      case 'hidden':
      case 'hiddenField':
        return Visibility(
          visible: false,
          maintainState: true,
          child: Container(
            color: Colors.yellow,
            child: FormBuilderTextField(
              name: widget.elemento['fieldName'].toString(),
              decoration: _criaInputDecoration(widget.elemento),
              readOnly: true,
            ),
          ),
        );

      case 'readonly':
      case 'ReadOnlyField':
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: FormBuilderTextField(
            name: widget.elemento['fieldName'].toString(),
            enabled: false,
            decoration: _criaInputDecoration(widget.elemento),
          ),
        );

      case 'DateField':
      //TODO: IMPORTANTE fazer data funcionar
      // return EcDate3(this.elemento);
      case 'Nome':
      case 'TextField':
      case 'IntField':
      case 'NumField':
      case 'MoneyField':
      case 'FloatField':
        return EcTextField(
          widget.elemento,
          widget.vars,
          widget.formKey,
        );

      case 'select':
      case 'Select':
      case 'SelectField':
        return EcSelect(
          widget.elemento,
          widget.vars,
          widget.formKey,
          refresh,
        );

      case 'CheckboxField':
        return EcCheckbox(
          elemento: widget.elemento,
          vars: widget.vars,
          formKey: widget.formKey,
          notifyParent: refresh,
        );

      case 'RadioboxField':
      case 'Radiobox':
      case 'RadioField':
        return EcRadiobox(
          elemento: widget.elemento,
          vars: widget.vars,
          formKey: widget.formKey,
          notifyParent: refresh,
        );

      case 'textarea':
      case 'TextArea':
      case 'TextareaField':
        return EcTextArea(widget.elemento);

      // case 'assinatura':
      // break;
      case 'gps':
      case 'GpsField':
        return EcGps(
          elemento: widget.elemento,
          formKey: widget.formKey,
        );
      case 'geom':
      case 'GeomField':
        return EcGeoms(
          elemento: widget.elemento,
          formKey: widget.formKey,
        );

      case 'collapsible':
        return EcCollapsible(
          elemento: widget.elemento,
          vars: widget.vars,
          formKey: widget.formKey,
          notifyParent: refresh,
        );
      // return EcLotes3(elemento: this.elemento, vars: this.vars);

      case 'tabela':
      case 'fieldset':
        return EcFieldset(
          elemento: widget.elemento,
          vars: widget.vars,
          formKey: widget.formKey,
          notifyParent: refresh,
        );

      case 'htmlField':
      case 'html':
        return HtmlWidget(widget.elemento['value'].toString());
      // return WebView(
      //   'https://www.youtube.com/watch?v=rCb46fuEahA',
      //   aspectRatio: 1,
      // );
      // return HtmlWidget(
      //   '<h1>a</h1><b>asdf</b><iframe width="560" height="315" src="https://www.youtube.com/embed/rCb46fuEahA" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>',
      //   factoryBuilder: () => MyWidgetFactory(),
      // );

      default:
        return Text(
          '${'Tipo de Campo não encontrado (' + widget.elemento.cast()['type']} )',
        );
    }
  }
}

class EcCollapsible extends StatefulWidget {
  final Map<String, dynamic> elemento;
  final vars;
  final formKey;

  final Function() notifyParent;

  const EcCollapsible({
    required this.elemento,
    this.vars,
    this.formKey,
    required this.notifyParent,
  });

  @override
  _EcCollapsibleState createState() => _EcCollapsibleState();
}

class _EcCollapsibleState extends State<EcCollapsible> {
  bool _collapsed = true;

  void _toggleCollapsible() {
    _collapsed = !_collapsed;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> elementosFilhos = widget.elemento.cast()['childrens'];
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      // padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: const BorderRadius.all(
          Radius.circular(12),
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  widget.elemento['label'].toString(),
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: _toggleCollapsible,
                  icon:
                      Icon(_collapsed ? Icons.expand_more : Icons.expand_less),
                ),
              ],
            ),
            Collapsible(
              axis: CollapsibleAxis.vertical,
              maintainState: true,
              collapsed: _collapsed,
              child: Column(
                children: [
                  ...elementosFilhos.map(
                    (e) => EcComponente(
                      elemento: e,
                      vars: widget.vars,
                      formKey: widget.formKey,
                      notifyParent: widget.notifyParent,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EcRadiobox extends StatefulWidget {
  final Map<String, dynamic> elemento;
  final vars;
  final formKey;

  final List<bool> isComplementoVisible = [];

  final Function() notifyParent;
  EcRadiobox({
    required this.elemento,
    required this.vars,
    required this.formKey,
    required this.notifyParent,
  });

  @override
  _EcRadioboxState createState() => _EcRadioboxState();
}

class _EcRadioboxState extends State<EcRadiobox> {
  late String opcoesNome;

  @override
  void initState() {
    opcoesNome = widget.elemento['options'];
    //tornaComlementoVisivel();
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => tornaComlementoVisivel());
  }

  //isso aqui roda sempre quando terminar de fazer o build (aí já vai ter criado o campo de complemento)
  tornaComlementoVisivel() {
    try {
      if (widget.formKey != null) {
        if (widget.elemento.containsKey('complementos')) {
          widget.elemento['complementos'].asMap().forEach((i, c) {
            if (!widget.isComplementoVisible.contains(i)) {
              widget.isComplementoVisible.add(true);
            }

            if (widget.formKey.currentState
                        .fields[widget.elemento['fieldName'].toString()] !=
                    null &&
                c['opcoes'].indexOf(
                      widget.formKey.currentState
                          .fields[widget.elemento['fieldName'].toString()].value
                          .toString(),
                    ) >=
                    0) {
              widget.isComplementoVisible[i] = true;
            } else {
              widget.isComplementoVisible[i] = false;
            }
          });
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Erro relacionado ao complemento do radiobox. Contate suporte.',
          ),
          padding: const EdgeInsets.all(10),
          backgroundColor: Colors.red[900],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // print('build do radiobox');
    tornaComlementoVisivel();

    var errMsg = '';
    var required = false;
    if (widget.elemento.containsKey('validations')) {
      if (widget.elemento['validations']!.any((i) => i['type'] == 'required')) {
        required = true;
        final r = widget.elemento['validations']!
            .firstWhere((i) => i['type'] == 'required');
        errMsg = r['message'];
      }
    }

    final String opcoesNome = widget.elemento['options'].toString();
    final List<FormBuilderFieldOption<Object>> opcoesRadio = [];
    widget.vars[opcoesNome].forEach((k, v) {
      opcoesRadio.add(FormBuilderFieldOption(value: k, child: Text(v)));
    });

    final complementos = [];
    if (widget.elemento.containsKey('complementos')) {
      widget.elemento['complementos'].asMap().forEach(
        (i, c) {
          complementos.add(
            Visibility(
              maintainState: true,
              visible: widget.isComplementoVisible[i],
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: EcComponente(
                  elemento: widget.elemento['complementos'][i]['elemento'],
                  vars: widget.vars,
                  formKey: widget.formKey,
                  notifyParent: widget.notifyParent,
                ),
              ),
            ),
          );
        },
      );
    }

    final Color radioboxCleanButtonColor =
        geraColor(cor: widget.elemento['radioboxCleanButtonColor']) ??
            Colors.black87;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Column(
            children: [
              //heber trabalhando

              FormBuilderRadioGroup(
                decoration: _criaInputDecoration(widget.elemento),
                name: widget.elemento['fieldName'].toString(),
                validator: required
                    ? FormBuilderValidators.compose(
                        [FormBuilderValidators.required(errorText: errMsg)],
                      )
                    : null,
                options: opcoesRadio.toList(growable: false),
                onChanged: (val) {
                  debugPrint('val no onchanged do radio2: $val');
                  if (widget.elemento.containsKey('complementos')) {
                    widget.elemento['complementos'].asMap().forEach((i, c) {
                      if (c['opcoes'].indexOf(val.toString()) >= 0) {
                        widget.isComplementoVisible[i] = true;
                      } else {
                        widget.isComplementoVisible[i] = false;
                        //quando seleciona outra coisa precisa zerar esse campo
                        widget.formKey.currentState
                            .fields[c['elemento']['fieldName'].toString()]
                            .didChange('');
                      }
                    });
                    // setState(() {});
                  }
                  widget.notifyParent();
                },
              ),
              if (widget.elemento.containsKey('complementos')) ...complementos,
            ],
          ),
          Visibility(
            visible: widget.elemento['radioboxCleanButtonVisible'] ?? false,
            child: TextButton(
              onPressed: () {
                //widget.formKey.currentState.reset();
                print(
                  widget.formKey.currentState
                      .fields[widget.elemento['fieldName']],
                );
                widget.formKey.currentState.fields[widget.elemento['fieldName']]
                    .didChange('');
              },
              // child: Text('Limpar'),
              child: Column(
                children: [
                  Icon(
                    Icons.cleaning_services_sharp,
                    size: 18,
                    color: radioboxCleanButtonColor,
                  ),
                  Text(
                    'Limpar',
                    style: TextStyle(
                      fontSize: 12,
                      color: radioboxCleanButtonColor,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClasseDinamica {
  final List<Map<dynamic, dynamic>> data;
  ClasseDinamica(this.data);
  factory ClasseDinamica.fromJson(json) {
    assert(json is Map);
    return ClasseDinamica(json['data']);
  }
}

class EcAba extends StatelessWidget {
  final Map<String, dynamic> elemento;
  final vars;
  final formKey;

  const EcAba({
    required this.elemento,
    this.vars,
    this.formKey,
    required this.notifyParent,
  });

  final Function() notifyParent;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> elementosFilhos = elemento.cast()['childrens'];
    //print('filhos aba:');
    //print(elementosFilhos.length);

    return Column(
      children: [
        //Text('ABA'),

        ...elementosFilhos.map(
          (e) => EcComponente(
            elemento: e,
            vars: vars,
            formKey: formKey,
            notifyParent: notifyParent,
          ),
        ),
      ],
    );
  }
}

class EcFieldset extends StatelessWidget {
  final Map<String, dynamic> elemento;
  final vars;
  final formKey;

  final Function() notifyParent;
  const EcFieldset({
    required this.elemento,
    this.vars,
    required this.formKey,
    required this.notifyParent,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> elementosFilhos = elemento.cast()['childrens'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
      child: Column(
        children: [
          Container(
            // color: Colors.amber,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
              child: Text(
                elemento['label'].toString(),
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
          ...elementosFilhos.map(
            (e) => EcComponente(
              elemento: e,
              vars: vars,
              formKey: formKey,
              notifyParent: notifyParent,
            ),
          )
        ],
      ),
    );
  }
}

// eh utilzado para o dropdown com mais de 5 mil itens
class EcModel {
  final String id;
  final String name;

  EcModel({required this.id, required this.name});

  factory EcModel.fromJson(Map<String, dynamic> json) {
    //if (json == null) return null;
    return EcModel(
      id: json['id'],
      name: json['name'],
    );
  }

  static List<EcModel> fromJsonList(List list) {
    //if (list == null) return null;
    return list.map((item) => EcModel.fromJson(item)).toList();
  }

  ///this method will prevent the override of toString
  String userAsString() => '#$id $name';

  ///custom comparing function to check if two users are equal
  bool isEqual(EcModel model) => id == model.id;

  @override
  String toString() => name;
}

class EcSelect extends StatefulWidget {
  final Map<String, dynamic> elemento;
  final vars;
  final formKey;

  final Function() notifyParent;
  final List<bool> isComplementoVisible = [];

  EcSelect(this.elemento, this.vars, this.formKey, this.notifyParent);

  @override
  State<EcSelect> createState() => _EcSelectState();
}

class _EcSelectState extends State<EcSelect> {
  late String opcoesNome;

  @override
  void initState() {
    opcoesNome = widget.elemento['options'];
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => tornaComlementoVisivel());
  }

  tornaComlementoVisivel() {
    if (widget.formKey != null) {
      if (widget.elemento.containsKey('complementos')) {
        widget.elemento['complementos'].asMap().forEach((i, c) {
          if (!widget.isComplementoVisible.contains(i)) {
            widget.isComplementoVisible.add(true);
          }

          if (widget.formKey.currentState
                      .fields[widget.elemento['fieldName'].toString()] !=
                  null &&
              c['opcoes'].indexOf(
                    widget.formKey.currentState
                        .fields[widget.elemento['fieldName'].toString()].value
                        .toString(),
                  ) >=
                  0) {
            widget.isComplementoVisible[i] = true;
          } else {
            widget.isComplementoVisible[i] = false;
          }
        });
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // print(vars);
    // print('formKey no select: ' + widget.formKey.hashCode.toString());

    tornaComlementoVisivel();

    final complementos = [];
    if (widget.elemento.containsKey('complementos')) {
      widget.elemento['complementos'].asMap().forEach(
        (i, c) {
          complementos.add(
            Visibility(
              maintainState: true,
              visible: widget.isComplementoVisible[i],
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: EcComponente(
                  elemento: widget.elemento['complementos'][i]['elemento'],
                  vars: widget.vars,
                  formKey: widget.formKey,
                  notifyParent: widget.notifyParent,
                ),
              ),
            ),
          );
        },
      );
    }

    if (!widget.vars.containsKey(widget.elemento['options'])) {
      return Text(
        'BUG: Não tem ou está zerado o vars de ${widget.elemento['options']}',
      );
    }

    var errMsg = '';
    var required = false;
    if (widget.elemento.containsKey('validations')) {
      if (widget.elemento['validations']!.any((i) => i['type'] == 'required')) {
        required = true;
        final r = widget.elemento['validations']!
            .firstWhere((i) => i['type'] == 'required');
        errMsg = r['message'];
      }
    }

    // var _lista = [
    //   EcModel(id: "1", name: "Brazil"),
    //   EcModel(id: "2", name: "ASDFASDF"),
    //   EcModel(id: "3", name: "ssssss"),
    // ];

    final List<EcModel> lista2 = [];

    widget.vars[widget.elemento['options'].toString()].forEach((k, v) {
      lista2.add(EcModel(id: k, name: v));
    });

    // _lista2.sort((a, b) {
    //   return a.name
    //       .toString()
    //       .toLowerCase()
    //       .compareTo(b.name.toString().toLowerCase());
    // });
    //isso faz a ordem alfabetica caso queiramos

    if (widget.vars[widget.elemento['options'].toString()].length > 5) {
      EcModel? selectedItem;

      if (widget.formKey.currentState.fields[widget.elemento['fieldName']] !=
          null) {
        final idJahSalvo = widget.formKey.currentState
            .fields[widget.elemento['fieldName'].toString()].value;
        selectedItem =
            lista2.firstWhereOrNull((element) => element.id == idJahSalvo);
      }

      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 06),

        // child: FormBuilderTypeAhead<String>(
        //   decoration: _criaInputDecoration(widget.elemento),
        //   name: widget.elemento['fieldName'],
        //   itemBuilder: (context, continent) {
        //     return ListTile(title: Text(continent));
        //   },
        //   suggestionsCallback: (query) {
        //     if (query.isNotEmpty) {
        //       var lowercaseQuery = query.toLowerCase();
        //       return ['a', 'b', 'c', 'd'].where((continent) {
        //         return continent.toLowerCase().contains(lowercaseQuery);
        //       }).toList(growable: false)
        //         ..sort((a, b) =>
        //             a.toLowerCase().indexOf(lowercaseQuery).compareTo(b.toLowerCase().indexOf(lowercaseQuery)));
        //     } else {
        //       return ['a', 'b', 'c', 'd'];
        //     }
        //   },
        // ),

        child: Column(
          children: [
            Visibility(
              visible: false,
              maintainState: true,
              child: FormBuilderTextField(
                name: widget.elemento['fieldName'].toString(),
                readOnly: true,
                onChanged: (val) {
                  debugPrint('val no onchanged do select1: $val');

                  if (widget.elemento.containsKey('complementos')) {
                    widget.elemento['complementos'].asMap().forEach((i, c) {
                      if (c['opcoes'].indexOf(val.toString()) >= 0) {
                        widget.isComplementoVisible[i] = true;
                      } else {
                        widget.isComplementoVisible[i] = false;
                        //quando seleciona outra coisa precisa zerar esse campo
                        widget.formKey.currentState
                            .fields[c['elemento']['fieldName'].toString()]
                            .didChange('');
                      }
                    });
                    // setState(() {});
                  }
                  widget.notifyParent();
                },
              ),
            ),
            DropdownSearch<EcModel>(
              // showClearButton: true,
              dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration:
                      _criaInputDecoration(widget.elemento)),
              //dropdownSearchDecoration: _criaInputDecoration(widget.elemento),
              //focusNode: FocusNode(descendantsAreFocusable: true),
              selectedItem: selectedItem,
              popupProps: PopupProps.dialog(
                showSearchBox: true,
                showSelectedItems: true,
                searchDelay: const Duration(),
                // errorBuilder: (_, __, ___) => Text('nada encontrado'),
                emptyBuilder: (_, __) =>
                    const Center(child: Text('sem opçõe encontrada')),
                title: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      widget.elemento['label'].toString(),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                searchFieldProps: const TextFieldProps(autofocus: true),
                // disabledItemFn: (EcModel s) => s.name.startsWith('XXXB'),
              ),
              compareFn: (i1, i2) => i1.name == i2.name,

              validator: required
                  ? FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: errMsg),
                    ])
                  : null,
              // items: vars[elemento['options'].toString()].entries.toList(),
              items: lista2,
              itemAsString: (EcModel? u) => u!.name.toString(),

              onChanged: (val) {
                // print(val!.id.toString());
                // print(val!.name.toString());
                widget.formKey.currentState
                    .fields[widget.elemento['fieldName'].toString()]
                    .didChange(val!.id.toString());
              },
              // selectedItem: EcModel(id: "4429", name: "Brazil"),
            ),
            if (widget.elemento.containsKey('complementos')) ...complementos,
          ],
        ),
      );
    } else if (widget.vars[widget.elemento['options'].toString()].length > 4) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Column(
          children: [
            FormBuilderDropdown<String>(
              name: widget.elemento['fieldName'].toString(),
              validator: required
                  ? FormBuilderValidators.compose(
                      [FormBuilderValidators.required(errorText: errMsg)],
                    )
                  : null,
              decoration: _criaInputDecoration(widget.elemento),
              items: itensParaDropdown(widget.vars[opcoesNome]),
              onChanged: (val) {
                debugPrint('val no onchanged do select: $val');
                if (widget.elemento.containsKey('complementos')) {
                  widget.elemento['complementos'].asMap().forEach((i, c) {
                    if (c['opcoes'].indexOf(val.toString()) >= 0) {
                      widget.isComplementoVisible[i] = true;
                    } else {
                      widget.isComplementoVisible[i] = false;
                      //quando seleciona outra coisa precisa zerar esse campo
                      widget.formKey.currentState
                          .fields[c['elemento']['fieldName'].toString()]
                          .didChange('');
                    }
                  });
                  // setState(() {});
                  widget.notifyParent();
                }
              },
            ),
            if (widget.elemento.containsKey('complementos')) ...complementos,
          ],
        ),
      );
    } else {
      return EcRadiobox(
        elemento: widget.elemento,
        vars: widget.vars,
        formKey: widget.formKey,
        notifyParent: widget.notifyParent,
      );
    }
  }
}

class EcCheckbox extends StatefulWidget {
  final Map<String, dynamic> elemento;
  final vars;
  final formKey;

  final List<bool> isComplementoVisible = [];
  final Function() notifyParent;

  EcCheckbox({
    required this.elemento,
    this.vars,
    required this.formKey,
    required this.notifyParent,
  });

  @override
  _EcCheckboxState createState() => _EcCheckboxState();
}

class _EcCheckboxState extends State<EcCheckbox> {
  @override
  void initState() {
    //tornaComlementoVisivel();
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => tornaComlementoVisivel());
  }

  //isso aqui roda sempre quando terminar de fazer o build (aí já vai ter criado o campo de complemento)
  tornaComlementoVisivel() {
    try {
      if (widget.formKey != null) {
        if (widget.elemento.containsKey('complementos')) {
          widget.elemento['complementos'].asMap().forEach((i, c) {
            if (!widget.isComplementoVisible.contains(i)) {
              widget.isComplementoVisible.add(false);
            }

            if (widget.formKey.currentState
                    .fields[widget.elemento['fieldName'].toString()] !=
                null) {
              if (widget
                  .formKey
                  .currentState
                  .fields[widget.elemento['fieldName'].toString()]
                  .value is List) {
                // debugPrint('eh uma lista vinda do checkbox');

                widget.formKey.currentState
                    .fields[widget.elemento['fieldName'].toString()].value
                    .forEach((v) {
                  if (c['opcoes'].indexOf(v.toString()) >= 0) {
                    widget.isComplementoVisible[i] = true;
                  }
                });
              }
            } else {
              widget.isComplementoVisible[i] = false;
            }
          });
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Erro relacionado ao complemento do ckeckbox. Contate suporte.',
          ),
          padding: const EdgeInsets.all(10),
          backgroundColor: Colors.red[900],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // debugPrint('build do checkbox ${widget.elemento['fieldName']}');

    tornaComlementoVisivel();

    final complementos = [];
    if (widget.elemento.containsKey('complementos')) {
      widget.elemento['complementos'].asMap().forEach(
        (i, c) {
          complementos.add(
            Visibility(
              maintainState: true,
              visible: widget.isComplementoVisible[i],
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: EcComponente(
                  elemento: widget.elemento['complementos'][i]['elemento'],
                  vars: widget.vars,
                  formKey: widget.formKey,
                  notifyParent: widget.notifyParent,
                ),
              ),
            ),
          );
        },
      );
    }

    return Padding(
      //padding: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: Column(
        children: [
          FormBuilderCheckboxGroup(
            key: UniqueKey(),
            decoration: _criaInputDecoration(widget.elemento),
            name: widget.elemento['fieldName'].toString(),
            //initialValue: ["98", "135"],
            options: itensParaRadio(
              widget.vars[widget.elemento['options'].toString()],
            ),
            onChanged: (val) {
              debugPrint('val no onchanged do checkbox: $val');
              if (widget.elemento.containsKey('complementos')) {
                widget.elemento['complementos'].asMap().forEach((i, c) {
                  if (val is List) {
                    for (final v in val) {
                      if (c['opcoes'].indexOf(v.toString()) >= 0) {
                        widget.isComplementoVisible[i] = true;
                      } else {
                        print('entrou aqui');
                        widget.isComplementoVisible[i] = false;
                      }
                    }
                  } else {
                    widget.isComplementoVisible[i] = false;
                  }
                });
                // setState(() {});
              }

              //TODO: continuar, eh para apagar o conteúdo do textfield quando a opção for des-selecionada
              // if (widget.elemento.containsKey('complementos')) {
              //   widget.elemento['complementos'].asMap().forEach((i, c) {
              //     if (widget.isComplementoVisible[i] == true) {
              //       //se o iscomplemento de i tava true, e vai pra false limpa
              //       if (val is List)
              //         val.forEach((v) {

              //           if (c['opcoes'].indexOf(v.toString()) >= 0) {
              //             widget.isComplementoVisible[i] = true;
              //           } else {
              //             print('entrou aqui');
              //             widget.isComplementoVisible[i] = false;
              //             if (widget.formKey.currentState.fields[c['elemento']['fieldName'].toString()] != null)
              //               widget.formKey.currentState.fields[c['elemento']['fieldName'].toString()].didChange("");
              //           }
              //         });
              //     }
              //   });
              // }

              widget.notifyParent();
            },
          ),
          if (widget.elemento.containsKey('complementos')) ...complementos,
        ],
      ),
    );
  }
}

class EcTextField extends StatefulWidget {
  final Map<String, dynamic> elemento;
  final vars;
  final formKey;

  final bool isComplementoVisible = false;

  const EcTextField(this.elemento, this.vars, this.formKey);

  @override
  State<EcTextField> createState() => _EcTextFieldState();
}

class _EcTextFieldState extends State<EcTextField> {
  String errMsg = '';
  bool required = false;
  bool validation = false;
  String validationFunction = '';
  String validationErrMsg = '';

  @override
  Widget build(BuildContext context) {
    if (widget.elemento.containsKey('validations')) {
      if (widget.elemento['validations']!.any((i) => i['type'] == 'function')) {
        validation = true;
        final x = widget.elemento['validations']!
            .firstWhere((i) => i['type'] == 'function');
        validationFunction = x['function'];
        validationErrMsg = x['message'];
      }
    }

    dynamic mask;
    if (widget.elemento.containsKey('mask')) {
      mask = widget.elemento['mask'];
      //tem um Bug na biblioteca de mascara que soh pegava lista de string e não dynamic, então resolvi aqui mesmo
      if (mask is List) mask = List<String>.from(mask);

      // mask = ['(99) 9999-9999', '(99) 99999-9999'];
      // mask = ['999-999', '99-99'];
      // print('tem mascara: ' + mask.runtimeType.toString());
      // print(mask);
    } else {
      mask = 'X*';
    }

    final validators = [];

    String msgErrData = 'insira uma válida (use o padrão 01/12/2022)';

    if (widget.elemento.containsKey('validations')) {
      validation = true;
      widget.elemento['validations'].forEach((validator) {
        final String errPadrao = "${validator['type'].toString()} com problema";

        switch (validator['type'].toString()) {
          case 'required':
            validators.add(
              FormBuilderValidators.required(
                errorText: validator['message'].toString(),
              ),
            );
            break;

          case 'creditCard':
            validators.add(
              FormBuilderValidators.creditCard(
                errorText: validator['message'] ?? errPadrao,
              ),
            );
            break;
          case 'date':
            widget.elemento['type'] = 'DateField';
            msgErrData = validator['message'] ?? msgErrData;
            break;
          case 'email':
            validators.add(
              FormBuilderValidators.email(
                errorText: validator['message'] ?? errPadrao,
              ),
            );
            break;
          case 'integer':
            validators.add(
              FormBuilderValidators.integer(
                errorText: validator['message'] ?? errPadrao,
              ),
            );
            break;
          case 'ip':
            validators.add(
              FormBuilderValidators.ip(
                errorText: validator['message'] ?? errPadrao,
              ),
            );
            break;
          case 'match':
          // TODO: continuar
          // validators.add(FormBuilderValidators.match(
          //   'r' + validator['param'].toString(),
          //   errorText: validator['message'] ?? errPadrao,
          // ));
          // break;
          case 'maxLength':
            validators.add(
              FormBuilderValidators.maxLength(
                int.tryParse(validator['param'].toString()) ?? 100,
                errorText: validator['message'] ?? errPadrao,
              ),
            );
            break;
          case 'minLength':
            validators.add(
              FormBuilderValidators.minLength(
                int.tryParse(validator['param'].toString()) ?? 0,
                errorText: validator['message'] ?? errPadrao,
              ),
            );
            break;
          case 'max':
            validators.add(
              FormBuilderValidators.max(
                int.tryParse(validator['param'].toString()) ?? 0,
                errorText: validator['message'] ?? errPadrao,
              ),
            );
            break;
          case 'min':
            validators.add(
              FormBuilderValidators.min(
                int.tryParse(validator['param'].toString()) ?? 0,
                errorText: validator['message'] ?? errPadrao,
              ),
            );
            break;
          //TODO: consertar para ser numeric com , inves de ponto
          case 'numeric':
            validators.add(
              FormBuilderValidators.numeric(
                errorText: validator['message'] ?? errPadrao,
              ),
            );
            break;
          case 'url':
            validators.add(
              FormBuilderValidators.url(
                errorText: validator['message'] ?? errPadrao,
              ),
            );
            break;

          default:
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      child: FormBuilderTextField(
        name: widget.elemento['fieldName'].toString(),
        //enabled: false,
        //initialValue: elemento['defaultValue'].toString(),
        keyboardType: (widget.elemento['type'] == 'IntField' ||
                widget.elemento['type'] == 'FloatField' ||
                widget.elemento['type'] == 'NumField' ||
                widget.elemento['type'] == 'MoneyField')
            ? TextInputType.number
            : null,
        inputFormatters: (widget.elemento['maskReverse'] == '1')
            ? [TextInputMask(mask: mask, reverse: true)]
            : [TextInputMask(mask: mask)],
        decoration: _criaInputDecoration(widget.elemento),
        validator: FormBuilderValidators.compose(
          [
            ...validators,
            (val) {
              print('val$val');
              if (val != null && val.isNotEmpty) {
                if (widget.elemento['type'] == 'DateField') {
                  final partes = val.toString().split('/');
                  if (partes.length == 3) {
                    final dia = int.tryParse(partes[0]) ?? 0;
                    final mes = int.tryParse(partes[1]) ?? 0;
                    //var ano = int.tryParse(partes[2]) ?? 0;
                    if (dia >= 1 && dia <= 31) if (mes >= 1 && mes <= 12) {
                      if (partes[2].length == 4) return null;
                    }
                  }
                  return msgErrData;
                }
              }

              if (validation && (val != null && val != '')) {
                //se tem validação, só faz a validação caso o campo tenha sido preenchido
                switch (validationFunction) {
                  case 'cpf_cnpj':
                    if (!CpfValidator.isValid(val.toString()) &&
                        !CNPJValidator.isValid(val.toString())) {
                      return validationErrMsg;
                    }
                    break;
                  case 'cpf':
                    if (!CpfValidator.isValid(val.toString())) {
                      return validationErrMsg;
                    }
                    break;
                  case 'cnpj':
                    if (!CNPJValidator.isValid(val.toString())) {
                      return validationErrMsg;
                    }
                    break;
                  case 'email':
                    if (!RegExp(
                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                    ).hasMatch(val.toString())) return validationErrMsg;
                    break;

                  default:
                    return null; //ajustado em 17/02/2022
                }
              }
              return null;
            }
          ],
        ),
      ),
    );
  }
}

class EcTextArea extends StatelessWidget {
  final Map<String, dynamic> elemento;
  const EcTextArea(this.elemento);

  @override
  Widget build(BuildContext context) {
    var errMsg = '';
    var required = false;
    if (elemento.containsKey('validations')) {
      if (elemento['validations']!.any((i) => i['type'] == 'required')) {
        required = true;
        final r =
            elemento['validations']!.firstWhere((i) => i['type'] == 'required');
        errMsg = r['message'];
      }
    }

    return SizedBox(
      width: double.infinity,
      child: FormBuilderTextField(
        // expands: true,
        minLines: 1,
        maxLines: 5,
        decoration: _criaInputDecoration(elemento),
        name: elemento['fieldName'].toString(),

        validator: FormBuilderValidators.compose(
          [
            if (required) FormBuilderValidators.required(errorText: errMsg),
          ],
        ),
      ),
    );
  }
}

// TODO: esse aqui valeria apena avaliar e fazer.
// class EcUpload extends StatelessWidget {
//   final Map<String, dynamic> elemento;
//   EcUpload({required this.elemento});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       // color: Colors.grey[100],
//       width: double.infinity,
//       //height: 15,
//       //child: Text('textarea ' + elemento['fieldName'].toString()),
//       child: Column(
//         children: [
//           Text(elemento['label'].toString()),
//           FormBuilderImagePicker(
//             name: elemento['fieldName'].toString(),
//             decoration: const InputDecoration(
//               labelText: 'Selecionar Imagens',
//             ),
//             maxImages: 3,
//             // valueTransformer: (value) {
//             //   var x = 1;

//             //   return jsonEncode(value.toString());
//             // },
//             // onChanged: (text) {
//             //   text!.forEach((element) {
//             //     File file = new File(element.path.toString());
//             //     var x = 1;
//             //     // storage
//             //     //     .uploadImage(
//             //     //         context: context,
//             //     //         imageToUpload: file,
//             //     //         title: basename(file.path.toString()),
//             //     //         requestId: database.currentRequest.id)
//             //     //     .then((value) {
//             //     //   setState(() {
//             //     //     //ERROR HERE
//             //     //     _imageList.add(value.imageUrl);
//             //     //   });
//             //     // });
//             //   });
//             // },
//           ),
//         ],
//       ),
//     );
//   }
// }

class EcGps extends StatefulWidget {
  final Map<String, dynamic> elemento;
  final formKey;
  const EcGps({required this.elemento, required this.formKey});

  @override
  _EcGpsState createState() => _EcGpsState();
}

class _EcGpsState extends State<EcGps> {
  String? latlong;

  Future<void> salvarPosicaoGps(double lat, double long) async {
    print('aqui salvarPosicaoGps do EC GPS: $lat,$long');
    setState(() {
      latlong = '$lat,$long';
    });

    widget.formKey.currentState.fields[widget.elemento['fieldName'].toString()]
        .didChange(latlong);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // print(widget.elemento);

    if (widget.formKey.currentState
            .fields[widget.elemento['fieldName'].toString()] !=
        null) {
      latlong = widget.formKey.currentState
          .fields[widget.elemento['fieldName'].toString()].value;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: Container(
        // color: Colors.grey[200],
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: const BorderRadius.all(Radius.circular(7)),
        ),

        // height: 150,
        //height: 15,
        //child: Text('textarea ' + elemento['fieldName'].toString()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.elemento['label'].toString(),
              style: const TextStyle(fontSize: 16),
            ),
            Center(
              child: (latlong != null && latlong!.isNotEmpty)
                  ? const Text(
                      'Existe ponto definido.',
                      style: TextStyle(fontSize: 16),
                    )
                  : const Text(
                      'Ponto não definido.',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            Visibility(
              visible: false,
              maintainState: true,
              child: FormBuilderTextField(
                //readOnly: true,
                decoration: _criaInputDecoration(widget.elemento),
                name: widget.elemento['fieldName'].toString(),
                valueTransformer: (String? v) => v =
                    (latlong != null && latlong!.length > 1)
                        ? latlong as dynamic
                        : v as dynamic,
              ),
            ),
            if (latlong != null && latlong!.length > 1)
              Container(
                child: Center(
                  child: Text('(GPS: $latlong)'),
                ),
              ),
            EcOnline(
              child: Center(
                child: IconButton(
                  onPressed: () {
                    print('aasdfasdfasdf');

                    final coord = widget.formKey.currentState
                        .fields[widget.elemento['fieldName'].toString()].value
                        .toString()
                        .split(',');

                    final LatLng? gpsInicial = (coord.length == 2)
                        ? LatLng(
                            double.parse(coord[0].toString()),
                            double.parse(coord[1].toString()),
                          )
                        : null;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return EcGpsPage(
                            title: widget.elemento['label'].toString(),
                            salvarPosicaoGps: salvarPosicaoGps,
                            gpsInicial: gpsInicial,
                            icone_item_no_mapa:
                                widget.elemento['icone_item_no_mapa'] ??
                                    '0xe4c7',
                            online: true,
                          );
                          //TODO: pegar o icone do do item no mapa do headers e não do element do form
                        },
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.gps_fixed,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            EcOffline(
              child: Center(
                child: IconButton(
                  onPressed: () {
                    final coord = widget.formKey.currentState
                        .fields[widget.elemento['fieldName'].toString()].value
                        .toString()
                        .split(',');

                    final LatLng? gpsInicial = (coord.length == 2)
                        ? LatLng(
                            double.parse(coord[0].toString()),
                            double.parse(coord[1].toString()),
                          )
                        : null;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EcGpsPage(
                          title: widget.elemento['label'].toString(),
                          salvarPosicaoGps: salvarPosicaoGps,
                          gpsInicial: gpsInicial,
                          icone_item_no_mapa:
                              widget.elemento['icone_item_no_mapa'] ?? '0xe4c7',
                          online: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.gps_fixed,
                    color: Colors.red,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class EcGeoms extends StatefulWidget {
  final Map<String, dynamic> elemento;
  final formKey;
  const EcGeoms({required this.elemento, required this.formKey});

  @override
  _EcGeomsState createState() => _EcGeomsState();
}

class _EcGeomsState extends State<EcGeoms> {
  String? geomStr;

  Future<void> salvarGeom(var geom) async {
    print('aqui salvarGeom:');
    print(geom);

    setState(() {
      //latlong = '$lat, $long';
      widget
          .formKey.currentState.fields[widget.elemento['fieldName'].toString()]
          .didChange(jsonEncode(geom));
      geomStr = jsonEncode(geom);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // print(widget.elemento);

    if (widget.formKey.currentState
            .fields[widget.elemento['fieldName'].toString()] !=
        null) {
      geomStr = widget.formKey.currentState
          .fields[widget.elemento['fieldName'].toString()].value;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: const BorderRadius.all(Radius.circular(7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.elemento['label'].toString(),
            style: const TextStyle(fontSize: 16),
          ),
          Center(
            child: (geomStr != null && geomStr!.length > 1)
                ? Text(
                    'Existe polígono com ${jsonDecode(geomStr.toString()).length} pontos.',
                    style: const TextStyle(fontSize: 16),
                  )
                : const Text(
                    'Polígono não definido.',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          Visibility(
            visible: false,
            maintainState: true,
            child: FormBuilderTextField(
              //readOnly: true,
              decoration: _criaInputDecoration(widget.elemento),
              name: widget.elemento['fieldName'].toString(),
              valueTransformer: (String? v) => v =
                  (geomStr != null && geomStr!.length > 1)
                      ? geomStr as dynamic
                      : v as dynamic,
            ),
          ),
          EcOnline(
            child: Center(
              child: IconButton(
                onPressed: () {
                  print('criando icone para pegar geom estando online');

                  final geomatual = widget.formKey.currentState
                      .fields[widget.elemento['fieldName'].toString()].value
                      .toString();

                  final geomInicial = jsonDecode(geomatual);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return EcGpsPage(
                          title: widget.elemento['label'].toString(),
                          salvarGeom: salvarGeom,
                          geomInicial: geomInicial,
                          icone_item_no_mapa:
                              widget.elemento['icone_item_no_mapa'] ?? '0xe4c7',
                          online: true,
                          tipo: 'poligono',
                        );
                        //TODO: pegar o icone do do item no mapa do headers e não do element do form
                      },
                    ),
                  ).then((value) {
                    print('passou aqui');
                    setState(() {});
                  });
                },
                icon: const Icon(
                  Icons.polyline_outlined,
                  color: Colors.green,
                ),
              ),
            ),
          ),
          EcOffline(
            child: Center(
              child: IconButton(
                onPressed: () {
                  final geomatual = widget.formKey.currentState
                      .fields[widget.elemento['fieldName'].toString()].value
                      .toString();

                  final geomInicial = jsonDecode(geomatual);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EcGpsPage(
                        title: widget.elemento['label'].toString(),
                        salvarGeom: salvarGeom,
                        geomInicial: geomInicial,
                        icone_item_no_mapa:
                            widget.elemento['icone_item_no_mapa'],
                        online: false,
                        tipo: 'poligono',
                      ),
                    ),
                  ).then((value) {
                    setState(() {});
                  });
                },
                icon: const Icon(
                  Icons.polyline_outlined,
                  color: Colors.red,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// class EcDate extends StatelessWidget {
//   final Map<String, dynamic> elemento;
//   EcDate(this.elemento);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: FormBuilderTextField(
//             name: elemento['fieldName'].toString(),
//             //initialValue: elemento['value'].toString(),
//             decoration:
//                 InputDecoration(labelText: elemento['label'].toString()),
//             readOnly: true,
//           ),
//         ),
//         Container(
//           width: 50,
//           child: TextButton(
//               onPressed: () {
//                 DatePicker.showDatePicker(context,
//                     showTitleActions: true,
//                     minTime: DateTime(2010, 3, 5),
//                     maxTime: DateTime(2019, 6, 7), onChanged: (date) {
//                   print('change $date');
//                 }, onConfirm: (date) {
//                   print('confirm $date');
//                 }, currentTime: DateTime.now(), locale: LocaleType.pt);
//               },
//               child: Icon(Icons.calendar_month)),
//         ),
//       ],
//     );
//   }
// }

class EcDate3 extends StatelessWidget {
  final Map<String, dynamic> elemento;
  const EcDate3(this.elemento);

  @override
  Widget build(BuildContext context) => FormBuilderDateTimePicker(
        locale: const Locale('pt'),
        onChanged: (d) {
          print('d no date${elemento['fieldName']}');
          print(d);
          // [elemento['fieldName'].toString()] = 'asdf';
          //didChange(DateTime.parse("2021-06-18 00:00:00.000"));

//TODO: ajustar data para poder salvar
        },
        //initialValue: DateTime.tryParse("1982-01-15"),

        name: elemento['fieldName'].toString(),
        // format: DateFormat("dd/MM/y"),
        // onChanged: _onChanged,
        inputType: InputType.date,
        decoration: _criaInputDecoration(elemento),
        // valueTransformer: (v) => 2,
        //initialTime: TimeOfDay(hour: 8, minute: 0),
        // initialValue: DateTime.now(),
      );
}

InputDecoration _criaInputDecoration(elemento) {
  bool required = false;
  if (elemento.containsKey('validations')) {
    if (elemento['validations']!.any((i) => i['type'] == 'required')) {
      required = true;
      // var r =
      //     elemento['validations']!.firstWhere((i) => i['type'] == "required");
    }
  }

  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    // borderSide: BorderSide(color: Colors.black, width: 1.5),
  );

  // elemento['prefixIcon'] = "person";
  // elemento['suffixIcon'] = "zoom_in";
  // elemento['icon'] = "0xf435"; //0xf439
  // elemento['fillColor'] = "0xffb74093";
  // elemento['fillColor'] = "0xffc7c0c3";

  int fillColor = 0x00FFFFFF;
  if (elemento.containsKey('fillColor')) {
    try {
      fillColor = int.parse(elemento['fillColor'].toString());
    } catch (e) {
      fillColor = 0x00FFFFFF;
    }
  }

  if (elemento.containsKey('after')) elemento['helperText'] = elemento['after'];

  final int labelTextSize = elemento['labelTextSize'] ?? 17;
  final Color labelTextColor =
      geraColor(cor: elemento['labelTextColor']) ?? Colors.black;

  return InputDecoration(
    fillColor: Color(fillColor),
    filled: true,
    prefixIcon: elemento.containsKey('prefixIcon')
        ? EcIcon(elemento['prefixIcon'])
        : null,
    suffixIcon: elemento.containsKey('suffixIcon')
        ? EcIcon(elemento['suffixIcon'])
        : null,
    hintText: elemento['hintText'],
    icon: elemento.containsKey('icon') ? EcIcon(elemento['icon']) : null,
    border: border,
    hintMaxLines: 3,
    label: Text(
      elemento['label'].toString(),
      style: TextStyle(
        fontSize: double.parse(labelTextSize.toString()),
        color: labelTextColor,
      ),
    ),
    labelStyle: required
        ? const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          )
        : const TextStyle(
            fontSize: 18,
          ),
    helperText: elemento['helperText'],
    helperMaxLines: 3,
  );
}

List<DropdownMenuItem<String>> itensParaDropdown(Map<String, dynamic> items) =>
    items.entries
        .map(
          (e) => DropdownMenuItem<String>(
            value: e.key,
            child: Text(e.value.toString()),
          ),
        )
        .toList();

List<FormBuilderFieldOption> itensParaRadio(itens) {
  final List<FormBuilderFieldOption> opcoes = [];
  for (final i in itens.entries) {
    opcoes.add(
      FormBuilderFieldOption(
        value: i.key,
        child: Text(i.value),
      ),
    );
  }
  return opcoes;
}
