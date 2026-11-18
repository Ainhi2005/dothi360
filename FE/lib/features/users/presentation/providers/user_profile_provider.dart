import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/models/user_profile_model.dart';

final userRemoteDataSourceProvider =
    Provider<UserRemoteDataSource>((ref) => UserRemoteDataSource());

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfileModel>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends AsyncNotifier<UserProfileModel> {
  @override
  Future<UserProfileModel> build() =>
      ref.read(userRemoteDataSourceProvider).getProfile();

  Future<bool> updateProfile(
      {required String fullName, required String phone}) async {
    state = const AsyncLoading();
    try {
      final profile =
          await ref.read(userRemoteDataSourceProvider).updateProfile(
                fullName: fullName,
                phone: phone,
              );
      state = AsyncData(profile);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
