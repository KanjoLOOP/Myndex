import 'dart:async';

// This file is required by the flutter test runner.
// On Windows, sqlite3.dll must be present in the project root directory
// (or in PATH) for Drift NativeDatabase.memory() tests to work.
// Run: copy %USERPROFILE%\AppData\Local\Programs\Python\Python313\DLLs\sqlite3.dll .
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await testMain();
}
