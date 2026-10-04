import '../models/email_string_model.dart';

EmailStringModel? processEmailString(String input) {
  final value = input.trim();
  if (value.isEmpty) return null;

  try {
    final result = EmailStringModel();
    if (value.contains('<') && value.contains('>')) {
      final start = value.indexOf('<');
      final end = value.indexOf('>', start + 1);
      if (end <= start) return null;
      result.name = value.substring(0, start).trim();
      result.email = value.substring(start + 1, end).trim();
      return result;
    }

    if (!value.contains('@')) return null;
    result.name = value.substring(0, value.indexOf('@')).trim();
    result.email = value;
    return result;
  } catch (_) {
    return null;
  }
}
