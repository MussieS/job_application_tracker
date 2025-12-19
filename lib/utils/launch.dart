import 'package:url_launcher/url_launcher.dart';

Future<bool> launchUrlStringSafe(String url) async {
  final u = Uri.tryParse(url.trim());
  if (u == null) return false;
  if (!(u.isScheme('http') || u.isScheme('https'))) return false;
  return launchUrl(u, mode: LaunchMode.externalApplication);
}
