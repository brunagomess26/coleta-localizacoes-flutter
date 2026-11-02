import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class ServicoLocalizacao {
  Future<void> verificarPermissao() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception(
          'Ative a localização (GPS) nas configurações do aparelho.');
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.deniedForever) {
      throw Exception('Permissão bloqueada. Use Configurações de permissão.');
    }
    if (permissao != LocationPermission.whileInUse &&
        permissao != LocationPermission.always) {
      throw Exception('Permissão negada. Autorize a localização para coletar.');
    }
  }

  Future<void> verificarNotificacao() async {
    final permissao = await Permission.notification.request();
    if (!permissao.isGranted) {
      throw Exception(
          'Autorize as notificações nas configurações do aplicativo '
          'para manter o aviso da coleta visível.');
    }
  }

  Stream<Position> posicoes() {
    // Esta entrega é para Android. Inicie a coleta com o app visível.
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 20),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Coleta de localização ativa',
          notificationText: 'Abra o aplicativo para parar a coleta.',
          notificationChannelName: 'Coleta de localizações',
          notificationIcon: AndroidResource(
            name: 'ic_stat_localizacao',
            defType: 'drawable',
          ),
          enableWakeLock: true,
          setOngoing: true,
        ),
      ),
    );
  }

  Future<void> abrirConfiguracoes() async {
    if (!await Geolocator.openAppSettings()) {
      throw Exception('Não foi possível abrir as configurações.');
    }
  }
}
