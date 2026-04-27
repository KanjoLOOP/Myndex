import 'package:drift_flutter/drift_flutter.dart';

import '../constants/app_constants.dart';
import 'app_database.dart';

AppDatabase openNativeDatabase() => AppDatabase(driftDatabase(
      name: AppConstants.dbName,
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ));
