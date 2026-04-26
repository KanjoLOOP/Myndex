/// Modelo de errores de dominio.
///
/// Diferenciamos los fallos de la capa de datos/red con clases
/// concretas para que la UI pueda decidir cómo reaccionar (reintentar,
/// mostrar mensaje específico, ofrecer modo offline, etc.) sin
/// depender de excepciones de implementación (DioException, DriftException…).
library;

abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Fallo de la base de datos local (lectura/escritura SQLite).
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// Fallo en cualquier llamada a una API externa.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Fallo durante el proceso de importación (parseo JSON, esquema…).
class ImportFailure extends Failure {
  const ImportFailure(super.message);
}

/// Fallo durante el proceso de exportación.
class ExportFailure extends Failure {
  const ExportFailure(super.message);
}

/// Validación de datos de entrada (formularios, payloads).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Recurso solicitado no encontrado.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
