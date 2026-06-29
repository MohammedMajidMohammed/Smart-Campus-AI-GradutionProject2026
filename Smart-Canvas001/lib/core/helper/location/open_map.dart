import 'package:url_launcher/url_launcher.dart';

Future<void> openMap(double lat, double lng) async {
  final String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  final Uri url0 = Uri.parse(googleUrl);

  if (!await launchUrl(url0)) {
    throw Exception('Could not launch $url0');
  }
}
