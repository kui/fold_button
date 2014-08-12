library fold_button;

import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';

@CustomTag('fold-button')
class FoldButtonElement extends PolymerElement {
  static const List<String> PROP_NAMES =
      const ['display', 'transform', 'opacity', 'transform-origin', 'transition'];
  static const TRANSITION_DURATION = const Duration(milliseconds: 200);
  static const DISPLAY_DELAY = const Duration(milliseconds: 80);

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
  Timer _transitionEndTimer;

  FoldButtonElement.created() : super.created();

  @override
  attached() {
    super.attached();
    onClick.listen((_) => toggle());
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

    if (_transitionEndTimer == null) {
      _saveStyles(t.style);
      final Point<double> delta = _getCenterPoint(this) - _getTopLeftPoint(t);
      _setStyle(t.style, 'transform-origin',
          '${delta.x.round()}px ${delta.y.round()}px');
    }

    _setStyle(t.style, 'transform', 'scale(0)');
    _setStyle(t.style, 'opacity', '0');
    _setStyle(t.style, 'transition',
        'transform ${TRANSITION_DURATION.inMilliseconds}ms ease-in  0s, '
        'opacity   ${TRANSITION_DURATION.inMilliseconds}ms ease-out 0s');
    startTransitionEndTimer();
  }

  void _unfoldTarget() {
    final t = _targetElement;
    if (t == null) {
      window.console.warn('Target not found: $target');
      return;
    }

    _restoreStyle(t.style, 'display');

    new Timer(DISPLAY_DELAY, () {
      _restoreStyle(t.style, 'transform', 'scale(1)');
      _restoreStyle(t.style, 'opacity', '1');
      startTransitionEndTimer();
    });
  }

  void startTransitionEndTimer() {
    if (_transitionEndTimer != null) {
      _transitionEndTimer.cancel();
    }
    _transitionEndTimer = new Timer(TRANSITION_DURATION, handleTransitionEnd);
  }

  void handleTransitionEnd() {
    final t = _targetElement;
    if (t == null) return;

    if (folding) {
      t.style.display = 'none';
    } else {
      _restoreStyles(t.style);
    }

    _transitionEndTimer = null;
  }

  _setStyle(CssStyleDeclaration style, String propName, String value) =>
      _listWithVenderPrefix(propName).forEach((name) {
          style.setProperty(name, value); print(name);});
  _saveStyles(CssStyleDeclaration style) =>
      PROP_NAMES.forEach((p) => _saveStyle(style, p));
  _saveStyle(CssStyleDeclaration style, String propName) {
    if (_originalStyle == null) _originalStyle = new CssStyleDeclaration();
    _originalStyle.setProperty(propName, style.getPropertyValue(propName));
  }
  _restoreStyles(CssStyleDeclaration style) =>
      PROP_NAMES.forEach((p) => _restoreStyle(style, p));
  _restoreStyle(CssStyleDeclaration style, String propName, [String defaultValue]) {
    if (_originalStyle == null) return;
    final p = _originalStyle.getPropertyValue(propName);
    final value = (p == null) ? defaultValue : p;
    if (value == null) {
      _listWithVenderPrefix(propName).forEach(style.removeProperty);
    } else {
      _listWithVenderPrefix(propName).forEach((name) =>
          style.setProperty(name, value));
    }
  }
}

List<String> _listWithVenderPrefix(String propName) =>
  ['-webkit-$propName', '-moz-$propName', '-ms-$propName',
   '-o-$propName', propName];

_getCenterPoint(Element e) {
  final rects = e.getClientRects();
  return rects
    .map((r) => (r.topLeft + r.bottomRight) * 0.5)
    .fold(new Point(0.0, 0.0), (prev, p) => prev + p) * (1 / rects.length);
}
_getTopLeftPoint(Element e) {
  final rects = e.getClientRects();
  return rects
    .map((r) => r.topLeft)
    .fold(new Point(0.0, 0.0), (prev, p) => prev + p) * (1 / rects.length);
}
