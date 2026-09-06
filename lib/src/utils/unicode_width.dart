import 'package:characters/characters.dart';
import 'package:termunicode/termunicode.dart' as termunicode;

/// How grapheme clusters are measured.
enum WidthMethod { grapheme, legacy }

/// Code points a legacy terminal counts as cells but shapes away when
/// drawing: joiners, variation selectors, and skin-tone modifiers.
bool _isShapedAway(int rune) =>
    rune == 0x200D ||
    rune == 0xFE0E ||
    rune == 0xFE0F ||
    (rune >= 0x1F3FB && rune <= 0x1F3FF);

/// Utility class for handling Unicode character display width in terminals.
class UnicodeWidth {
  /// Active measurement policy. Detected at startup, before the first
  /// frame.
  static WidthMethod method = WidthMethod.grapheme;

  /// Overrides [method] for tests. Pass null to reset to the default.
  static void setMethodForTesting(WidthMethod? value) {
    method = value ?? WidthMethod.grapheme;
  }

  /// Text a legacy terminal can count and draw consistently: joiners,
  /// variation selectors and skin-tone modifiers removed, so a ZWJ
  /// sequence becomes its component emoji and a VS16 symbol its text
  /// form.
  static String normalize(String text) {
    if (method != WidthMethod.legacy) return text;
    if (!text.runes.any(_isShapedAway)) return text;
    return String.fromCharCodes(
      text.runes.where((rune) => !_isShapedAway(rune)),
    );
  }

  /// Calculate the display width of a string in terminal columns.
  static int stringWidth(String text) {
    if (text.isEmpty) return 0;

    var totalWidth = 0;
    for (final grapheme in text.characters) {
      totalWidth += graphemeWidth(grapheme);
    }

    return totalWidth;
  }

  /// Calculate the display width of a single grapheme cluster.
  static int graphemeWidth(String grapheme) {
    if (grapheme.isEmpty) return 0;

    // Layout expects a tab to advance the cursor.
    if (grapheme == '\t') return 1;

    if (method == WidthMethod.legacy) {
      var total = 0;
      for (final rune in grapheme.runes) {
        if (_isShapedAway(rune)) continue;
        total += termunicode.widthCp(rune);
      }
      return total;
    }

    return termunicode.widthString(grapheme);
  }

  /// Calculate the display width of a single rune/codepoint.
  static int runeWidth(int rune) {
    if (rune == 0x09) return 1;

    return termunicode.widthCp(rune);
  }
}
