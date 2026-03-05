// lib/core/network/network_info.dart
// ✅ Web-safe ağ bağlantıs1 kontrolü

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Ağ bağlantıs1 kontrol arayüzü
abstract class NetworkInfo {
  Future<bool> get baglantiVarMi; // '1' yerine 'i' - illegal_character fix
}

/// NetworkInfo implementasyonu
/// Web'de her zaman bağl1 kabul eder (internet_connection_checker web desteklemiyor)
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker? _checker;

  NetworkInfoImpl(this._checker);

  @override
  Future<bool> get baglantiVarMi async {
    // Web platformunda connection checker alışmıyor
    if (kIsWeb) return true;
    return await _checker?.hasConnection ?? true;
  }
}
