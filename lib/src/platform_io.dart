import 'dart:io' show Platform;

bool get isMobilePlatform => Platform.isAndroid || Platform.isIOS;
