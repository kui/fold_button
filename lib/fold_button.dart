library fold_button;

import 'dart:html';
import 'dart:async';
import 'dart:math';
import 'package:polymer/polymer.dart';

@CustomTag('fold-button')
class FoldButtonElement extends PolymerElement {
  static const List<String> PROP_NAMES =
      const ['display', 'transform', 'opacity', 'transform-origin', 'transition'];
  static const TRANSITION_DURATION = const Duration(milliseconds: 200);
  static const DISPLAY_DELAY = const Duration(milliseconds: 50);

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
    _startTransitionEndTimer();
  }

  void _unfoldTarget() {
    final t = _targetElement;
    if (t == null) {
      window.console.warn('Target not found: $target');
      return;
    }

    _restoreStyle(t.style, 'display');

    _startTransitionEndTimer(delay: DISPLAY_DELAY + TRANSITION_DURATION);
    new Timer(DISPLAY_DELAY, () {
      _restoreStyle(t.style, 'transform', 'scale(1)');
      _restoreStyle(t.style, 'opacity', '1');
    });
  }

  void _startTransitionEndTimer({Duration delay: TRANSITION_DURATION}) {
    if (_transitionEndTimer != null) {
      _transitionEndTimer.cancel();
    }
    _transitionEndTimer = new Timer(delay, _handleTransitionEnd);
  }

  void _handleTransitionEnd() {
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
      _listWithVenderPrefix(propName).forEach((name) =>
          style.setProperty(name, value));
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

Point _getCenterPoint(Element e) {
  final rects = e.getClientRects();
  final Point sumPoint = rects
      .fold(new Point(0,0), (prev, r) => prev + r.topLeft + r.bottomRight);
  final f = 1 / (2 * rects.length);
  return sumPoint * f;
}
Point _getTopLeftPoint(Element e) {
  final rects = e.getClientRects();
  final Point sumPoint = rects
      .fold(new Point(0,0), (prev, r) => prev + r.topLeft);
  final f = 1 / rects.length;
  return sumPoint * f;
}
