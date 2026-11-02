import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';

class RepositorioLocalizacoes {
  final BancoLocalizacoes banco;

  RepositorioLocalizacoes(this.banco);

  Future<void> inserir(Localizacao localizacao) async {
    final conexao = await banco.conexao;
    await conexao.insert('localizacoes', localizacao.toMap());
  }

  Future<List<Localizacao>> consultar() async {
    final conexao = await banco.conexao;
    final registros = await conexao.query(
      'localizacoes',
      orderBy: 'instante DESC, id DESC',
      limit: 100,
    );
    return registros.map(Localizacao.fromMap).toList();
  }

  Future<void> limpar() async {
    final conexao = await banco.conexao;
    await conexao.delete('localizacoes'); // Sem WHERE: exclui todas as linhas.
  }
}
