import 'package:isar/isar.dart';

part 'pending_operation.g.dart';

@collection
class PendingOperation {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('idempotencyKey')], unique: true)
  late String ownerId;

  late String idempotencyKey;
  late String entityType;
  late String entityId;
  late String operationType;
  late String payloadJson;
  late String clientVersion;

  /// pending, processing, synchronized, conflict, failed
  late String status;
  late DateTime createdAt;
  late DateTime updatedAt;
  int attemptCount = 0;
  DateTime? nextRetryAt;

  /// Sanitized error category only; never persist server bodies or tokens.
  String? lastErrorCode;
  DateTime? completedAt;
}
