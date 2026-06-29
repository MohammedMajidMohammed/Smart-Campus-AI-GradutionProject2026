import 'dart:developer';
import 'dart:io';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

Future<String?> uploadFileToSupabaseStorage({required File file, required String pucketName}) async {
  try {
    final extension = file.path.split('.').last;
    String fileName = "${const Uuid().v4()}.$extension";
    log("Attempting upload to bucket: $pucketName, File: $fileName");
    
    final response = await getIt<SupabaseClient>().storage.from(pucketName).upload(fileName, file);
    log("Upload response: $response");
    
    final url = getIt<SupabaseClient>()
        .storage
        .from(pucketName)
        .getPublicUrl(fileName);
        
    log("Generated Public URL: $url");
    return url;
  } catch (e) {
    log("ERROR in uploadFileToSupabaseStorage: $e");
    rethrow;
  }
}
