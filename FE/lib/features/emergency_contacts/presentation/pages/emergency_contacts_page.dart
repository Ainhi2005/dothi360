import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/emergency_contact_model.dart';
import '../providers/emergency_contacts_provider.dart';
import '../widgets/emergency_call_sheet.dart';
import '../widgets/emergency_contact_group.dart';
import '../widgets/emergency_contacts_header.dart';
import '../widgets/emergency_national_hotlines.dart';
import '../widgets/emergency_scroll_down_button.dart';
import '../widgets/emergency_search_bar.dart';

const Map<String, String> _categoryTitles = {
  'INFRASTRUCTURE': 'SỰ CỐ HẠ TẦNG ĐÔ THỊ',
  'TRAFFIC': 'GIAO THÔNG & TRẬT TỰ',
  'MEDICAL': 'Y TẾ DỰ PHÒNG & CẤP CỨU',
  'SECURITY': 'AN NINH & TRẬT TỰ',
  'RESCUE': 'TÌM KIẾM CỨU NẠN',
};

const List<String> _categoryDisplayOrder = [
  'INFRASTRUCTURE',
  'TRAFFIC',
  'MEDICAL',
  'SECURITY',
  'RESCUE',
];

class EmergencyContactsPage extends ConsumerStatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  ConsumerState<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends ConsumerState<EmergencyContactsPage> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onCallContact(EmergencyContactModel contact) {
    EmergencyCallSheet.show(context, contact);
  }

  void _scrollDown() {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + 320).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(emergencyContactsProvider);
    final pinned = ref.watch(pinnedContactsProvider);
    final searchQuery = ref.watch(emergencySearchQueryProvider).trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.refresh(emergencyContactsProvider.future),
              child: contactsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: AppDimens.spacingSm),
                      Text('Không thể tải danh bạ khẩn cấp', style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppDimens.spacingMd),
                      FilledButton(
                        onPressed: () => ref.refresh(emergencyContactsProvider),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
                data: (allContacts) {
                  final isSearching = searchQuery.isNotEmpty;
                  final hotlines = allContacts.where((c) => c.isHotline && c.category == 'NATIONAL').toList();
                  final pinnedContacts = allContacts.where((c) => pinned.contains(c.phoneNumber)).toList();

                  final Map<String, List<EmergencyContactModel>> grouped = {};
                  for (final cat in _categoryDisplayOrder) {
                    grouped[cat] = [];
                  }
                  for (final contact in allContacts) {
                    if (!isSearching && contact.isHotline && contact.category == 'NATIONAL') {
                      continue; // Handled in top national hotline grid
                    }
                    if (grouped.containsKey(contact.category)) {
                      grouped[contact.category]!.add(contact);
                    } else {
                      grouped.putIfAbsent(contact.category, () => []).add(contact);
                    }
                  }

                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.spacingMd,
                      AppDimens.spacingXs,
                      AppDimens.spacingMd,
                      80,
                    ),
                    children: [
                      const EmergencyContactsHeader(),
                      EmergencySearchBar(
                        controller: _searchController,
                        onChanged: (val) => ref.read(emergencySearchQueryProvider.notifier).setQuery(val),
                        onClear: () {
                          _searchController.clear();
                          ref.read(emergencySearchQueryProvider.notifier).setQuery('');
                        },
                      ),
                      const SizedBox(height: AppDimens.spacingMd),
                      if (!isSearching && hotlines.isNotEmpty) ...[
                        EmergencyNationalHotlines(
                          hotlines: hotlines,
                          onContactTap: _onCallContact,
                        ),
                        const SizedBox(height: AppDimens.spacingLg),
                      ],
                      if (!isSearching && pinnedContacts.isNotEmpty) ...[
                        EmergencyContactGroup(
                          title: 'ĐÃ GHIM ƯU TIÊN',
                          titleIcon: const Icon(Icons.star_rounded, size: 16, color: AppColors.starGold),
                          contacts: pinnedContacts,
                          pinnedPhoneNumbers: pinned,
                          isPinnedSection: true,
                          onStarToggle: (p) => ref.read(pinnedContactsProvider.notifier).toggle(p),
                          onCall: _onCallContact,
                        ),
                        const SizedBox(height: AppDimens.spacingLg),
                      ],
                      if (allContacts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppDimens.spacingXl),
                          child: Center(
                            child: Text('Không có liên hệ phù hợp', style: AppTextStyles.bodyMedium),
                          ),
                        )
                      else ...[
                        for (final entry in grouped.entries)
                          if (entry.value.isNotEmpty) ...[
                            EmergencyContactGroup(
                              title: _categoryTitles[entry.key] ?? entry.key,
                              contacts: entry.value,
                              pinnedPhoneNumbers: pinned,
                              onStarToggle: (p) => ref.read(pinnedContactsProvider.notifier).toggle(p),
                              onCall: _onCallContact,
                            ),
                            const SizedBox(height: AppDimens.spacingLg),
                          ],
                      ],
                    ],
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: EmergencyScrollDownButton(
                onPressed: _scrollDown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
