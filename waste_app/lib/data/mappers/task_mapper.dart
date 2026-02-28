import '../models/delivery_task.dart';

/// Mapper for converting between DeliveryTask objects and Firestore documents
class TaskMapper {
  /// Convert Firestore document to DeliveryTask object
  static DeliveryTask fromFirestore(Map<String, dynamic> data) {
    return DeliveryTask.fromJson(data);
  }

  /// Convert DeliveryTask object to Firestore document
  static Map<String, dynamic> toFirestore(DeliveryTask task) {
    return task.toJson();
  }

  /// Convert Firestore document snapshot to DeliveryTask object
  /// Returns null if document doesn't exist
  static DeliveryTask? fromDocumentSnapshot(Map<String, dynamic>? data) {
    if (data == null) return null;
    return fromFirestore(data);
  }
}
