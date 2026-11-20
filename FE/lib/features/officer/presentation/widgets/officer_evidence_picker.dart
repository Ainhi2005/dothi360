import 'package:flutter/material.dart';
import '../../../../core/theme/app_dimens.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'officer_evidence_thumbnail.dart';

class OfficerEvidencePicker extends StatelessWidget {
  const OfficerEvidencePicker(
      {required this.evidence, required this.onChanged, super.key});
  final List<File> evidence;
  final ValueChanged<List<File>> onChanged;
  @override
  Widget build(BuildContext context) => Column(children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: evidence.length >= 5
                    ? null
                    : () async {
                        final image = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (image != null && context.mounted) {
                          onChanged([...evidence, File(image.path)]);
                        }
                      },
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Chụp ảnh'),
              ),
            ),
            const SizedBox(width: AppDimens.spacingSm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: evidence.length >= 5
                    ? null
                    : () async {
                        final images = await ImagePicker().pickMultiImage(
                          imageQuality: 80,
                          limit: 5 - evidence.length,
                        );
                        if (images.isNotEmpty && context.mounted) {
                          onChanged([
                            ...evidence,
                            ...images.map((image) => File(image.path))
                          ]);
                        }
                      },
                icon: const Icon(Icons.photo_library_outlined),
                label: Text('Thư viện (${evidence.length}/5)'),
              ),
            ),
          ],
        ),
        if (evidence.isNotEmpty) ...[
          const SizedBox(height: AppDimens.spacingMd),
          Wrap(
            spacing: AppDimens.spacingSm,
            runSpacing: AppDimens.spacingSm,
            children: evidence
                .map((file) => OfficerEvidenceThumbnail(
                    file: file,
                    onRemove: () => onChanged([...evidence]..remove(file))))
                .toList(),
          ),
        ],
      ]);
}
