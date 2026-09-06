import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

const zwsp = '​';

void main() {
  tearDown(() => UnicodeWidth.setMethodForTesting(null));

  group('WidthMethod.legacy', () {
    setUp(() => UnicodeWidth.setMethodForTesting(WidthMethod.legacy));

    test('sums per-codepoint widths, ignoring shaped-away code points', () {
      expect(UnicodeWidth.graphemeWidth('👍🏽'), 2); // skin tone dropped
      expect(UnicodeWidth.graphemeWidth('🇺🇸'), 4); // regional indicator pair
      expect(
          UnicodeWidth.graphemeWidth('👮‍♂️'), 3); // 👮 + ♂, ZWJ/VS16 dropped
      expect(UnicodeWidth.graphemeWidth('👨‍👩‍👧'), 6); // three people
    });

    test('VS16 narrow base stays width 1', () {
      expect(UnicodeWidth.graphemeWidth('❤️'), 1);
      expect(UnicodeWidth.graphemeWidth('⚠️'), 1);
    });

    test('single code points match grapheme mode', () {
      expect(UnicodeWidth.graphemeWidth('中'), 2);
      expect(UnicodeWidth.graphemeWidth('a'), 1);
      expect(UnicodeWidth.graphemeWidth('😀'), 2);
      expect(UnicodeWidth.graphemeWidth('é'), 1); // e + combining acute
      expect(UnicodeWidth.graphemeWidth('\t'), 1);
    });

    test('normalize strips joiners, variation selectors and skin tones', () {
      expect(UnicodeWidth.normalize('👨‍👩‍👧'), '👨👩👧');
      expect(UnicodeWidth.normalize('👍🏽'), '👍');
      expect(UnicodeWidth.normalize('❤️'), '❤');
      expect(UnicodeWidth.normalize('🕵️‍♂️'), '🕵♂');
      expect(UnicodeWidth.normalize('a ❤️ b'), 'a ❤ b');
    });

    test('normalize keeps combining marks and returns plain text as-is', () {
      const plain = 'héllo 中 😀';
      expect(UnicodeWidth.normalize(plain), same(plain));
    });

    test('a string measures the same before and after normalizing', () {
      const text = 'abc 👨‍👩‍👧 ❤️ 👍🏽 def';
      expect(
        UnicodeWidth.stringWidth(text),
        UnicodeWidth.stringWidth(UnicodeWidth.normalize(text)),
      );
    });
  });

  group('grapheme mode (default)', () {
    test('clusters are a single width', () {
      expect(UnicodeWidth.graphemeWidth('👍🏽'), 2);
      expect(UnicodeWidth.graphemeWidth('🇺🇸'), 2);
      expect(UnicodeWidth.graphemeWidth('❤️'), 2);
    });

    test('normalize leaves text untouched', () {
      const text = '👨‍👩‍👧 ❤️ 👍🏽';
      expect(UnicodeWidth.normalize(text), same(text));
    });
  });

  group('Buffer.setString in legacy mode', () {
    setUp(() => UnicodeWidth.setMethodForTesting(WidthMethod.legacy));

    test('stores a skin-toned emoji as its base with one continuation', () {
      final buffer = Buffer(10, 1)..setString(0, 0, '👍🏽');
      expect(buffer.getCell(0, 0).char, '👍');
      expect(buffer.getCell(1, 0).char, zwsp);
      expect(buffer.getCell(2, 0).char, ' ');
    });

    test('splits a ZWJ sequence into its component emoji', () {
      final buffer = Buffer(10, 1)..setString(0, 0, '👨‍👩‍👧');
      expect(buffer.getCell(0, 0).char, '👨');
      expect(buffer.getCell(1, 0).char, zwsp);
      expect(buffer.getCell(2, 0).char, '👩');
      expect(buffer.getCell(3, 0).char, zwsp);
      expect(buffer.getCell(4, 0).char, '👧');
      expect(buffer.getCell(5, 0).char, zwsp);
      expect(buffer.getCell(6, 0).char, ' ');
    });

    test('stores a VS16 symbol in its narrow text form', () {
      final buffer = Buffer(10, 1)..setString(0, 0, '❤️x');
      expect(buffer.getCell(0, 0).char, '❤');
      expect(buffer.getCell(1, 0).char, 'x');
    });

    test('a cluster that would overflow the row is dropped', () {
      final buffer = Buffer(1, 1)..setString(0, 0, '👍🏽');
      expect(buffer.getCell(0, 0).char, ' ');
    });
  });

  group('Buffer.setString in grapheme mode', () {
    test('keeps the full cluster with one continuation cell', () {
      final buffer = Buffer(10, 1)..setString(0, 0, '👍🏽');
      expect(buffer.getCell(0, 0).char, '👍🏽');
      expect(buffer.getCell(1, 0).char, zwsp);
      expect(buffer.getCell(2, 0).char, ' ');
    });
  });

  group('Cell.isMultiCodePoint', () {
    test('distinguishes clusters from single code points', () {
      expect(Cell(char: '👍🏽').isMultiCodePoint, isTrue);
      expect(Cell(char: '❤️').isMultiCodePoint, isTrue);
      expect(Cell(char: 'a').isMultiCodePoint, isFalse);
      expect(Cell(char: '中').isMultiCodePoint, isFalse);
      expect(Cell(char: '😀').isMultiCodePoint, isFalse);
    });
  });
}
