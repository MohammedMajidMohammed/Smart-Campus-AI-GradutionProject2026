import 'dart:io';

void main() {
  final targetDir = Directory(r'd:\My_Edit_Project\Smart-Canvas001\lib');
  if (!targetDir.existsSync()) {
    print('Directory does not exist: ${targetDir.path}');
    return;
  }

  final replacements = {
    // Upper case hex codes
    '0xFFD4AF37': '0xFF1E8449', // Primary Gold -> Primary Lighter Emerald Green
    '0xFFB88E1F': '0xFF145A32', // Deep Gold -> Deep Forest Green
    '0xFFF3C63F': '0xFF2ECC71', // Bright Gold -> Vibrant Light Green
    '0xFFE5B83B': '0xFF27AE60', // Golden Orange -> Nephrite Green
    '0xFFC5A028': '0xFF196F3D', // Medium Gold -> Medium Dark Green
    '0xFFC59B27': '0xFF196F3D',
    '0xFF6F5303': '0xFF0E6251', // Dark Golden -> Dark Teal Green
    '0xFF7D5F04': '0xFF117A65', // Teal/Olive Gold -> Teal Green
    '0xFF8F6D05': '0xFF0E6251',
    '0xFFFDEBB7': '0xFFD5F5E3', // Gold Glow -> Mint Light Green Glow
    '0xFFE6C280': '0xFFA9DFBF', // Light Sandy Gold -> Soft Sage/Pastel Green
    '0xFFFFFDF5': '0xFFF4FBF7', // Off-white gold tint -> Soft off-white green tint

    // Lower case hex codes just in case
    '0xffd4af37': '0xff1e8449',
    '0xffb88e1f': '0xff145a32',
    '0xfff3c63f': '0xff2ecc71',
    '0xffe5b83b': '0xff27ae60',
    '0xffc5a028': '0xff196f3d',
    '0xffc59b27': '0xff196f3d',
    '0xff6f5303': '0xff0e6251',
    '0xff7d5f04': '0xff117a65',
    '0xff8f6d05': '0xff0e6251',
    '0xfffdebb7': '0xffd5f5e3',
    '0xffe6c280': '0xffa9dfbf',
    '0xfffffdf5': '0xfff4fbf7',
  };

  int modifiedFilesCount = 0;

  final files = targetDir.listSync(recursive: true);
  for (final entity in files) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      var newContent = content;
      bool changed = false;

      replacements.forEach((oldVal, newVal) {
        if (newContent.contains(oldVal)) {
          newContent = newContent.replaceAll(oldVal, newVal);
          changed = true;
        }
      });

      if (changed) {
        entity.writeAsStringSync(newContent);
        print('Updated: ${entity.path}');
        modifiedFilesCount++;
      }
    }
  }

  print('Migration completed! Total modified files: $modifiedFilesCount');
}
