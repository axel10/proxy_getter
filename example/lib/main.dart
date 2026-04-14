import 'package:flutter/material.dart';
import 'package:proxy_getter/proxy_getter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final proxy = await getSystemProxy();
  runApp(MyApp(proxy: proxy));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.proxy});

  final SystemProxy proxy;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Proxy Getter')),
        body: Center(
          child: Text(
            [
              'Enabled: ${proxy.enable}',
              'Host: ${proxy.host}',
              'Port: ${proxy.port}',
              'Bypass: ${proxy.bypass}',
            ].join('\n'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
