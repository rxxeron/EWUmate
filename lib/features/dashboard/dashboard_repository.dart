import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DashboardRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<Map<String, dynamic>> getScheduleStream(String semesterCode) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    final scheduleStream = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('schedule')
        .doc(semesterCode)
        .snapshots();

    final exceptionsStream = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('schedule_exceptions')
        .snapshots();

    // Combine streams manually using RX-like generic merge or StreamBuilder logic in UI?
    // Easier to do it here to keep UI clean.
    return DataMerger.combine(scheduleStream, exceptionsStream);
  }
}

class DataMerger {
  static Stream<Map<String, dynamic>> combine(
      Stream<DocumentSnapshot> scheduleStr,
      Stream<QuerySnapshot> exceptionsStr) {
    return StreamBuilderLike.combine2(scheduleStr, exceptionsStr, (sched, ex) {
      final data = sched.data() as Map<String, dynamic>? ?? {};
      final exceptions =
          ex.docs.map((d) => d.data() as Map<String, dynamic>).toList();

      // Merge exceptions into the 'exceptions' field expected by DashboardLogic
      // Existing data['exceptions'] might exist from cloud, we append/overwrite
      final cloudEx = (data['exceptions'] as List<dynamic>?) ?? [];

      // We want to use the local exceptions collection primarily for user actions
      // So we merge: [...cloudExceptions, ...userExceptions]
      // DashboardLogic handles this list.

      final Map<String, dynamic> merged = Map.from(data);
      merged['exceptions'] = [...cloudEx, ...exceptions];

      return merged;
    });
  }
}

// Simple helper to combine two streams without rxdart
class StreamBuilderLike {
  static Stream<T> combine2<A, B, T>(
      Stream<A> streamA, Stream<B> streamB, T Function(A, B) combiner) {
    // ignore: close_sinks
    final controller = StreamController<T>();
    A? lastA;
    B? lastB;
    bool hasA = false;
    bool hasB = false;

    void update() {
      if (hasA && hasB) {
        try {
          controller.add(combiner(lastA as A, lastB as B));
        } catch (e) {
          controller.addError(e);
        }
      }
    }

    final subA = streamA.listen(
        (data) {
          lastA = data;
          hasA = true;
          update();
        },
        onError: controller.addError,
        onDone: () {
          if (!controller.isClosed) controller.close();
        } // Naive close
        );

    final subB = streamB.listen(
        (data) {
          lastB = data;
          hasB = true;
          update();
        },
        onError: controller.addError,
        onDone: () {
          if (!controller.isClosed) controller.close();
        });

    controller.onCancel = () {
      subA.cancel();
      subB.cancel();
    };

    return controller.stream;
  }
}
