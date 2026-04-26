abstract class Failure {
  final String message;
  const Failure(this.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ImportFailure extends Failure {
  const ImportFailure(super.message);
}

class ExportFailure extends Failure {
  const ExportFailure(super.message);
}
