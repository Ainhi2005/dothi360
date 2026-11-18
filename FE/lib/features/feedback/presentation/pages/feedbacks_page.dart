import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/feedback_provider.dart';
import '../widgets/feedback_card.dart';
import '../widgets/feedback_empty_state.dart';
import '../widgets/feedback_filter_bar.dart';

class FeedbacksPage extends ConsumerStatefulWidget {
  const FeedbacksPage({super.key});

  @override
  ConsumerState<FeedbacksPage> createState() => _FeedbacksPageState();
}

class _FeedbacksPageState extends ConsumerState<FeedbacksPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final communityState = ref.watch(communityFeedbacksProvider);
    final myState = ref.watch(myFeedbacksProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hiến kế & Góp ý'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Cộng đồng'),
            Tab(text: 'Của tôi'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>(AppRoutes.createFeedback);
          if (created == true) {
            ref.read(communityFeedbacksProvider.notifier).refresh();
            ref.read(myFeedbacksProvider.notifier).refresh();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: Text(
          'Gửi hiến kế',
          style: AppTextStyles.buttonText.copyWith(color: Colors.white),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Cộng đồng
          Column(
            children: [
              const SizedBox(height: AppDimens.spacingSm),
              FeedbackFilterBar(
                selectedCategory: selectedCategory,
                onSelectCategory: (cat) {
                  ref.read(selectedCategoryProvider.notifier).setCategory(cat);
                },
              ),
              const SizedBox(height: AppDimens.spacingSm),
              Expanded(
                child: communityState.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Không thể tải danh sách: $e'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref
                              .read(communityFeedbacksProvider.notifier)
                              .refresh(),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const FeedbackEmptyState(
                        message: 'Chưa có góp ý nào trong danh mục này.\nHãy là người đầu tiên gửi sáng kiến!',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(communityFeedbacksProvider.notifier)
                          .refresh(),
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.spacingBase,
                          AppDimens.spacingSm,
                          AppDimens.spacingBase,
                          90,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return FeedbackCard(
                            feedback: item,
                            onToggleUpvote: () => ref
                                .read(communityFeedbacksProvider.notifier)
                                .toggleUpvote(item.id),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Tab 2: Của tôi
          myState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: TextButton(
                onPressed: () =>
                    ref.read(myFeedbacksProvider.notifier).refresh(),
                child: const Text('Tải lại'),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return FeedbackEmptyState(
                  message: 'Bạn chưa gửi hiến kế hoặc góp ý nào.',
                  actionLabel: 'Gửi hiến kế đầu tiên',
                  onAction: () async {
                    final created =
                        await context.push<bool>(AppRoutes.createFeedback);
                    if (created == true) {
                      ref.read(communityFeedbacksProvider.notifier).refresh();
                      ref.read(myFeedbacksProvider.notifier).refresh();
                    }
                  },
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(myFeedbacksProvider.notifier).refresh(),
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.spacingBase,
                    AppDimens.spacingBase,
                    AppDimens.spacingBase,
                    90,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return FeedbackCard(
                      feedback: item,
                      onToggleUpvote: () {},
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

