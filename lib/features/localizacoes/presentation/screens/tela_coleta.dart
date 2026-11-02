import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/localizacao.dart';
import '../../data/repositories/repositorio_localizacoes.dart';
import '../../services/servico_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';

class TelaColeta extends StatefulWidget {
  final RepositorioLocalizacoes repositorio;
  final ServicoLocalizacao servico;

  const TelaColeta({
    super.key,
    required this.repositorio,
    required this.servico,
  });

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  StreamSubscription<void>? _assinatura;
  Future<void> _gravacao = Future<void>.value();
  bool _ocupada = false;
  bool _ativa = false;
  String _mensagem = 'Coleta parada.';

  void _mostrar(String mensagem) {
    if (!mounted) return;
    setState(() => _mensagem = mensagem);
  }

  Future<void> _salvar(Position posicao) {
    _gravacao = _gravar(posicao);
    return _gravacao;
  }

  Future<void> _gravar(Position posicao) async {
    final localizacao = Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      instante: posicao.timestamp,
    );
    await widget.repositorio.inserir(localizacao);
    _mostrar('Localização salva no banco.');
  }

  Future<void> _iniciar() async {
    if (_ocupada || _ativa) return;
    setState(() => _ocupada = true);
    try {
      await widget.servico.verificarPermissao();
      await widget.servico.verificarNotificacao();
      if (!mounted) return;
      // asyncMap espera uma gravação terminar antes de processar a próxima.
      _assinatura = widget.servico.posicoes().asyncMap(_salvar).listen(
        (_) {},
        onError: (Object erro) {
          _mostrar('Falha na coleta ou no banco: $erro');
          unawaited(_encerrarAposErro());
        },
        onDone: () {
          _assinatura = null;
          if (mounted) setState(() => _ativa = false);
        },
      );
      setState(() {
        _ativa = true;
        _mensagem = 'Coleta ativa. Aguardando uma posição...';
      });
    } catch (erro) {
      _mostrar('Não foi possível iniciar: $erro');
    } finally {
      if (mounted) setState(() => _ocupada = false);
    }
  }

  Future<void> _encerrarAposErro() async {
    try {
      await _cancelarAssinatura();
    } catch (erro) {
      _mostrar('Falha ao encerrar a coleta: $erro');
    }
  }

  Future<void> _cancelarAssinatura() async {
    final assinatura = _assinatura;
    await assinatura?.cancel();
    _assinatura = null;
    try {
      await _gravacao;
    } catch (_) {
      // O erro de gravação já foi apresentado pelo onError do stream.
    }
    if (mounted) setState(() => _ativa = false);
  }

  Future<void> _parar() async {
    if (_ocupada || !_ativa) return;
    setState(() => _ocupada = true);
    try {
      await _cancelarAssinatura();
      _mostrar('Coleta parada.');
    } catch (erro) {
      _mostrar('Erro ao parar: $erro');
    } finally {
      if (mounted) setState(() => _ocupada = false);
    }
  }

  Future<void> _configuracoes() async {
    try {
      await widget.servico.abrirConfiguracoes();
    } catch (erro) {
      _mostrar('Erro: $erro');
    }
  }

  @override
  void dispose() {
    // Esta tela permanece montada quando outra é aberta com Navigator.push.
    unawaited(_assinatura?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas localizações')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_mensagem),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _ocupada || _ativa ? null : _iniciar,
            child: const Text('Iniciar coleta'),
          ),
          OutlinedButton(
            onPressed: _ocupada || !_ativa ? null : _parar,
            child: const Text('Parar coleta'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TelaLocalizacoes(
                  repositorio: widget.repositorio,
                  coletaAtiva: () => _ativa,
                ),
              ),
            ),
            child: const Text('Consultar histórico'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TelaMapa(repositorio: widget.repositorio),
              ),
            ),
            child: const Text('Ver mapa'),
          ),
          TextButton(
            onPressed: _ocupada ? null : _configuracoes,
            child: const Text('Configurações de permissão'),
          ),
          const SizedBox(height: 16),
          const Text('O intervalo solicitado é de 20 segundos. '
              'O Android e o sinal de localização podem alterar esse tempo.'),
        ],
      ),
    );
  }
}
