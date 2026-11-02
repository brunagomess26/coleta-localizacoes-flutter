import 'package:flutter/material.dart';
import '../../models/localizacao.dart';

class ItemLocalizacao extends StatelessWidget {
  final Localizacao localizacao;

  const ItemLocalizacao({super.key, required this.localizacao});

  String _doisDigitos(int valor) => valor.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final data = localizacao.instante.toLocal();
    final dataFormatada = '${_doisDigitos(data.day)}/'
        '${_doisDigitos(data.month)}/${data.year} '
        '${_doisDigitos(data.hour)}:${_doisDigitos(data.minute)}:'
        '${_doisDigitos(data.second)}';
    return ListTile(
      leading: const Icon(Icons.location_on),
      title: Text(dataFormatada),
      subtitle: Text(
        'Latitude: ${localizacao.latitude.toStringAsFixed(6)}\n'
        'Longitude: ${localizacao.longitude.toStringAsFixed(6)}\n'
        'Precisão: ${localizacao.precisao.toStringAsFixed(1)} m',
      ),
      isThreeLine: true,
    );
  }
}
