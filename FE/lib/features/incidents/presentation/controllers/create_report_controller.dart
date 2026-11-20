import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';
import '../../data/datasources/incident_report_remote_datasource.dart';
import 'create_report_state.dart';
export 'create_report_state.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class CreateReportController extends Notifier<CreateReportState> {
  final _remote = IncidentReportRemoteDataSource();
  static const _draftKey = 'incident_draft';
  final _storage = const FlutterSecureStorage();
  @override
  CreateReportState build() {
    return CreateReportState();
  }

  void updateDescription(String text) {
    state = state.copyWith(
        description: text,
        clearError: true,
        clearAiAnalysis: true,
        isAiConfirmed: false,
        analysisStage: 'idle');
  }

  void selectIncidentType(String? id) =>
      state = state.copyWith(incidentTypeId: id, isAiConfirmed: false);

  void selectSeverity(int severity) {
    final analysis = Map<String, dynamic>.from(state.aiAnalysis ?? const {});
    analysis['confirmed_severity'] = severity;
    state = state.copyWith(aiAnalysis: analysis, isAiConfirmed: false);
  }

  void updateAnalysisReason(String reason) {
    final analysis = Map<String, dynamic>.from(state.aiAnalysis ?? const {});
    final originalReason = analysis['original_reason']?.toString() ??
        analysis['reason']?.toString() ??
        '';
    analysis['original_reason'] = originalReason;
    analysis['reason'] = reason.trim();
    analysis['user_edited_reason'] = originalReason.trim() != reason.trim();
    state = state.copyWith(aiAnalysis: analysis, isAiConfirmed: false);
  }

  void updateAnalysisRecommendation(String recommendation) {
    final analysis = Map<String, dynamic>.from(state.aiAnalysis ?? const {});
    analysis['recommended_action'] = recommendation;
    state = state.copyWith(aiAnalysis: analysis, isAiConfirmed: false);
  }

  void confirmAiReview() {
    if (state.aiAnalysis == null ||
        state.incidentTypeId == null ||
        state.aiAnalysis?['confirmed_severity'] == null) {
      state = state.copyWith(
          error: 'Vui lòng xác nhận loại và mức độ sự cố.',
          isAiConfirmed: false);
      return;
    }
    state = state.copyWith(isAiConfirmed: true, clearError: true);
  }

  Future<void> loadIncidentTypes() async {
    try {
      final types = await _remote.loadIncidentTypes();
      state = state.copyWith(incidentTypes: types);
    } catch (_) {}
  }

  Future<void> saveDraft() async {
    final documents = await getApplicationDocumentsDirectory();
    final draftDirectory =
        Directory('${documents.path}${Platform.pathSeparator}incident_drafts');
    await draftDirectory.create(recursive: true);
    final savedPaths = <String>[];
    for (var index = 0; index < state.media.length; index++) {
      final source = state.media[index];
      if (source.path.startsWith(draftDirectory.path)) {
        savedPaths.add(source.path);
        continue;
      }
      final extension =
          source.path.contains('.') ? '.${source.path.split('.').last}' : '';
      final destination =
          '${draftDirectory.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}_$index$extension';
      savedPaths.add((await source.copy(destination)).path);
    }
    await _storage.write(
        key: _draftKey,
        value: jsonEncode({
          'description': state.description,
          'latitude': state.location?.latitude,
          'longitude': state.location?.longitude,
          'address': state.address,
          'location_source': state.locationSource,
          'incident_type_id': state.incidentTypeId,
          'media_paths': savedPaths
        }));
    final files = savedPaths.map(File.new).toList();
    state =
        state.copyWith(media: files, image: files.isEmpty ? null : files.first);
  }

  Future<void> loadDraft() async {
    final raw = await _storage.read(key: _draftKey);
    if (raw == null) return;
    final d = jsonDecode(raw);
    final paths = List<String>.from(d['media_paths'] ?? [])
        .where((p) => File(p).existsSync())
        .map(File.new)
        .toList();
    state = state.copyWith(
        description: d['description'] ?? '',
        location: d['latitude'] != null
            ? LatLng(d['latitude'], d['longitude'])
            : null,
        incidentTypeId: d['incident_type_id'],
        address: d['address'],
        locationSource: d['location_source'] ?? 'GPS',
        media: paths,
        image: paths.isEmpty ? null : paths.first);
  }

  bool validateForReview() {
    if (state.media.isEmpty && state.image == null) {
      state = state.copyWith(error: 'Vui lòng chọn ảnh hiện trường.');
      return false;
    }
    if (state.location == null) {
      state = state.copyWith(error: 'Vui lòng chọn vị trí xảy ra sự cố.');
      return false;
    }
    if (state.description.trim().isEmpty) {
      state = state.copyWith(error: 'Vui lòng nhập mô tả sự cố.');
      return false;
    }
    if (state.description.trim().length < 3) {
      state = state.copyWith(error: 'Mô tả cần ít nhất 3 ký tự.');
      return false;
    }
    return true;
  }

  void reset() {
    state = CreateReportState();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      if (source == ImageSource.gallery) {
        final files = await picker.pickMultiImage(imageQuality: 80, limit: 5);
        if (files.isNotEmpty) {
          final newMedia = files.map((x) => File(x.path)).toList();
          final combined = [...state.media, ...newMedia].take(5).toList();
          state = state.copyWith(
              image: combined.first,
              media: combined,
              uploadedMedia: const [],
              clearAiAnalysis: true,
              isAiConfirmed: false,
              analysisStage: 'idle',
              clearError: true);
        }
      } else {
        final pickedFile =
            await picker.pickImage(source: source, imageQuality: 80);
        if (pickedFile != null) {
          final file = File(pickedFile.path);
          final combined = [...state.media, file].take(5).toList();
          state = state.copyWith(
              image: combined.first,
              media: combined,
              uploadedMedia: const [],
              clearAiAnalysis: true,
              isAiConfirmed: false,
              analysisStage: 'idle',
              clearError: true);
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Lỗi khi chọn ảnh: $e');
    }
  }

  void removeImage() {
    state = state.copyWith(
        clearImage: true,
        uploadedMedia: const [],
        clearAiAnalysis: true,
        isAiConfirmed: false,
        analysisStage: 'idle');
  }

  void removeMediaAt(int index) {
    final updated = [...state.media]..removeAt(index);
    state = state.copyWith(
      clearImage: updated.isEmpty,
      image: updated.isEmpty ? null : updated.first,
      media: updated,
      uploadedMedia: const [],
      clearError: true,
      clearAiAnalysis: true,
      isAiConfirmed: false,
      analysisStage: 'idle',
    );
  }

  Future<List<Map<String, dynamic>>> _ensureUploaded() async {
    if (state.uploadedMedia.isNotEmpty) return state.uploadedMedia;
    final files = state.media.isEmpty ? [state.image!] : state.media;
    final uploaded = <Map<String, dynamic>>[];
    var lastProgressPercent = -1;
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final uploadedMedia =
          await _remote.upload(file, onSendProgress: (sent, total) {
        if (total <= 0) return;
        final progress = ((i + sent / total) / files.length).clamp(0.0, 1.0);
        final percent = (progress * 100).floor();
        if (percent == lastProgressPercent) return;
        lastProgressPercent = percent;
        state = state.copyWith(
          uploadProgress: progress,
          analysisStage: 'uploading',
        );
      });
      uploaded.add(uploadedMedia);
    }
    state = state.copyWith(uploadedMedia: uploaded);
    return uploaded;
  }

  Future<bool> analyzeForReview() async {
    if (!validateForReview()) return false;
    state = state.copyWith(
        isAnalyzing: true,
        isLoading: true,
        isAiConfirmed: false,
        analysisStage: 'uploading',
        uploadProgress: 0,
        clearError: true);
    try {
      final uploaded = await _ensureUploaded();
      state = state.copyWith(analysisStage: 'analyzing');
      final analysis = await _remote.analyze(state.description, uploaded);
      final suggested = analysis['suggested_incident_type']?.toString();
      String? suggestedId;
      if (suggested != null) {
        for (final type in state.incidentTypes) {
          if (type['name']?.toString().toLowerCase() ==
              suggested.toLowerCase()) {
            suggestedId = type['id']?.toString();
            break;
          }
        }
      }
      analysis['confirmed_severity'] = analysis['suggested_severity'];
      state = state.copyWith(
          aiAnalysis: analysis,
          incidentTypeId: state.incidentTypeId ?? suggestedId,
          isAnalyzing: false,
          isLoading: false,
          analysisStage: 'ready');
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.response?.data?['message'] ?? e.message)
          : e.toString();
      state = state.copyWith(
          error: message?.toString() ?? 'Không thể phân tích ảnh',
          isAnalyzing: false,
          isLoading: false,
          analysisStage: 'failed');
      return false;
    }
  }

  void proceedWithManualFallback() {
    if (!validateForReview()) return;

    String? typeName;
    if (state.incidentTypeId != null) {
      for (final type in state.incidentTypes) {
        if (type['id']?.toString() == state.incidentTypeId) {
          typeName = type['name']?.toString();
          break;
        }
      }
    }

    final fallbackAnalysis = <String, dynamic>{
      'confidence': 0.0,
      'analysis_status': 'MANUAL_FALLBACK',
      'reason': 'Người dân tiếp tục bằng thông tin tự chọn và xác nhận.',
      'recommended_action':
          'Cán bộ sẽ trực tiếp kiểm tra và xác minh hiện trường.',
      'suggested_incident_type': typeName ?? 'Sự cố đô thị chung',
      'suggested_severity': 2,
      'confirmed_severity': 2,
      'risk_level': 'Trung bình',
      'suggested_sla_hours': 24,
      'requires_manual_review': true,
      'detected_signals': <String>[],
    };

    state = state.copyWith(
      aiAnalysis: fallbackAnalysis,
      incidentTypeId: state.incidentTypeId ??
          (state.incidentTypes.isNotEmpty
              ? state.incidentTypes.first['id']?.toString()
              : null),
      isAnalyzing: false,
      isLoading: false,
      analysisStage: 'ready',
      clearError: true,
    );
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Vui lòng bật GPS trên thiết bị.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Quyền truy cập vị trí bị từ chối.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Quyền truy cập vị trí bị từ chối vĩnh viễn.';
      }

      Position position = await Geolocator.getCurrentPosition();

      String? currentAddress;
      try {
        final geocoding = Geocoding();
        List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          currentAddress = [
            if (place.street != null && place.street!.isNotEmpty) place.street,
            if (place.subAdministrativeArea != null &&
                place.subAdministrativeArea!.isNotEmpty)
              place.subAdministrativeArea,
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty)
              place.administrativeArea,
          ].join(', ');
        }
      } catch (_) {}

      state = state.copyWith(
        location: LatLng(position.latitude, position.longitude),
        address: currentAddress,
        locationSource: 'GPS',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void setIncidentLocation({
    required LatLng location,
    required String source,
    String? address,
  }) {
    state = state.copyWith(
      location: location,
      address: address,
      clearAddress: address == null,
      locationSource: source,
      clearError: true,
    );
  }

  Future<void> submitReport() async {
    if (state.image == null) {
      state = state.copyWith(error: 'Vui lòng chọn ảnh hiện trường.');
      return;
    }
    if (state.location == null) {
      state = state.copyWith(error: 'Vui lòng chọn vị trí xảy ra sự cố.');
      return;
    }
    if (state.description.isEmpty) {
      state = state.copyWith(error: 'Vui lòng nhập mô tả sự cố.');
      return;
    }
    if (state.aiAnalysis == null || !state.isAiConfirmed) {
      state = state.copyWith(
          error: 'Bạn cần xem và xác nhận kết quả phân tích AI trước khi gửi.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    var uploadedMedia = <Map<String, dynamic>>[];

    try {
      uploadedMedia = await _ensureUploaded();

      // 2. Tạo sự cố
      final data = {
        "description": state.description,
        "longitude": state.location!.longitude,
        "latitude": state.location!.latitude,
        "reported_address": state.address,
        "location_source": state.locationSource,
        "media_urls": uploadedMedia,
        if (state.incidentTypeId != null)
          "incident_type_id": state.incidentTypeId,
        if (state.aiAnalysis?['confirmed_severity'] != null)
          "reported_severity": state.aiAnalysis!['confirmed_severity'],
        if (state.aiAnalysis != null) "ai_analysis": state.aiAnalysis,
        "ai_confirmation": {
          "accepted": true,
          "suggested_incident_type":
              state.aiAnalysis?['suggested_incident_type'],
          "suggested_severity": state.aiAnalysis?['suggested_severity'],
          "confirmed_incident_type_id": state.incidentTypeId,
          "confirmed_severity": state.aiAnalysis?['confirmed_severity'],
          "suggested_summary": state.aiAnalysis?['original_reason'] ??
              state.aiAnalysis?['reason'],
          "confirmed_summary": state.aiAnalysis?['reason'],
          "summary_edited": state.aiAnalysis?['user_edited_reason'] == true,
          "confirmed_at": DateTime.now().toUtc().toIso8601String(),
        },
      };

      final result = await _remote.submit(data);
      {
        if (result['media_attached'] == false) {
          for (final media in uploadedMedia) {
            try {
              await _remote.deleteUpload(media);
            } catch (_) {}
          }
          uploadedMedia.clear();
        }
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          responseData: result,
        );
        await _storage.delete(key: _draftKey);
      }
    } catch (e) {
      for (final media in uploadedMedia) {
        try {
          await _remote.deleteUpload(media);
        } catch (_) {}
      }
      try {
        await saveDraft();
      } catch (_) {}
      String errMsg = 'Lỗi hệ thống';
      if (e is DioException) {
        errMsg = e.response?.data['message'] ?? e.message ?? 'Lỗi kết nối';
      } else {
        errMsg = e.toString();
      }
      state = state.copyWith(isLoading: false, error: errMsg);
    }
  }
}

final createReportProvider =
    NotifierProvider<CreateReportController, CreateReportState>(
  () => CreateReportController(),
);
