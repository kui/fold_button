library fold_button;

import 'dart:html';
import 'package:polymer/polymer.dart';

@CustomTag('fold-button')
class FoldButtonElement extends PolymerElement {
  static const TRANSITION_DURATION = '0.2s';
  static const List<String> PROP_NAMES =
      const ['display', 'transform', 'opacity', 'transform-origin', 'transition'];

  @PublishedProperty(reflect: true)
  String get target => readValue(#target);
  set target(String s) => writeValue(#target, s);

  @PublishedProperty(reflect: true)
  bool get folding => readValue(#folding, () => false);
  set folding(bool b) => writeValue(#folding, b);

  @reflectable
  bool get hasOnFoldingElement =>
      this.querySelectorAll('on-folding,on-unfolding').isNotEmpty;

  HtmlElement get _targetElement =>
      target == null ? null : querySelector(target);
  CssStyleDeclaration _originalStyle;

  FoldButtonElement.created() : super.created();

  @override
  attached() {
    super.attached();
    onClick.listen((_) => toggle());
    _targetElement.onTransitionEnd.listen(handleTransitionEnd);
  }

  void toggle() { folding = !folding; }
  void fold() { folding = true; }
  void unfold() { folding = false; }

  targetChanged() {
    final t = _targetElement;
    if (t == null) {
      window.console.warn('Target not found: $target');
      return;
    }
  }

  foldingChanged() {
    if (folding) {
      _foldTarget();
    } else {
      _unfoldTarget();
    }
  }

  void _foldTarget() {
    final t = _targetElement;
    if (t == null) {
      window.console.warn('Target not found: $target');
      return;
    }

    _saveStyles(t.style);

    t.style.transform = 'scale(0)';
    t.style.opacity = '0';
    t.style.transition = 'transform $TRANSITION_DURATION ease-in, '
        'opacity $TRANSITION_DURATION ease-out';
    final Point<double> delta = getCenterPoint(this) - getTopLeftPoint(t);
    t.style.transformOrigin = '${delta.x.round()}px ${delta.y.round()}px';
  }

  void _unfoldTarget() {
    final t = _targetElement;
    if (t == null) {
      window.console.warn('Target not found: $target');
      return;
    }

    _restoreStyle(t.style, 'display');

    async((_) {
      _restoreStyle(t.style, 'transform');
      _restoreStyle(t.style, 'opacity');
    });
  }

  void handleTransitionEnd(TransitionEvent event) {
    final t = _targetElement;
    if (t == null) return;

    if (folding) {
      t.style.display = 'none';
    } else {
      _restoreStyles(t.style);
    }
  }

  _saveStyles(CssStyleDeclaration style) =>
      PROP_NAMES.forEach((p) => _saveStyle(style, p));
  _saveStyle(CssStyleDeclaration style, String propName) {
    if (_originalStyle == null) _originalStyle = new CssStyleDeclaration();
    _originalStyle.setProperty(propName, style.getPropertyValue(propName));
  }
  _restoreStyles(CssStyleDeclaration style) =>
      PROP_NAMES.forEach((p) => _restoreStyle(style, p));
  _restoreStyle(CssStyleDeclaration style, String propName) {
    if (_originalStyle == null) return;
    final p = _originalStyle.getPropertyValue(propName);
    if (p == null) {
      style.removeProperty(propName);
      style.removeProperty('-webkit-$propName');
      style.removeProperty('-moz-$propName');
      style.removeProperty('-ms-$propName');
      style.removeProperty('-o-$propName');
    } else {
      style.setProperty(propName, p);
      style.setProperty('-webkit-$propName', p);
      style.setProperty('-moz-$propName', p);
      style.setProperty('-ms-$propName', p);
      style.setProperty('-o-$propName', p);
    }
  }
}

getCenterPoint(Element e) {
  final rects = e.getClientRects();
  return rects
    .map((r) => (r.topLeft + r.bottomRight) * 0.5)
    .fold(new Point(0.0, 0.0), (prev, p) => prev + p) * (1 / rects.length);
}
getTopLeftPoint(Element e) {
  final rects = e.getClientRects();
  return rects
    .map((r) => r.topLeft)
    .fold(new Point(0.0, 0.0), (prev, p) => prev + p) * (1 / rects.length);
}
