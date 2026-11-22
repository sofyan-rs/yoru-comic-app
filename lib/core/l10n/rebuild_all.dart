import 'package:flutter/widgets.dart';

/// Marks [element] and everything below it to build again, as a hot
/// reload does: `AppText` is read while building, so a widget, const ones
/// included, only shows a new language once it builds.
void rebuildAll(Element element) {
  element.markNeedsBuild();
  element.visitChildren(rebuildAll);
}
