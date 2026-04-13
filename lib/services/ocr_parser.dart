/// Extracts contact fields (name, email, phone, job title, company)
/// from raw OCR text recognized on a business card.
class OcrParser {
  OcrParser._();

  static Map<String, String> parse(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final result = <String, String>{};

    String? email;
    String? phone;
    String? website;
    final nameLines = <String>[];
    final companyLines = <String>[];

    for (final line in lines) {
      // Email
      final emailMatch = RegExp(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}').firstMatch(line);
      if (emailMatch != null && email == null) {
        email = emailMatch.group(0);
        continue;
      }

      // Phone (international or local formats)
      final phoneMatch = RegExp(
        r'(?:\+?\d{1,3}[\s\-.]?)?\(?\d{2,4}\)?[\s\-.]?\d{2,4}[\s\-.]?\d{2,4}[\s\-.]?\d{0,4}',
      ).firstMatch(line);
      if (phoneMatch != null) {
        final digits = phoneMatch.group(0)!.replaceAll(RegExp(r'[^\d+]'), '');
        if (digits.length >= 8 && phone == null) {
          phone = phoneMatch.group(0)!.trim();
          // If line has only the phone, skip
          if (line.replaceAll(phoneMatch.group(0)!, '').trim().length < 3) continue;
        }
      }

      // Website lines — skip
      if (RegExp(r'www\.|https?://', caseSensitive: false).hasMatch(line)) {
        website ??= line;
        continue;
      }

      // Skip address-like lines
      if (RegExp(r'\b(rue|avenue|boulevard|bp|boîte|cedex|street|road|box)\b', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      if (RegExp(r'\b\d{4,6}\b').hasMatch(line) && line.length > 15) {
        continue; // likely postal address
      }

      // Remaining lines: classify as name or company/title
      nameLines.add(line);
    }

    if (email != null) result['email'] = email;
    if (phone != null) result['phone'] = phone;

    // Heuristic: first text line is usually the name,
    // second is job title or company, third is the other.
    if (nameLines.isNotEmpty) {
      final name = nameLines[0];
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        result['firstName'] = parts.first;
        result['lastName'] = parts.sublist(1).join(' ');
      } else {
        result['lastName'] = name;
      }
    }

    // Common job title keywords
    final titleKeywords = RegExp(
      r'\b(ceo|cto|cfo|coo|cmo|directeur|directrice|manager|head|chef|responsable|ingénieur|engineer|consultant|partner|founder|président|associate|analyst|developer|designer|vp|vice)\b',
      caseSensitive: false,
    );

    for (var i = 1; i < nameLines.length; i++) {
      final line = nameLines[i];
      if (titleKeywords.hasMatch(line)) {
        if (!result.containsKey('jobTitle')) {
          result['jobTitle'] = line;
        }
      } else if (!result.containsKey('company')) {
        result['company'] = line;
      }
    }

    // If we found a company but not a title, and there's a leftover line, use it
    if (!result.containsKey('jobTitle') && nameLines.length > 2) {
      for (var i = 1; i < nameLines.length; i++) {
        if (nameLines[i] != result['company']) {
          result['jobTitle'] = nameLines[i];
          break;
        }
      }
    }

    return result;
  }
}
