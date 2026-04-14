import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:proxy_getter/proxy_getter.dart';

const String kCoverUrl =
    'https://coverartarchive.org/release/690eda44-dae6-45c3-9b75-30c524df11e5/front';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final proxy = await getSystemProxy();
  HttpOverrides.global = _SystemProxyHttpOverrides(proxy);
  runApp(MyApp(proxy: proxy));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.proxy});

  final SystemProxy proxy;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF243B53)),
        useMaterial3: true,
      ),
      home: ProxyTestPage(proxy: proxy),
    );
  }
}

class ProxyTestPage extends StatefulWidget {
  const ProxyTestPage({super.key, required this.proxy});

  final SystemProxy proxy;

  @override
  State<ProxyTestPage> createState() => _ProxyTestPageState();
}

class _ProxyTestPageState extends State<ProxyTestPage> {
  final Dio _dio = Dio();
  String _dioStatus = 'Idle';
  String _dioDetails = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadImageByDio();
  }

  Future<void> _loadImageByDio() async {
    setState(() {
      _loading = true;
      _dioStatus = 'Loading';
      _dioDetails = '';
    });

    try {
      final response = await _dio.get<List<int>>(
        kCoverUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data?.length ?? 0;
      final contentType = response.headers.value('content-type') ?? 'unknown';

      if (!mounted) return;
      setState(() {
        _dioStatus = 'Success';
        _dioDetails = 'Bytes: $bytes\nContent-Type: $contentType';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dioStatus = 'Failed';
        _dioDetails = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proxy = widget.proxy;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proxy Getter Test'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadImageByDio,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload with Dio',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            title: 'System Proxy',
            child: Text(
              [
                'Enabled: ${proxy.enable}',
                'Host: ${proxy.host}',
                'Port: ${proxy.port}',
                'Bypass: ${proxy.bypass}',
              ].join('\n'),
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Dio Request',
            child: Text(
              'Status: $_dioStatus\n\n$_dioDetails',
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Image.network',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                kCoverUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 260,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes == null
                            ? null
                            : loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    height: 260,
                    child: Center(
                      child: Text(
                        'Image load failed:\n$error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 10),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SystemProxyHttpOverrides extends HttpOverrides {
  _SystemProxyHttpOverrides(this.proxy);

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
