import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:dio/dio.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api_service.dart';

/// Собирает «досье» об устройстве/сети и (опционально) шлёт визит на сервер.
/// Гео — только по IP (без системных разрешений). Чисто для рофла.
class TrackerService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
  ));

  /// Собирает все доступные данные в Map. Любая отдельная ошибка не валит
  /// весь сбор — поле просто останется null.
  static Future<Map<String, dynamic>> collect({String? username}) async {
    final data = <String, dynamic>{'username': username};

    await Future.wait([
      _collectIpGeo(data),
      _collectDevice(data),
      _collectBattery(data),
      _collectNetwork(data),
      _collectApp(data),
    ]);

    // Локаль и таймзона устройства — синхронно, без сети.
    try {
      data['locale'] = PlatformDispatcher.instance.locale.toLanguageTag();
    } catch (_) {}
    data['timezone'] ??= DateTime.now().timeZoneName;

    return data;
  }

  /// Собирает данные и фоном отправляет визит на сервер. Ошибки гасятся.
  static Future<void> recordVisit({String? username}) async {
    try {
      final data = await collect(username: username);
      await ApiService.sendVisit(data);
    } catch (_) {}
  }

  static Future<void> _collectIpGeo(Map<String, dynamic> d) async {
    try {
      final res = await _dio.get('https://ipwho.is/');
      final j = res.data as Map<String, dynamic>;
      if (j['success'] == false) return;
      d['ip'] = j['ip'];
      d['city'] = j['city'];
      d['region'] = j['region'];
      d['country'] = j['country'];
      d['lat'] = j['latitude'];
      d['lon'] = j['longitude'];
      final conn = j['connection'];
      if (conn is Map) d['isp'] = conn['isp'] ?? conn['org'];
      final tz = j['timezone'];
      if (tz is Map && tz['id'] != null) d['timezone'] = tz['id'];
    } catch (_) {}
  }

  static Future<void> _collectDevice(Map<String, dynamic> d) async {
    try {
      d['platform'] = Platform.operatingSystem;
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        d['device'] = '${a.manufacturer} ${a.model}';
        d['os'] = 'Android ${a.version.release} (SDK ${a.version.sdkInt})';
      } else if (Platform.isIOS) {
        final i = await info.iosInfo;
        d['device'] = '${i.name} (${i.utsname.machine})';
        d['os'] = '${i.systemName} ${i.systemVersion}';
      } else if (Platform.isMacOS) {
        final m = await info.macOsInfo;
        d['device'] = m.model;
        d['os'] = 'macOS ${m.osRelease}';
      } else {
        d['os'] = Platform.operatingSystemVersion;
      }
    } catch (_) {}
  }

  static Future<void> _collectBattery(Map<String, dynamic> d) async {
    try {
      d['battery'] = await Battery().batteryLevel;
    } catch (_) {}
  }

  static Future<void> _collectNetwork(Map<String, dynamic> d) async {
    try {
      final results = await Connectivity().checkConnectivity();
      final r = results.isNotEmpty ? results.first : ConnectivityResult.none;
      d['network'] = switch (r) {
        ConnectivityResult.wifi => 'Wi-Fi',
        ConnectivityResult.mobile => 'Mobile',
        ConnectivityResult.ethernet => 'Ethernet',
        ConnectivityResult.vpn => 'VPN',
        ConnectivityResult.bluetooth => 'Bluetooth',
        ConnectivityResult.none => 'Offline',
        _ => 'Other',
      };
    } catch (_) {}
  }

  static Future<void> _collectApp(Map<String, dynamic> d) async {
    try {
      final p = await PackageInfo.fromPlatform();
      d['app_version'] = '${p.version}+${p.buildNumber}';
    } catch (_) {}
  }
}
