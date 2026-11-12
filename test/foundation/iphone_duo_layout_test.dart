import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:venera_next/foundation/iphone_duo_layout.dart';

void main() {
  test(
    'maps the iPhone Duo simulator displays to their navigation layouts',
    () {
      expect(
        IPhoneDuoLayout.forSize(const Size(466, 678)),
        IPhoneDuoLayout.outer,
      );
      expect(
        IPhoneDuoLayout.forSize(const Size(669, 951)),
        IPhoneDuoLayout.innerPortrait,
      );
      expect(
        IPhoneDuoLayout.forSize(const Size(951, 669)),
        IPhoneDuoLayout.innerLandscape,
      );
    },
  );

  test('only the wide inner layout turns two images into a spread', () {
    expect(IPhoneDuoLayout.outer.pagesPerSpread, 1);
    expect(IPhoneDuoLayout.innerPortrait.pagesPerSpread, 1);
    expect(IPhoneDuoLayout.innerLandscape.pagesPerSpread, 2);
    expect(IPhoneDuoLayout.forSize(const Size(678, 466)).pagesPerSpread, 1);
  });
}
