import 'dart:io';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/network/supabase/database/add_data.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'add_material_state.dart';

class AddMaterialCubit extends Cubit<AddMaterialState> {
  AddMaterialCubit() : super(AddMaterialInitial());

  final formKey = GlobalKey<FormState>();
  final materialNameController = TextEditingController();
  final materialDescriptionController = TextEditingController();
  final folderNameController = TextEditingController(); 
  final linkController = TextEditingController(); 

  String? subjectId;
  List<SubjectModel> subjects = [];
  File? selectedFile;
  String? selectedFileName;
  bool isLink = false; 
  String materialType = "Lecture";

  final _supabase = getIt<SupabaseClient>();

  void setMaterialType(String type) {
    materialType = type;
    emit(AddMaterialInitial());
  }

  void toggleIsLink(bool value) {
    isLink = value;
    emit(AddMaterialInitial());
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        selectedFile = File(result.files.single.path!);
        selectedFileName = result.files.single.name;
        emit(FileSelected());
      }
    } catch (e) {
      emit(AddMaterialError(message: 'Error picking file: $e'));
    }
  }

  void clearFile() {
    selectedFile = null;
    selectedFileName = null;
    emit(FileCleared());
  }

  Future<void> addMaterial() async {
    if (formKey.currentState!.validate()) {
      if (subjectId == null) {
        emit(AddMaterialError(message: 'Critical error: Subject not identified'));
        return;
      }
      
      if (!isLink && selectedFile == null) {
        emit(AddMaterialError(message: 'Please select a document to upload'));
        return;
      }

      if (isLink && linkController.text.isEmpty) {
        emit(AddMaterialError(message: 'Please enter a valid URL link'));
        return;
      }

      try {
        emit(AddMaterialLoading());
        final userId = _supabase.auth.currentUser!.id;
        String finalUrl = "";
        String finalTitle = "";

        if (isLink) {
          finalUrl = linkController.text;
          finalTitle = "${folderNameController.text.isEmpty ? "Resource" : folderNameController.text} ($materialType)";
        } else {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileExt = selectedFileName!.split('.').last;
          final fileName = '$userId/$subjectId/$timestamp.$fileExt';
          
          final bytes = await selectedFile!.readAsBytes();
          
          await _supabase.storage.from('materials').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: _getContentType(fileExt),
            ),
          );
          
          finalUrl = _supabase.storage.from('materials').getPublicUrl(fileName);
          finalTitle = selectedFileName!;
        }

        await addData(
          tableName: "materials",
          data: {
            "title": finalTitle,
            "description": materialDescriptionController.text,
            "file_url": finalUrl,
            "subject_id": subjectId,
            "uploaded_by": userId,
            "folder_name": folderNameController.text.isEmpty ? "General" : folderNameController.text,
            "is_link": isLink,
            "material_type": materialType,
            "created_at": DateTime.now().toIso8601String(),
          },
        );
        
        materialNameController.clear();
        materialDescriptionController.clear();
        folderNameController.clear();
        linkController.clear();
        clearFile();
        
        emit(AddMaterialSuccess());
      } catch (e) {
        emit(AddMaterialError(message: 'Publish failed: check your connection or database schema'));
        log("Upload error: $e");
      }
    }
  }

  String _getContentType(String fileExt) {
    switch (fileExt.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'doc':
      case 'docx': return 'application/msword';
      case 'ppt':
      case 'pptx': return 'application/vnd.ms-powerpoint';
      case 'xls':
      case 'xlsx': return 'application/vnd.ms-excel';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }

  @override
  Future<void> close() {
    materialNameController.dispose();
    materialDescriptionController.dispose();
    folderNameController.dispose();
    linkController.dispose();
    return super.close();
  }
}
