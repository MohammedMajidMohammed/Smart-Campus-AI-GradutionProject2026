// import 'package:flutter/material.dart';
// import 'package:smart_canvas/core/di/dependancy_injection.dart';
// import 'package:smart_canvas/core/helper/translation_services.dart';
// import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';

// class TranslateText extends StatelessWidget {
//   const TranslateText({
//     super.key,
//     required this.text,
//     this.style,
//     this.maxLines = 1,
//     this.overflow = TextOverflow.ellipsis,
//   });

//   final String text;
//   final TextStyle? style;
//   final int maxLines;
//   final TextOverflow overflow;
//   @override
//   Widget build(BuildContext context) {
//     final translationService = getIt<TranslationService>();
//     return FutureBuilder<String>(
//       future: translationService.translate(text),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Text('Loading...', style: style ?? AppTextStyles.title16Black);
//         } else if (snapshot.hasError) {
//           return Text(text, style: style ?? AppTextStyles.title16Black);
//         } else {
//           return Text(
//             snapshot.data ?? text,
//             style: style ?? AppTextStyles.title16Black,
//             maxLines: maxLines,
//             overflow: overflow,
//           );
//         }
//       },
//     );
//   }
// }
