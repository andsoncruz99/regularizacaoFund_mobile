import 'dart:async';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../../shared/usuario_controller.dart';
import '../anexos/ec_images.dart';
import '../formularios/formulario_page.dart';
// import 'package:sishabi/src/features/gps_baixar_cache_page.dart';

class ListagemItem extends StatelessWidget {
  const ListagemItem({
    super.key,
    required this.item,
    required this.doque,
    this.abasDisponiveis,
    required this.salvar,
    required this.atualizar,
    required this.deletar,
    required this.subir,
    required this.varsConfigs,
    required this.salvarPosicaoGps,
  });

  final item;
  final doque;
  final Map<String, dynamic>? abasDisponiveis;
  final varsConfigs;
  final Function atualizar;
  final Future Function(dynamic p1) deletar;
  final Future<dynamic> Function(BuildContext ctx, dynamic p1) subir;
  final Future Function(double lat, double long) salvarPosicaoGps;
  final dynamic salvar;
  // final Future<Map<String, dynamic>> Function(Map<String, dynamic> r) salvar;

  Widget _buildPopupMenu(BuildContext context) => PopupMenuButton(
        itemBuilder: (context) {
          //TODO: talvez não mostrar a primeira aba, senão aparece 2 vezes...editar e tbm na aba
          return abasDisponiveis!.entries
              .map(
                (e) => PopupMenuItem(
                  value: e.key,
                  child: Text(e.value),
                ),
              )
              .toList();
        },
        onSelected: (String value) async {
          print('You Click on po up menu item $value');
          switch (value) {
            case 'fotos':
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EcImages(
                    doque: doque,
                    id: item.id,
                    dados: item.dados,
                    usarAppBar: true,
                  ),
                ),
              ).whenComplete(() {
                print('whencomplete');
                atualizar();
              });
              break;

            case 'subir':
              if (!item.sincronizado) {
                await subir(context, item.id);
              } else {
                await EasyLoading.showError('Item já está sincronizado.');
              }
              break;

            case 'edit':
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    print('item');
                    print(item);
                    return FormularioPage(
                      id: item.id,
                      salvar: salvar,
                      primaryKey: varsConfigs[doque]['primaryKey'],
                      doque: doque,
                      dados: item.dados,
                      atualizarListagem: atualizar,
                    );
                  },
                ),
              ).whenComplete(() => atualizar);
              break;
            case 'delete':
              await confirmaDeletar(context, item.id);
              break;

            default:
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormularioPage(
                    id: item.id,
                    primaryKey: varsConfigs[doque]['primaryKey'],
                    salvar: salvar,
                    doque: doque,
                    dados: item.dados,
                    atualizarListagem: atualizar,
                    aba: value,
                  ),
                ),
              ).whenComplete(() => atualizar());
          }
        },
      );

  @override
  Widget build(BuildContext context) {
//TODO: quem sabe transofrmar em statefull para poder mostrar/sumir dinamica essa opção
    final usuarioController = Provider.of<UsuarioController>(context);
    if (usuarioController.isNetworkDisponible) {
      abasDisponiveis!.putIfAbsent('subir', () => 'Subir para OnLine');
    }

    abasDisponiveis!.putIfAbsent('edit', () => 'Editar');
    abasDisponiveis!.putIfAbsent('delete', () => 'Deletar');

    return SizedBox(
      width: double.infinity,
      // color: item.sincronizado ? Colors.white : Colors.red[600],
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          // _showPopupMenu(details.globalPosition);
          _buildPopupMenu(context);
        },
        child: Card(
          color: item.sincronizado ? Colors.white : Colors.red[100],
          child: ListTile(
            // isThreeLine: true,
            trailing: _buildPopupMenu(context),
            onLongPress: () async {
              if (!item.sincronizado) await subir(context, item.id);
            },
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormularioPage(
                    id: item.id,
                    primaryKey: varsConfigs[doque]['primaryKey'],
                    salvar: salvar,
                    doque: doque,
                    dados: item.dados,
                    atualizarListagem: atualizar,
                  ),
                ),
              ).whenComplete(() {
                print('whencomplete');
                atualizar();
              });
            },

            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // 'id : ' + item.id.toString() + ' ' + item.title,
                  item.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('${item.subtitle1}'),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                (item.subtitle3.length > 0)
                    ? Text(item.subtitle2 + ' / ' + item.subtitle3)
                    : Text(item.subtitle2),
                Text(item.subtitle4),
                // Text('ID Local ${item.id}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> confirmaDeletar(BuildContext context, id) async {
    if (await confirm(
      context,
      title: const Text('Tem certeza que deseja excluir?'),
      content: const Text(
        'Clicando em sim esse cadastro já era, não há como reverter. Mas é somente excluído deste dispositivo.',
      ),
      textOK: const Text('Sim'),
      textCancel: const Text('Cancelar'),
    )) {
      await EasyLoading.show(status: 'Apagando...');
      await deletar(id);
      await EasyLoading.showSuccess('Apagado com sucesso!');

      atualizar();
    } else {
      return print('pressedCancel');
    }
  }
}
