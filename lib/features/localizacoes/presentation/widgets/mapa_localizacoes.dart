import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/localizacao.dart';
import 'item_localizacao.dart';

class MapaLocalizacoes extends StatefulWidget {
  final List<Localizacao> registros;
  final BuiltInMapCachingProvider cache;

  const MapaLocalizacoes({
    super.key,
    required this.registros,
    required this.cache,
  });

  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  final MapController _controlador = MapController();
  bool _falhaImagem = false;
  bool _avisoAgendado = false;

  List<LatLng> get _pontos => widget.registros
      .map((localizacao) => LatLng(localizacao.latitude, localizacao.longitude))
      .toList();

  CameraFit _enquadramento() => CameraFit.coordinates(
        coordinates: _pontos,
        padding: const EdgeInsets.all(48),
        maxZoom: 16,
      );

  void _avisarFalhaImagem() {
    // O callback pode ocorrer durante a montagem: atualiza após o frame.
    if (_falhaImagem || _avisoAgendado) return;
    _avisoAgendado = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _avisoAgendado = false;
      if (mounted) setState(() => _falhaImagem = true);
    });
  }

  Future<void> _abrirAtribuicao() async {
    try {
      final abriu = await launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
        mode: LaunchMode.externalApplication,
      );
      if (!abriu) throw Exception('Não foi possível abrir o navegador.');
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Atribuição: openstreetmap.org/copyright. $erro')),
      );
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_falhaImagem)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Algumas imagens não carregaram. '
                'Verifique a internet e atualize o mapa.'),
          ),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _controlador,
                options: MapOptions(
                  initialCenter: _pontos.first,
                  initialCameraFit: _enquadramento(),
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'br.com.bruna.localizacoes',
                    maxNativeZoom: 19,
                    tileProvider:
                        NetworkTileProvider(cachingProvider: widget.cache),
                    errorTileCallback: (tile, erro, pilha) =>
                        _avisarFalhaImagem(),
                  ),
                  MarkerLayer(
                    markers: [
                      // Pinta a mais recente por último para ficar por cima.
                      for (int indice = widget.registros.length - 1;
                          indice >= 0;
                          indice--)
                        Marker(
                          point: _pontos[indice],
                          width: 48,
                          height: 48,
                          child: IconButton(
                            tooltip: indice == 0
                                ? 'Localização mais recente'
                                : 'Ver localização',
                            icon: Icon(
                              Icons.location_on,
                              color: indice == 0 ? Colors.red : Colors.blue,
                              size: 36,
                            ),
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              builder: (_) => SafeArea(
                                child: ItemLocalizacao(
                                    localizacao: widget.registros[indice]),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 12,
                right: 12,
                child: FloatingActionButton.small(
                  tooltip: 'Enquadrar todos os pontos',
                  onPressed: () => _controlador.fitCamera(_enquadramento()),
                  child: const Icon(Icons.center_focus_strong),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Material(
                  color: Colors.white,
                  child: InkWell(
                    onTap: _abrirAtribuicao,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Text('© OpenStreetMap contributors',
                          style: TextStyle(color: Colors.blue, fontSize: 12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
