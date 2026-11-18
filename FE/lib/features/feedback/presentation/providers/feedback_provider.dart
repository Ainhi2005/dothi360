import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/feedback_remote_datasource.dart';
import '../../data/models/citizen_feedback_model.dart';

final feedbackDataSourceProvider = Provider<FeedbackRemoteDataSource>((ref) {
  return FeedbackRemoteDataSource();
});

class FeedbackCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';

  void setCategory(String category) {
    state = category;
  }
}

final selectedCategoryProvider =
    NotifierProvider<FeedbackCategoryNotifier, String>(
  FeedbackCategoryNotifier.new,
);

final communityFeedbacksProvider =
    AsyncNotifierProvider<CommunityFeedbacksNotifier, List<CitizenFeedbackModel>>(
  CommunityFeedbacksNotifier.new,
);

class CommunityFeedbacksNotifier extends AsyncNotifier<List<CitizenFeedbackModel>> {
  @override
  Future<List<CitizenFeedbackModel>> build() async {
    final category = ref.watch(selectedCategoryProvider);
    return ref.read(feedbackDataSourceProvider).list(category: category);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final category = ref.read(selectedCategoryProvider);
      return ref.read(feedbackDataSourceProvider).list(category: category);
    });
  }

  Future<void> toggleUpvote(String id) async {
    final currentList = state.value ?? <CitizenFeedbackModel>[];
    final targetIndex = currentList.indexWhere((x) => x.id == id);
    if (targetIndex < 0) return;

    final item = currentList[targetIndex];
    final optimisticUpvoted = !item.isUpvoted;
    final optimisticUpvotes =
        optimisticUpvoted ? item.upvotes + 1 : (item.upvotes > 0 ? item.upvotes - 1 : 0);

    final List<CitizenFeedbackModel> updated =
        List<CitizenFeedbackModel>.from(currentList);
    updated[targetIndex] = item.copyWith(
      isUpvoted: optimisticUpvoted,
      upvotes: optimisticUpvotes,
    );
    state = AsyncData(updated);

    try {
      final result = await ref.read(feedbackDataSourceProvider).toggleUpvote(id);
      final confirmedUpvoted = result['is_upvoted'] == true;
      final confirmedUpvotes =
          int.tryParse(result['upvotes'].toString()) ?? optimisticUpvotes;

      final List<CitizenFeedbackModel> confirmedList =
          List<CitizenFeedbackModel>.from(state.value ?? <CitizenFeedbackModel>[]);
      final idx = confirmedList.indexWhere((x) => x.id == id);
      if (idx >= 0) {
        confirmedList[idx] = confirmedList[idx].copyWith(
          isUpvoted: confirmedUpvoted,
          upvotes: confirmedUpvotes,
        );
        state = AsyncData(confirmedList);
      }
    } catch (_) {
      state = AsyncData(currentList);
    }
  }
}

final myFeedbacksProvider =
    AsyncNotifierProvider<MyFeedbacksNotifier, List<CitizenFeedbackModel>>(
  MyFeedbacksNotifier.new,
);

class MyFeedbacksNotifier extends AsyncNotifier<List<CitizenFeedbackModel>> {
  @override
  Future<List<CitizenFeedbackModel>> build() async {
    return ref.read(feedbackDataSourceProvider).getMine();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(feedbackDataSourceProvider).getMine();
    });
  }
}
