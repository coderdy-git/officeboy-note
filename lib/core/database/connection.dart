import 'package:drift/drift.dart';

import 'connection_stub.dart'
    if (dart.library.io) 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart';

/// Open a database connection. Works on all platforms:
/// - Native: uses SQLite via `drift/native.dart`
/// - Web: uses sql.js via `drift/web.dart`
QueryExecutor openConnection(String name) => createConnection(name);
