import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';

class AttachmentPreview extends StatelessWidget {
  final File? image;
  final File? file;
  final VoidCallback? onRemoveImage;
  final VoidCallback? onRemoveFile;

  const AttachmentPreview({super.key, 
    this.image,
    this.file,
    this.onRemoveImage,
    this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return (image != null || file != null)
        ? Container(
            margin: EdgeInsets.only(bottom: SizeConfig.height * 0.02),
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.width * 0.03,
              vertical: SizeConfig.height * 0.01,
            ),
            decoration: BoxDecoration(
              color: AppColors.kPrimaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      image!,
                      width: SizeConfig.width * 0.2,
                      height: SizeConfig.height * 0.1,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (file != null)
                  Container(
                      width: SizeConfig.width * 0.2,
                      height: SizeConfig.height * 0.1,
                    decoration: BoxDecoration(
                      color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.insert_drive_file_rounded,
                      color: AppColors.kPrimaryColor,
                    ),
                  ),

                SizedBox(width: SizeConfig.width * 0.02),
                Expanded(
                  child: Text(
                    image != null
                        ? 'Image selected'
                        : file != null
                        ? file!.path.split('/').last
                        : '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title14BlackW600,
                  ),
                ),
                if (image != null)
                  IconButton(
                    onPressed: onRemoveImage,
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.redAccent,
                  ),
                if (file != null)
                  IconButton(
                    onPressed: onRemoveFile,
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.redAccent,
                  ),
              ],
            ),
          )
        : const SizedBox();
  }
}
