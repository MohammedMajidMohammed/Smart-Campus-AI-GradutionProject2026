import 'dart:io';
import 'package:image_picker/image_picker.dart';

Future<File?> pickImage({required ImageSource source}) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);
  if (pickedFile != null) {
    return File(pickedFile.path);
  }
  return null;
}
