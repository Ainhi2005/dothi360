import 'dart:io';
import 'package:latlong2/latlong.dart';

class CreateReportState {
  final File? image;
  final List<File> media;
  final LatLng? location;
  final String description;
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final Map<String, dynamic>? responseData;
  final String? address;
  final List<Map<String, dynamic>> incidentTypes;
  final String? incidentTypeId;
  final double uploadProgress;
  final Map<String, dynamic>? aiAnalysis;
  final List<Map<String, dynamic>> uploadedMedia;
  final bool isAnalyzing;
  final String analysisStage;
  final bool isAiConfirmed;
  final String locationSource;

  CreateReportState({
    this.image,
    this.media = const [],
    this.location,
    this.description = '',
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.responseData,
    this.address,
    this.incidentTypes = const [],
    this.incidentTypeId,
    this.uploadProgress = 0,
    this.aiAnalysis,
    this.uploadedMedia = const [],
    this.isAnalyzing = false,
    this.analysisStage = 'idle',
    this.isAiConfirmed = false,
    this.locationSource = 'GPS',
  });

  CreateReportState copyWith({
    File? image,
    bool clearImage = false,
    LatLng? location,
    String? description,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSuccess,
    Map<String, dynamic>? responseData,
    String? address,
    bool clearAddress = false,
    List<File>? media,
    List<Map<String, dynamic>>? incidentTypes,
    String? incidentTypeId,
    double? uploadProgress,
    Map<String, dynamic>? aiAnalysis,
    bool clearAiAnalysis = false,
    List<Map<String, dynamic>>? uploadedMedia,
    bool? isAnalyzing,
    String? analysisStage,
    bool? isAiConfirmed,
    String? locationSource,
  }) {
    return CreateReportState(
      image: clearImage ? null : (image ?? this.image),
      media: clearImage ? const [] : (media ?? this.media),
      location: location ?? this.location,
      description: description ?? this.description,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
      responseData: responseData ?? this.responseData,
      address: clearAddress ? null : (address ?? this.address),
      incidentTypes: incidentTypes ?? this.incidentTypes,
      incidentTypeId: incidentTypeId ?? this.incidentTypeId,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      aiAnalysis: clearAiAnalysis ? null : (aiAnalysis ?? this.aiAnalysis),
      uploadedMedia: uploadedMedia ?? this.uploadedMedia,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      analysisStage: analysisStage ?? this.analysisStage,
      isAiConfirmed: isAiConfirmed ?? this.isAiConfirmed,
      locationSource: locationSource ?? this.locationSource,
    );
  }
}
