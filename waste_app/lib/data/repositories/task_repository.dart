import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_task.dart';
import '../mappers/task_mapper.dart';
import 'chat_repository.dart';
import 'user_repository.dart';

/// Repository for managing volunteer delivery tasks in Firestore
class TaskRepository {
  TaskRepository({
    FirebaseFirestore? db,
    ChatRepository? chatRepo,
    UserRepository? userRepo,
  })  : _db = db ?? FirebaseFirestore.instance,
        _chatRepo = chatRepo ?? ChatRepository(),
        _userRepo = userRepo ?? UserRepository();

  final FirebaseFirestore _db;
  final ChatRepository _chatRepo;
  final UserRepository _userRepo;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _db.collection('tasks');

  /// Create a new delivery task
  Future<String> createTask(DeliveryTask task) async {
    final docRef = _tasks.doc();
    final newTask = task.copyWith(id: docRef.id);
    await docRef.set(TaskMapper.toFirestore(newTask));
    return docRef.id;
  }

  /// Accept a task (atomic transaction to prevent race conditions)
  /// Returns true if successful, false if task was already taken
  Future<bool> acceptTask(String taskId, String volunteerId) async {
    try {
      return await _db.runTransaction<bool>((transaction) async {
        final taskRef = _tasks.doc(taskId);
        final taskDoc = await transaction.get(taskRef);

        if (!taskDoc.exists) {
          throw Exception('Task not found');
        }

        final task = TaskMapper.fromFirestore(taskDoc.data()!);

        // Check if task is still open
        if (task.status != TaskStatus.open || task.volunteerId != null) {
          return false; // Task already taken
        }

        // Update task to accepted
        transaction.update(taskRef, {
          'volunteerId': volunteerId,
          'status': TaskStatus.accepted.name,
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        return true;
      }).then((success) async {
        if (success) {
          // After successful acceptance, create chat rooms
          final task = await getTask(taskId);
          if (task != null) {
            try {
              // Get Volunteer name
              final volunteerProfile = await _userRepo.getUserProfile(volunteerId);
              final volunteerName = volunteerProfile?['displayName'] ?? 'Volunteer';

              // Get Donor name
              final donorProfile = await _userRepo.getUserProfile(task.vendorId);
              final donorName = donorProfile?['displayName'] ?? donorProfile?['orgName'] ?? 'Donor';

              // Get NGO name
              final ngoProfile = await _userRepo.getUserProfile(task.ngoId);
              final ngoName = ngoProfile?['orgName'] ?? ngoProfile?['displayName'] ?? 'NGO';

              // Create chat rooms
              await _chatRepo.createChatsForTask(
                taskId: taskId,
                taskTitle: task.donationTitle,
                volunteerId: volunteerId,
                volunteerName: volunteerName,
                donorId: task.vendorId,
                donorName: donorName,
                ngoId: task.ngoId,
                ngoName: ngoName,
              );

              print('✅ Chat rooms created for task $taskId');
            } catch (e) {
              print('⚠️ Error creating chat rooms: $e');
              // Don't fail the task acceptance if chat creation fails
            }
          }
        }
        return success;
      });
    } catch (e) {
      print('Error accepting task: $e');
      return false;
    }
  }

  /// Complete a task
  Future<void> completeTask(String taskId) async {
    await _tasks.doc(taskId).update({
      'status': TaskStatus.completed.name, // or delivered, user schema has both. Using completed as final.
      'completedAt': FieldValue.serverTimestamp(),
      'deliveredAt': FieldValue.serverTimestamp(),
      'proof.deliveryCode': 'SIMULATED_DELIVERY_${DateTime.now().millisecondsSinceEpoch}',
      'proof.deliveryNote': 'Delivered successfully via Volunteer App',
    });

    // Also update the parent donation and request to completed
    final task = await getTask(taskId);
    if (task != null) {
      // Update donation status
      await _db.collection('donations').doc(task.donationId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update request status
      await _db.collection('requests').doc(task.requestId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Mark task as picked up (in transit)
  Future<void> markAsPickedUp(String taskId) async {
    await _tasks.doc(taskId).update({
      'status': TaskStatus.pickedUp.name,
      'pickedUpAt': FieldValue.serverTimestamp(),
      'proof.pickupCode': 'SIMULATED_PICKUP_${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  /// Release a task (unassign volunteer so it becomes open again)
  Future<void> releaseTask(String taskId) async {
    await _tasks.doc(taskId).update({
      'status': TaskStatus.open.name,
      'volunteerId': null,
      'acceptedAt': null,
      'pickedUpAt': null, // Reset if needed
      'proof': { // Reset proof
        'pickupCode': null,
        'deliveryCode': null,
        'deliveryNote': null,
        'pickupPhotos': [],
        'deliveryPhotos': [],
      },
    });

    // Delete associated chat rooms
    try {
      await _chatRepo.deleteChatsForTask(taskId);
      print('✅ Deleted chat rooms for cancelled task $taskId');
    } catch (e) {
      print('⚠️ Error deleting chat rooms: $e');
      // Don't fail the task release if chat deletion fails
    }
  }

  /// Cancel a task (permanently)
  Future<void> cancelTask(String taskId) async {
    await _tasks.doc(taskId).update({
      'status': TaskStatus.cancelled.name,
    });
  }

  /// Get a single task by ID
  Future<DeliveryTask?> getTask(String id) async {
    final doc = await _tasks.doc(id).get();
    if (!doc.exists) return null;
    return TaskMapper.fromDocumentSnapshot(doc.data());
  }

  /// Stream available tasks (open status) for volunteers
  Stream<List<DeliveryTask>> watchAvailableTasks() {
    return _tasks
        .where('status', isEqualTo: TaskStatus.open.name)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskMapper.fromFirestore(doc.data()))
          .toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Client-side sort desc
      return tasks;
    });
  }

  /// Stream volunteer's accepted tasks
  Stream<List<DeliveryTask>> watchVolunteerTasks(String volunteerId) {
    return _tasks
        .where('volunteerId', isEqualTo: volunteerId)
        .snapshots() // Removed orderBy to avoid index error
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskMapper.fromFirestore(doc.data()))
          .toList();
      // Client-side sort by acceptedAt desc
      tasks.sort((a, b) {
        if (a.acceptedAt == null) return -1;
        if (b.acceptedAt == null) return 1;
        return b.acceptedAt!.compareTo(a.acceptedAt!);
      });
      return tasks;
    });
  }

  /// Get volunteer statistics
  /// Returns map with: deliveriesCompleted, hoursVolunteered
  Future<Map<String, dynamic>> getVolunteerStats(String volunteerId) async {
    final snapshot = await _tasks
        .where('volunteerId', isEqualTo: volunteerId)
        .where('status', isEqualTo: TaskStatus.completed.name)
        .get();

    final tasks = snapshot.docs
        .map((doc) => TaskMapper.fromFirestore(doc.data()))
        .toList();

    // Calculate total hours (rough estimate: each delivery = 1 hour)
    // In production, would calculate from acceptedAt to completedAt
    int totalHours = 0;
    for (final task in tasks) {
      if (task.acceptedAt != null && task.completedAt != null) {
        final duration = task.completedAt!.difference(task.acceptedAt!);
        totalHours += duration.inHours;
      } else {
        // Fallback estimate
        totalHours += 1;
      }
    }

    return {
      'deliveriesCompleted': tasks.length,
      'hoursVolunteered': totalHours,
    };
  }

  /// Get all tasks (for admin purposes)
  Stream<List<DeliveryTask>> watchAllTasks() {
    return _tasks
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskMapper.fromFirestore(doc.data()))
          .toList();
    });
  }
}
