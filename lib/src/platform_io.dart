import 'dart:io';
import 'package:flutter/services.dart';
import 'proxy_getter.dart';

Future<SystemProxy> getSystemProxyInternal(MethodChannel channel) async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows) {
    try {
      final map = await channel.invokeMapMethod<String, Object?>('getSystemProxy');
      return SystemProxy.fromMap(map ?? const <String, Object?>{});
    } catch (e) {
      return const SystemProxy(enable: false, host: '', port: 0, bypass: '');
    }
  }

  if (Platform.isLinux) {
    return _getLinuxProxy();
  }

  return const SystemProxy(enable: false, host: '', port: 0, bypass: '');
}

Future<SystemProxy> _getLinuxProxy() async {
  // 1. Check environment variables
  final envHttpProxy = Platform.environment['http_proxy'] ?? Platform.environment['HTTP_PROXY'];
  if (envHttpProxy != null && envHttpProxy.isNotEmpty) {
    try {
      var uriStr = envHttpProxy;
      if (!uriStr.startsWith('http://') && !uriStr.startsWith('https://') && !uriStr.startsWith('socks://')) {
        uriStr = 'http://$uriStr';
      }
      final uri = Uri.parse(uriStr);
      final bypass = Platform.environment['no_proxy'] ?? Platform.environment['NO_PROXY'] ?? '';
      return SystemProxy(
        enable: true,
        host: uri.host,
        port: uri.port,
        bypass: bypass,
      );
    } catch (_) {}
  }

  // 2. Try desktop-specific settings
  final desktop = Platform.environment['XDG_CURRENT_DESKTOP'] ?? '';
  final isKDE = desktop == 'KDE';

  if (isKDE) {
    try {
      final kdeVer = Platform.environment['KDE_SESSION_VERSION'] ?? '';
      final cmd = kdeVer == '6' ? 'kreadconfig6' : 'kreadconfig5';

      final modeResult = await Process.run(cmd, [
        '--file', 'kioslaverc',
        '--group', 'Proxy Settings',
        '--key', 'ProxyType'
      ]);
      final mode = modeResult.stdout.toString().trim();
      if (mode == '1') {
        final httpProxyResult = await Process.run(cmd, [
          '--file', 'kioslaverc',
          '--group', 'Proxy Settings',
          '--key', 'httpProxy'
        ]);
        final httpProxy = httpProxyResult.stdout.toString().trim();
        var proxyStr = httpProxy;
        if (proxyStr.isEmpty) {
          final socksProxyResult = await Process.run(cmd, [
            '--file', 'kioslaverc',
            '--group', 'Proxy Settings',
            '--key', 'socksProxy'
          ]);
          proxyStr = socksProxyResult.stdout.toString().trim();
        }

        if (proxyStr.isNotEmpty) {
          proxyStr = proxyStr.replaceAll('http://', '').replaceAll('socks://', '').replaceAll('https://', '');
          final parts = proxyStr.split(' ');
          final host = parts[0];
          final port = parts.length > 1 ? (int.tryParse(parts[1]) ?? 80) : 80;

          final bypassResult = await Process.run(cmd, [
            '--file', 'kioslaverc',
            '--group', 'Proxy Settings',
            '--key', 'NoProxyFor'
          ]);
          final bypass = bypassResult.stdout.toString().trim();

          return SystemProxy(
            enable: true,
            host: host,
            port: port,
            bypass: bypass,
          );
        }
      }
    } catch (_) {}
  } else {
    try {
      final isAppImage = Platform.environment.containsKey('APPIMAGE');
      final environment = isAppImage 
          ? (Map<String, String>.from(Platform.environment)..remove('LD_LIBRARY_PATH'))
          : null;

      final modeResult = await Process.run('gsettings', ['get', 'org.gnome.system.proxy', 'mode'], environment: environment);
      final mode = modeResult.stdout.toString().trim().replaceAll("'", "");
      if (mode == 'manual') {
        String? host;
        int? port;

        for (final proto in ['socks', 'http', 'https']) {
          final hostRes = await Process.run('gsettings', ['get', 'org.gnome.system.proxy.$proto', 'host'], environment: environment);
          final h = hostRes.stdout.toString().trim().replaceAll("'", "");
          if (h.isNotEmpty) {
            final portRes = await Process.run('gsettings', ['get', 'org.gnome.system.proxy.$proto', 'port'], environment: environment);
            final p = int.tryParse(portRes.stdout.toString().trim()) ?? 0;
            if (p > 0) {
              host = h;
              port = p;
              break;
            }
          }
        }

        if (host != null && port != null) {
          final bypassResult = await Process.run('gsettings', ['get', 'org.gnome.system.proxy', 'ignore-hosts'], environment: environment);
          var bypass = bypassResult.stdout.toString().trim();
          bypass = bypass.replaceAll(RegExp(r"[\[\]']"), '').split(',').map((e) => e.trim()).join(',');

          return SystemProxy(
            enable: true,
            host: host,
            port: port,
            bypass: bypass,
          );
        }
      }
    } catch (_) {}
  }

  return const SystemProxy(enable: false, host: '', port: 0, bypass: '');
}
