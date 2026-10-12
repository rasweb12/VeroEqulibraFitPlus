import 'package:isar/isar.dart';

part 'pending_operation.g.dart';

@collection
class PendingOperation {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('idempotencyKey')], unique: true)
  late String ownerId;

  late String idempotencyKey;
  late String operationType;
  late String payloadJson;
  late DateTime createdAt;
  DateTime? completedAt;
}
