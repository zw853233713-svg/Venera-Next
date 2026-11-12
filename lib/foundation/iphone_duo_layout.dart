import 'dart:ui';

enum IPhoneDuoLayout {
  outer,
  innerPortrait,
  innerLandscape;

  // At 3x scale the Duo's full outer screen is 466 points across its
  // shorter edge and the inner screen is 669 points. Classifying the
  // window keeps narrow multitasking layouts in the compact presentation.
  static IPhoneDuoLayout forSize(Size size) {
    if (size.shortestSide < 550) return outer;
    return size.width > size.height ? innerLandscape : innerPortrait;
  }

  int get pagesPerSpread => this == innerLandscape ? 2 : 1;
}
