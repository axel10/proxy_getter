import 'dart:convert';

import 'package:flutter/services.dart';

import 'platform_stub.dart' if (dart.library.io) 'platform_io.dart';
import 'rust/api/simple.dart' as rust_api;
import 'rust/frb_generated.dart';

const MethodChannel _proxyChannel = MethodChannel('proxy_getter/system_proxy');

bool _rustInitialized = false;

Future<void> _ensureRustInitialized() async {
  if (_rustInitialized) {
    return;
  }
  await RustLib.init();
  _rustInitialized = true;
}

class SystemProxy {
  const SystemProxy({
    required this.enable,
    required this.host,
    required this.port,
    required this.bypass,
  });

  final bool enable;
  final String host;
  final int port;
  final String bypass;

  factory SystemProxy.fromMap(Map<String, Object?> map) {
    return SystemProxy(
      enable: map['enable'] as bool? ?? false,
      host: map['host'] as String? ?? '',
      port: (map['port'] as num?)?.toInt() ?? 0,
      bypass: map['bypass'] as String? ?? '',
    );
  }

  factory SystemProxy.fromJson(String jsonText) {
    final raw = jsonDecode(jsonText);
    if (raw is Map<String, dynamic>) {
      return SystemProxy.fromMap(raw);
    }
    return const SystemProxy(enable: false, host: '', port: 0, bypass: '');
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'enable': enable,
      'host': host,
      'port': port,
      'bypass': bypass,
    };
  }

  String toJson() => jsonEncode(toMap());

  @override
  String toString() => 'SystemProxy($toJson())';
}

Future<SystemProxy> getSystemProxy() async {
  if (isMobilePlatform) {
    final map = await _proxyChannel.invokeMapMethod<String, Object?>(
      'getSystemProxy',
    );
    return SystemProxy.fromMap(map ?? const <String, Object?>{});
  }

  await _ensureRustInitialized();
  return SystemProxy.fromJson(rust_api.getSystemProxyJson());
}
