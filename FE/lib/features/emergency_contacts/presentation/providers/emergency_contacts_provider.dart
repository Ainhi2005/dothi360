import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/emergency_contacts_remote_datasource.dart';
import '../../data/models/emergency_contact_model.dart';

final emergencyContactsDataSourceProvider =
    Provider<EmergencyContactsRemoteDataSource>((ref) {
  return EmergencyContactsRemoteDataSource();
});

class EmergencyCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';

  void setCategory(String category) {
    state = category;
  }
}

final selectedEmergencyCategoryProvider =
    NotifierProvider<EmergencyCategoryNotifier, String>(
  EmergencyCategoryNotifier.new,
);

class EmergencySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final emergencySearchQueryProvider =
    NotifierProvider<EmergencySearchQueryNotifier, String>(
  EmergencySearchQueryNotifier.new,
);

class PinnedContactsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {'02438343355', '02438693731'};

  void toggle(String phoneNumber) {
    if (state.contains(phoneNumber)) {
      state = {...state}..remove(phoneNumber);
    } else {
      state = {...state, phoneNumber};
    }
  }

  bool isPinned(String phoneNumber) => state.contains(phoneNumber);
}

final pinnedContactsProvider =
    NotifierProvider<PinnedContactsNotifier, Set<String>>(
  PinnedContactsNotifier.new,
);

final emergencyContactsProvider =
    FutureProvider.autoDispose<List<EmergencyContactModel>>((ref) async {
  final dataSource = ref.watch(emergencyContactsDataSourceProvider);
  final category = ref.watch(selectedEmergencyCategoryProvider);
  final query = ref.watch(emergencySearchQueryProvider);

  return dataSource.getContacts(
    category: category,
    query: query,
  );
});
