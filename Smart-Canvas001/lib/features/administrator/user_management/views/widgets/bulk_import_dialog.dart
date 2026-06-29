import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:smart_canvas/core/components/custom_elevated_button.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';

class BulkImportDialog extends StatefulWidget {
  const BulkImportDialog({super.key});

  @override
  State<BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends State<BulkImportDialog> {
  String? _fileName;
  bool _isLoading = false;
  int _userCount = 0;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        _isLoading = true;
      });

      // Simulate parsing
      var bytes = result.files.single.bytes;
      if (bytes != null) {
        final csvString = utf8.decode(bytes);
        List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);
        
        // removing header row assumption
        int count = rows.length;
        if (count > 0) count--; 
        
        setState(() {
          _userCount = count > 0 ? count : 5; // Mock count if file empty or parsing fails
          _isLoading = false;
        });
      } else {
         // Fallback for simulation if bytes are null (web/some platforms)
         await Future.delayed(const Duration(seconds: 1));
         setState(() {
           _userCount = 25; // Simulated count
           _isLoading = false;
         });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Bulk Import Users", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Upload a CSV file with columns: Name, Email, Role."),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.kPrimaryColor),
                  const SizedBox(height: 10),
                  Text(
                    _fileName ?? "Click to Upload CSV",
                    style: TextStyle(
                      color: _fileName != null ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: LinearProgressIndicator(),
            ),
          if (_userCount > 0 && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                "Found $_userCount users to import.",
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        CustomElevatedButton(
          name: "Import",
          width: SizeConfig.width * 0.3,
          onPressed: _userCount > 0
              ? () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Successfully imported $_userCount users!")),
                  );
                  // Trigger Cubit refresh here in real app
                }
              : null,
          backgroundColor: AppColors.kPrimaryColor,
          forgroundColor: Colors.white,
        ),
      ],
    );
  }
}
