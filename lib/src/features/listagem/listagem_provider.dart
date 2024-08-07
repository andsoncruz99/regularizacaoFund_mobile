// import 'package:sishabi/src/features/listagem/listagem_item.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class RegistroListagem {
  late int id;
  late String primaryKey; //geralmente cpf
  late String primaryKeyQuente;
  late String temporarioIdQuente;
  late String title; //geralmente cpf
  late String? subtitle1; // nome por exemplo
  late String? subtitle2; //nome conjuge por exemplo
  late String? subtitle3; // cpf conjuge por exemplo
  late String? subtitle4; // algum adicional
  late String dados; // json dos dados por exemplo
  late bool sincronizado; //

  RegistroListagem({
    this.id = 0,
    required this.primaryKey,
    this.primaryKeyQuente = '',
    this.temporarioIdQuente = '',
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    required this.subtitle3,
    required this.subtitle4,
    required this.dados,
    required this.sincronizado,
  });

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'primaryKey': primaryKey,
      'primaryKeyQuente': primaryKeyQuente,
      'temporarioIdQuente': temporarioIdQuente,
      'title': title,
      'subtitle1': subtitle1,
      'subtitle2': subtitle2,
      'subtitle3': subtitle3,
      'subtitle4': subtitle4,
      'dados': dados,
      'sincronizado': sincronizado == true ? 1 : 0
    };
    return map;
  }

  RegistroListagem.fromMap(Map<String, Object?> map) {
    // print('frommap');
    // print(map);
    id = int.parse(map['id'].toString());
    primaryKey = map['primaryKey'].toString();
    primaryKeyQuente = map['primaryKeyQuente'].toString();
    temporarioIdQuente = map['temporarioIdQuente'].toString();
    title = map['title'].toString();
    subtitle1 = map['subtitle1'].toString();
    subtitle2 = map['subtitle2'].toString();
    subtitle3 = map['subtitle3'].toString();
    subtitle4 = map['subtitle4'].toString();
    dados = map['dados'].toString();
    sincronizado = int.parse(map['sincronizado'].toString()) ==
        1; //sqflite não suporta bool...
  }
}

//Para cada tipo de listagem é criado um database com apenas uma tabela
class ListagemProvider {
  late Database db;
  final String tipo;
  late String tabela;
  late Batch batch;
  bool isOpen = false;

  ListagemProvider({required this.tipo}) {
    tabela = 'listagem_$tipo';
  }

  Future dropDatabase() async {
    // Delete the database
    print('dropdatabase');
    final databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, '$tabela.db');
    await deleteDatabase(path);
  }

  Future open() async {
    //if (!isOpen) {
    // Get a location using getDatabasesPath
    final databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, '$tabela.db');

    // }
//TODO: talvez criar databases ou tabelas diferentes para cada dominio/host
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        //UNIQUE
        await db.execute(
          '''
create table $tabela ( 
  id integer primary key autoincrement, 
  primaryKey text UNIQUE,
  primaryKeyQuente text,
  temporarioIdQuente text,
  title text not null,
  subtitle1 text not null,
  subtitle2 text not null,
  subtitle3 text not null,
  subtitle4 text not null,
  dados text not null,
  sincronizado integer not null
  )
''',
        );
      },
    );
    batch = db.batch();
    isOpen = true;
  }

  // Future<bool> insertOK(RegistroListagem registro) async {
  //   print('insert');
  //   registro.id = await db.insert(tabela, registro.toMap());
  //   if (registro.id > 0) {
  //     print('registro.id > 0  ${registro.id}');
  //     return true;
  //   } else {
  //     print('registro.id > 0 false ${registro.id} ');
  //     return false;
  //   }
  // }

  // Future<void> insert(RegistroListagem registro) async {
  Future<bool> insert(RegistroListagem registro) async {
    print('insert');

    try {
      //o insert retorna o ID do registro inserido
      registro.id = await db.insert(tabela, registro.toMap());
      return true;
    } catch (e) {
      print(e);
      //TODO: talvez retornar o erro pra pegar se foi algo diferende primaryKey duplicada
      return false;
    }
  }

  Future<bool> update(int id, RegistroListagem registro) async {
    // print('update');
    registro.id = id;
    try {
      // var x = await db.update(table, values)
      //o update restorna um int com o número de registros alterados
      await db.update(tabela, registro.toMap(), where: 'id = $id');
      return true;
    } catch (e) {
      print(e);
      //TODO: talvez retornar o erro pra pegar se foi algo diferende primaryKey duplicada
      return false;
    }
  }

  Future<List<RegistroListagem>> getAll({
    String busca = '',
    bool somenteFaltaSubir = false,
    int? limit,
  }) async {
    final List<RegistroListagem> listagem = [];
    limit = limit ?? 1000;
    // print(busca);
    //se vamos mostrar sometne o que falta subir então é sincronizado = 0
    List<Map<String, Object?>> aux;
    if (isOpen) {
      if (somenteFaltaSubir) {
        aux = await db.query(
          tabela,
          where:
              "(title LIKE '%$busca%' or subtitle1 LIKE '%$busca%' or subtitle2 LIKE '%$busca%' or subtitle3 LIKE '%$busca%' or subtitle4 LIKE '%$busca%' ) and sincronizado = 0 order by upper(title) limit $limit ",
        ); //, whereArgs: ['%$busca%']);
      } else {
        aux = await db.query(
          tabela,
          where:
              "(title LIKE '%$busca%' or subtitle1 LIKE '%$busca%' or subtitle2 LIKE '%$busca%' or subtitle3 LIKE '%$busca%' or subtitle4 LIKE '%$busca%' ) order by upper(title) limit $limit ",
        ); //, whereArgs: ['%$busca%']);
      }

      for (final r in aux) {
        listagem.add(RegistroListagem.fromMap(r));
      }
    }

    return listagem;
  }

  Future<int> getTotal({
    String busca = '',
    bool somenteFaltaSubir = false,
  }) async {
    // List<RegistroListagem> listagem = [];
    // print(busca);
    //se vamos mostrar sometne o que falta subir então é sincronizado = 0
    int? count = 0;

    if (isOpen) {
      if (somenteFaltaSubir) {
        count = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM $tabela where (title LIKE '%$busca%' or subtitle1 LIKE '%$busca%' or subtitle2 LIKE '%$busca%' or subtitle3 LIKE '%$busca%' or subtitle4 LIKE '%$busca%' ) and sincronizado = 0  ",
          ),
        );
      } else {
        count = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM $tabela where (title LIKE '%$busca%' or subtitle1 LIKE '%$busca%' or subtitle2 LIKE '%$busca%' or subtitle3 LIKE '%$busca%' or subtitle4 LIKE '%$busca%' )  ",
          ),
        );
      }
    }

    return count ?? 0;
  }

  Future<bool> marcaSincronizado(int id) async {
    // print('marca sincron $id');
    try {
      // var x = await db.update(table, values)
      id = await db.update(tabela, {'sincronizado': 1}, where: 'id = $id');
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> marcaNaoSincronizado(int id) async {
    print('marca não sincron $id');
    try {
      // var x = await db.update(table, values)
      id = await db.update(tabela, {'sincronizado': 0}, where: 'id = $id');
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

// getRegistroByPrimaryKeyQuente
  Future<int?> getRegistroIdByPrimaryKeyQuente(String primaryKeyQuente) async {
    final List<Map> maps = await db.query(
      tabela,
      columns: ['id'],
      where: 'primaryKeyQuente = ?',
      whereArgs: [primaryKeyQuente],
    );
    if (maps.isNotEmpty) {
      // print(
      //     'getRegistroByPrimaryKeyQuente TEM registro onde primaryKeyQuente $primaryKeyQuente');
      // print(maps.first);
      return maps.first['id'];
    } else {
      // print(
      //     'getRegistroByPrimaryKeyQuente nao tem registro onde primaryKeyQuente $primaryKeyQuente');
      return null;
    }
  }

  Future<int?> getRegistroIdByTemporarioIdQuente(
    String temporarioIdQuente,
  ) async {
    // print('entrou getRegistroIdByTemporarioIdQuente $temporarioIdQuente');
    final List<Map> maps = await db.query(
      tabela,
      columns: ['id'],
      where: 'temporarioIdQuente = ?',
      whereArgs: [temporarioIdQuente],
    );
    if (maps.isNotEmpty) {
      // print('registro encontrado');
      // print(maps.first);
      return maps.first['id'];
    } else {
      // print('nao tem registro com esse temporarioIdQuente $temporarioIdQuente');
      return null;
    }
  }

  Future<RegistroListagem> getRegistroListagem(int id) async {
    print('entrou getRegistroListagem $id');
    final List<Map> maps = await db.query(
      tabela,
      columns: [
        'id',
        'primaryKey',
        'primaryKeyQuente',
        'temporarioIdQuente',
        'title',
        'subtitle1',
        'subtitle2',
        'subtitle3',
        'subtitle4',
        'dados',
        'sincronizado'
      ],
      where: 'id = ?',
      whereArgs: [id],
    );

    return RegistroListagem.fromMap(maps.first.cast());
  }

  Future<bool> delete(int id) async {
    print('delete $id');
    final r = await db.delete(tabela, where: 'id = ?', whereArgs: [id]);
    if (r > 0) {
      return true;
    } else {
      return false;
    }
  }

  // Future<int> update(Todo todo) async {
  //   return await db.update(tableTodo, todo.toMap(),
  //       where: '$columnId = ?', whereArgs: [todo.id]);
  // }

  batchInsert(RegistroListagem registro) {
    // print('batchInsert');
    batch.insert(tabela, registro.toMap());
  }

  batchUpdate(int id, RegistroListagem registro) {
    // print('batchUpdate');
    batch.update(tabela, registro.toMap(), where: 'id = $id');
  }

  batchInsertOrUpdate(RegistroListagem registro) {}

  Future<void> batchCommit() async {
    print('inicio batch commit');
    try {
      await batch.commit(noResult: true);
      await close();
      await open();
    } catch (e) {
      rethrow;
    }
    print('final batchcommit');
  }

  Future<bool> existemItensParaSubir() async {
    print('vendo se existem registros para subir');
    final r =
        await db.query(tabela, columns: ['id'], where: 'sincronizado = 0');
    print(r);
    if (r.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

//TODO: OTIMIZAÇÃO unificar essas duas funcoes
  Future<List<dynamic>> listaQueFaltaSubir(bool forcar) async {
    // print('criando lista dos que falta subir');

    List<Map> maps;
    if (forcar) {
      maps = await db.query(tabela, columns: ['id']);
    } else {
      maps = await db.query(
        tabela,
        columns: ['id'],
        where: 'sincronizado = ?',
        orderBy: 'primaryKeyQuente DESC',
        whereArgs: [0],
      );
    }

    print('criando lista de ids que falta subir');
    print(
      maps.map((element) => element.values.first).toList(),
    );
    return maps.map((element) => element.values.first).toList();
  }

  // Future<void> deleteByPrimaryKeyQuente(String primaryKeyQuente) async {
  //   batch.rawQuery(
  //       "DELETE from $tabela where primaryKeyQuente = '$primaryKeyQuente' limit 1");
  // }
  // // Future<void> deleteByPrimaryKey(String primaryKey) async {
  // //   batch.rawQuery("DELETE from $tabela where primaryKey = '$primaryKey' ");
  // // }

  Future close() async {
    await db.close();
    isOpen = false;
    // print('close banco');
  }
}
