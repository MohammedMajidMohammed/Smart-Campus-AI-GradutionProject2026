// import 'package:smart_canvas/app/my_app.dart';
// import 'package:translator/translator.dart';
// import 'package:easy_localization/easy_localization.dart';

// class TranslationService {
//   final GoogleTranslator _translator = GoogleTranslator();

//   // كاش بسيط للترجمات
//   final Map<String, String> _cache = {};

//   Future<String> translate(String text) async {
//     final locale = navigatorKey.currentContext!.locale.languageCode;

//     // ✅ لو اللغة المختارة نفس النص الأصلي.. رجعه زي ما هو
//     if (_detectLanguage(text) == locale) {
//       return text;
//     }

//     // ✅ لو النص مترجم قبل كده من نفس اللغة.. رجعه من الكاش
//     final cacheKey = "$text-$locale";
//     if (_cache.containsKey(cacheKey)) {
//       return _cache[cacheKey]!;
//     }

//     // ✅ ترجم النص وخزنه في الكاش
//     final translation = await _translator.translate(text, to: locale);
//     _cache[cacheKey] = translation.text;
//     return translation.text;
//   }

//   // دالة بسيطة تتوقع اللغة من النص (بدائية)
//   String _detectLanguage(String text) {
//     final regexArabic = RegExp(r'[\u0600-\u06FF]');
//     if (regexArabic.hasMatch(text)) {
//       return "ar";
//     }
//     return "en";
//   }
// }
