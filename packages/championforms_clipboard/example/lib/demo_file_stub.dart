/// No local files on the web.
Future<String> createDemoFile() =>
    Future.error(UnsupportedError('no local files on the web'));
