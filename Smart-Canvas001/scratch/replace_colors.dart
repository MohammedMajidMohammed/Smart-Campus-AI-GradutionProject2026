import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('Error: lib directory not found.');
    return;
  }

  final mappings = {
    // Primary Green -> Primary Gold (Menoufia Gold)
    '0xFF1B7A43': '0xFFD4AF37',
    '0xff1b7a43': '0xffd4af37',

    // Deep Green -> Deep Gold
    '0xFF0F4E27': '0xFFB88E1F',
    '0xff0f4e27': '0xffb88e1f',

    // Bright Green -> Bright Gold
    '0xFF3CA86A': '0xFFF3C63F',
    '0xff3ca86a': '0xfff3c63f',

    // Other shades of green -> corresponding shades of gold
    '0xFF0D5F36': '0xFF8F6D05',
    '0xff0d5f36': '0xff8f6d05',
    
    '0xFF0A3D1F': '0xFF6F5303',
    '0xff0a3d1f': '0xff6f5303',

    '0xFF0D3E26': '0xFF6F5303',
    '0xff0d3e26': '0xff6f5303',

    '0xFF114F30': '0xFF7D5F04',
    '0xff114f30': '0xff7d5f04',

    '0xFF1F8E52': '0xFFE5B83B',
    '0xff1f8e52': '0xffe5b83b',

    '0xFF0A3D1F': '0xFF6F5303',
    '0xff0a3d1f': '0xff6f5303',
  };

  int modifiedFilesCount = 0;

  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      bool modified = false;

      // Special handling for AppColors class declaration to swap or set secondary to green
      if (entity.path.endsWith('app_colors.dart')) {
        // First swap kSecondaryColor to green (since it was gold)
        if (content.contains('static const Color kSecondaryColor = Color(0xFFD4AF37);')) {
          content = content.replaceAll(
            'static const Color kSecondaryColor = Color(0xFFD4AF37);',
            'static const Color kSecondaryColor = Color(0xFF1B7A43);',
          );
          modified = true;
        }
      }

      // Special handling for AppTheme class declaration to swap secondary to green
      if (entity.path.endsWith('app_theme.dart')) {
        if (content.contains('static const Color secondaryColor = Color(0xFFD4AF37);')) {
          content = content.replaceAll(
            'static const Color secondaryColor = Color(0xFFD4AF37);',
            'static const Color secondaryColor = Color(0xFF1B7A43);',
          );
          modified = true;
        }
        if (content.contains('static const Color accentColor = Color(0xFFC59B27);')) {
          content = content.replaceAll(
            'static const Color accentColor = Color(0xFFC59B27);',
            'static const Color accentColor = Color(0xFF0F4E27);',
          );
          modified = true;
        }
      }

      mappings.forEach((greenHex, goldHex) {
        if (content.contains(greenHex)) {
          content = content.replaceAll(greenHex, goldHex);
          modified = true;
        }
      });

      if (modified) {
        entity.writeAsStringSync(content);
        print('Updated: ${entity.path}');
        modifiedFilesCount++;
      }
    }
  });

  print('Done! Updated $modifiedFilesCount files.');
}
