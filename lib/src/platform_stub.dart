import 'package:flutter/services.dart';
import 'proxy_getter.dart';

Future<SystemProxy> getSystemProxyInternal(MethodChannel channel) async {
  return const SystemProxy(enable: false, host: '', port: 0, bypass: '');
}
