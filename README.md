# proxy_getter

`proxy_getter` is a Flutter plugin for reading the current system proxy configuration and exposing it to Dart as a simple `SystemProxy` model.

It is designed for apps that need to:

- respect the user's OS-level proxy settings
- route `dart:io` traffic through the system proxy
- inspect proxy state before making network requests

The plugin uses:

- native platform channels on Android and iOS
- Rust FFI on desktop platforms

## Platform Notes

The proxy keys exposed by Apple's CFNetwork framework are not the same across all Apple platforms.

- On iOS, this plugin reads the system HTTP proxy settings.
- On macOS, the native implementation can read a broader set of proxy values, including HTTPS, SOCKS, and bypass lists.
- If a platform does not expose a proxy configuration, `getSystemProxy()` returns an "empty" `SystemProxy` with `enable = false`.

## Features

- Read system proxy settings from Flutter
- Return a strongly typed `SystemProxy` object
- Serialize and deserialize proxy data as JSON
- Works with `HttpOverrides`, Dio, and any `dart:io` HTTP client

## API

### `getSystemProxy()`

Returns a `Future<SystemProxy>` with these fields:

- `enable`
- `host`
- `port`
- `bypass`

### `SystemProxy`

```dart
class SystemProxy {
  const SystemProxy({
    required this.enable,
    required this.host,
    required this.port,
    required this.bypass,
  });
}
```

You can also convert it with:

- `toMap()`
- `toJson()`
- `SystemProxy.fromMap(...)`
- `SystemProxy.fromJson(...)`


## Basic Usage

```dart
import 'package:proxy_getter/proxy_getter.dart';

Future<void> main() async {
  final proxy = await getSystemProxy();

  print(proxy.enable);
  print(proxy.host);
  print(proxy.port);
  print(proxy.bypass);
}
```

## Example: Use With `HttpOverrides`

This is the most common scenario when you want all `dart:io` network requests to respect the system proxy.

```dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:proxy_getter/proxy_getter.dart';

class SystemProxyHttpOverrides extends HttpOverrides {
  SystemProxyHttpOverrides(this.proxy);

  final SystemProxy proxy;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) {
      if (!proxy.enable || proxy.host.isEmpty || proxy.port <= 0) {
        return 'DIRECT';
      }
      return 'PROXY ${proxy.host}:${proxy.port}';
    };
    return client;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final proxy = await getSystemProxy();
  HttpOverrides.global = SystemProxyHttpOverrides(proxy);

  runApp(const MyApp());
}
```

## Example: Use With Dio

You can configure Dio to use the system proxy specifically without affecting the global `HttpOverrides`:

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:proxy_getter/proxy_getter.dart';

Future<void> main() async {
  final proxy = await getSystemProxy();
  final dio = Dio();

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (uri) {
        if (!proxy.enable || proxy.host.isEmpty || proxy.port <= 0) {
          return 'DIRECT';
        }
        return 'PROXY ${proxy.host}:${proxy.port}';
      };
      return client;
    },
  );

  final response = await dio.get('https://example.com');
}
```

## Example: Use in `Image.network`

You can also apply the proxy globally before loading network images:

```dart
final proxy = await getSystemProxy();
HttpOverrides.global = SystemProxyHttpOverrides(proxy);
```

Then `Image.network(...)` requests made through the app will follow the same proxy configuration.

## Example App

The [`example/`](example/) app demonstrates a full end-to-end flow:

1. Read the system proxy
2. Apply it to `HttpOverrides.global`
3. Load a remote image
4. Test the same proxy behavior with Dio

This is a good reference if you want to see the plugin working in a real Flutter app.

## Project Structure

- [`lib/proxy_getter.dart`](lib/proxy_getter.dart) - public exports
- [`lib/src/proxy_getter.dart`](lib/src/proxy_getter.dart) - `SystemProxy` model and `getSystemProxy()`
- [`example/lib/main.dart`](example/lib/main.dart) - full usage demo

## Supported Platforms

- Android
- iOS
- Windows
- macOS
- Linux

## Requirements

The Rust environment requirement depends on your target platform:

| Platform | Rust Required | Reason |
| :--- | :---: | :--- |
| **Windows / macOS / Linux** | **Yes** | Uses Rust FFI, compiled during build. |
| **Android / iOS** | **No** | Uses native platform channels. |

If you are building for desktop, ensure you have the [Rust toolchain](https://rustup.rs/) installed.

## Notes

- On Android, proxy data is read through the native channel.
- On iOS, proxy data is read through the native channel, but only the HTTP proxy fields are guaranteed to be available.
- On desktop platforms, proxy data is read through the Rust implementation.
- If no proxy is available, the returned object will usually have `enable = false`, empty `host`, and `port = 0`.

## License

See the [LICENSE](LICENSE) file for details.
