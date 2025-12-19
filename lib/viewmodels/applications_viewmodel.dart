import 'package:flutter/foundation.dart';

import '../models/application.dart';
import '../services/firestore_service.dart';
import '../utils/enums.dart';

class ApplicationsViewModel extends ChangeNotifier {
  ApplicationsViewModel(this._firestore);

  final FirestoreService _firestore;

  String search = '';
  AppStatus? statusFilter;
  Priority? priorityFilter;

  bool kanbanMode = false;

  Stream<List<Application>> watchApps(String uid) {
    return _firestore.watchApplications(uid);
  }

  void setSearch(String v) {
    search = v.trim().toLowerCase();
    notifyListeners();
  }

  void toggleMode() {
    kanbanMode = !kanbanMode;
    notifyListeners();
  }

  void setStatusFilter(AppStatus? s) {
    statusFilter = s;
    notifyListeners();
  }

  void setPriorityFilter(Priority? p) {
    priorityFilter = p;
    notifyListeners();
  }

  List<Application> applyFilters(List<Application> apps) {
    Iterable<Application> out = apps;

    if (search.isNotEmpty) {
      out = out.where((a) =>
      a.companyName.toLowerCase().contains(search) ||
          a.roleTitle.toLowerCase().contains(search));
    }
    if (statusFilter != null) {
      out = out.where((a) => a.status == statusFilter);
    }
    if (priorityFilter != null) {
      out = out.where((a) => a.priority == priorityFilter);
    }

    return out.toList();
  }

  Future<void> deleteApp(String appId) async {
    await _firestore.deleteApplication(appId: appId, cascadeDelete: true);
  }

  Future<String> createApp(Application a) => _firestore.createApplication(a);

  Future<void> updateApp(Application a) => _firestore.updateApplication(a);
}
