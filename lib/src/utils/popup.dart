import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as m;

import 'package:fluent_ui/fluent_ui.dart';

class PopUp<T> extends StatefulWidget {
  const PopUp({
    Key? key,
    required this.child,
    required this.content,
    this.verticalOffset = 0,
    this.horizontalOffset = 0,
    this.placement = FlyoutPlacement.center,
  }) : super(key: key);

  final Widget child;
  final WidgetBuilder content;
  final double verticalOffset;
  final double horizontalOffset;

  final FlyoutPlacement placement;

  @override
  PopUpState<T> createState() => PopUpState<T>();
}

class PopUpState<T> extends State<PopUp<T>> {
  _PopUpRoute<T>? _dropdownRoute;

  Future<void> openPopup() {
    assert(_dropdownRoute == null, 'You can NOT open a popup twice');
    final NavigatorState navigator = Navigator.of(context);
    final RenderBox itemBox = context.findRenderObject()! as RenderBox;
    Offset leftTarget = itemBox.localToGlobal(
      itemBox.size.centerLeft(Offset.zero),
      ancestor: navigator.context.findRenderObject(),
    );
    Offset centerTarget = itemBox.localToGlobal(
      itemBox.size.center(Offset.zero),
      ancestor: navigator.context.findRenderObject(),
    );
    Offset rightTarget = itemBox.localToGlobal(
      itemBox.size.centerRight(Offset.zero),
      ancestor: navigator.context.findRenderObject(),
    );

    assert(m.debugCheckHasDirectionality(context));
    final directionality = Directionality.of(context);

    // The target according to the current directionality
    final Offset directionalityTarget = () {
      switch (widget.placement) {
        case FlyoutPlacement.start:
          if (directionality == TextDirection.ltr) {
            return leftTarget;
          } else {
            return rightTarget;
          }
        case FlyoutPlacement.end:
          if (directionality == TextDirection.ltr) {
            return rightTarget;
          } else {
            return leftTarget;
          }
        case FlyoutPlacement.center:
        case FlyoutPlacement.full:
          return centerTarget;
      }
    }();

    // The placement according to the current directionality
    final FlyoutPlacement directionalityPlacement = () {
      switch (widget.placement) {
        case FlyoutPlacement.start:
          if (directionality == TextDirection.rtl) {
            return FlyoutPlacement.end;
          }
          continue next;
        case FlyoutPlacement.end:
          if (directionality == TextDirection.rtl) {
            return FlyoutPlacement.start;
          }
          continue next;
        next:
        default:
          return widget.placement;
      }
    }();

    final Rect itemRect = directionalityTarget & itemBox.size;
    _dropdownRoute = _PopUpRoute<T>(
      target: centerTarget,
      placementOffset: directionalityTarget,
      placement: directionalityPlacement,
      content: widget.content(context),
      buttonRect: itemRect,
      elevation: 4,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      transitionAnimationDuration:
          FluentTheme.of(context).mediumAnimationDuration,
      verticalOffset: widget.verticalOffset,
      horizontalOffset: widget.horizontalOffset,
      barrierLabel: FluentLocalizations.of(context).modalBarrierDismissLabel,
    );

    return navigator.push(_dropdownRoute!).then((T? newValue) {
      removePopUpRoute();
      if (!mounted || newValue == null) return;
    });
  }

  bool get isOpen => _dropdownRoute != null;

  void removePopUpRoute() {
    _dropdownRoute?._dismiss();
    _dropdownRoute = null;
    // _lastOrientation = null;
  }

  @override
  void dispose() {
    removePopUpRoute();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(m.debugCheckHasDirectionality(context));
    return widget.child;
  }
}

// Backend below

class _PopUpScrollBehavior extends ScrollBehavior {
  const _PopUpScrollBehavior();

  @override
  TargetPlatform getPlatform(BuildContext context) => defaultTargetPlatform;

  @override
  Widget buildViewportChrome(context, child, axisDirection) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

class _PopUpMenu<T> extends StatefulWidget {
  const _PopUpMenu({
    Key? key,
    required this.route,
    required this.buttonRect,
    required this.constraints,
    this.dropdownColor,
  }) : super(key: key);

  final _PopUpRoute<T> route;
  final Rect buttonRect;
  final BoxConstraints constraints;
  final Color? dropdownColor;

  @override
  _PopUpMenuState<T> createState() => _PopUpMenuState<T>();
}

class _PopUpMenuState<T> extends State<_PopUpMenu<T>> {
  late CurvedAnimation _fadeOpacity;

  @override
  void initState() {
    super.initState();
    _fadeOpacity = CurvedAnimation(
      parent: widget.route.animation!,
      curve: const Interval(0.0, 0.50),
      reverseCurve: const Interval(0.75, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeOpacity,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        child: m.Material(
          type: m.MaterialType.transparency,
          child: ScrollConfiguration(
            behavior: const _PopUpScrollBehavior(),
            child: widget.route.content,
          ),
        ),
      ),
    );
  }
}

class _PopUpMenuRouteLayout<T> extends SingleChildLayoutDelegate {
  _PopUpMenuRouteLayout({
    required this.buttonRect,
    required this.route,
    required this.textDirection,
    required this.target,
    required this.verticalOffset,
    required this.horizontalOffset,
    required this.placementOffset,
    required this.placement,
  });

  final Rect buttonRect;
  final _PopUpRoute<T> route;
  final TextDirection? textDirection;
  final Offset target;
  final double verticalOffset;
  final double horizontalOffset;
  final Offset placementOffset;
  final FlyoutPlacement placement;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final defaultOffset = positionDependentBox(
      size: size,
      childSize: childSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: false,
      margin: horizontalOffset,
    );
    switch (placement) {
      case FlyoutPlacement.start:
        return Offset(placementOffset.dx, defaultOffset.dy);
      case FlyoutPlacement.end:
        return Offset(placementOffset.dx - childSize.width, defaultOffset.dy);
      case FlyoutPlacement.full:
        return Offset.zero;
      case FlyoutPlacement.center:
        return defaultOffset;
    }
  }

  @override
  bool shouldRelayout(_PopUpMenuRouteLayout<T> oldDelegate) {
    return oldDelegate.target == target ||
        oldDelegate.placementOffset == placementOffset ||
        buttonRect != oldDelegate.buttonRect;
  }
}

class _PopUpRoute<T> extends PopupRoute<T> {
  _PopUpRoute({
    required this.content,
    required this.buttonRect,
    required this.target,
    required this.placementOffset,
    required this.placement,
    this.elevation = 8,
    required this.capturedThemes,
    required this.transitionAnimationDuration,
    this.barrierLabel,
    required this.verticalOffset,
    required this.horizontalOffset,
    this.acrylicDisabled = false,
  });

  final bool acrylicDisabled;
  final Widget content;
  final Rect buttonRect;
  final int elevation;
  final CapturedThemes capturedThemes;
  final double verticalOffset;
  final double horizontalOffset;

  final Duration transitionAnimationDuration;

  final Offset target;
  final Offset placementOffset;
  final FlyoutPlacement placement;

  @override
  Duration get transitionDuration => transitionAnimationDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  final String? barrierLabel;

  @override
  Widget buildPage(context, animation, secondaryAnimation) {
    return LayoutBuilder(builder: (context, constraints) {
      final page = _PopUpRoutePage<T>(
        target: target,
        placementOffset: placementOffset,
        placement: placement,
        route: this,
        constraints: constraints,
        content: content,
        buttonRect: buttonRect,
        elevation: elevation,
        capturedThemes: capturedThemes,
        verticalOffset: verticalOffset,
        horizontalOffset: horizontalOffset,
      );
      if (acrylicDisabled) return DisableAcrylic(child: page);
      return page;
    });
  }

  void _dismiss() {
    if (isActive) {
      navigator?.removeRoute(this);
    }
  }
}

class _PopUpRoutePage<T> extends StatelessWidget {
  const _PopUpRoutePage({
    Key? key,
    required this.route,
    required this.constraints,
    required this.content,
    required this.buttonRect,
    this.elevation = 8,
    required this.capturedThemes,
    required this.verticalOffset,
    required this.horizontalOffset,
    this.style,
    required this.target,
    required this.placement,
    required this.placementOffset,
  }) : super(key: key);

  final _PopUpRoute<T> route;
  final BoxConstraints constraints;
  final Widget content;
  final Rect buttonRect;
  final int elevation;
  final CapturedThemes capturedThemes;
  final TextStyle? style;
  final double verticalOffset;
  final double horizontalOffset;
  final Offset target;
  final Offset placementOffset;
  final FlyoutPlacement placement;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));

    final TextDirection? textDirection = Directionality.maybeOf(context);
    final Widget menu = _PopUpMenu<T>(
      route: route,
      buttonRect: buttonRect,
      constraints: constraints,
    );

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (BuildContext context) {
          return CustomSingleChildLayout(
            delegate: _PopUpMenuRouteLayout<T>(
              target: target,
              placement: placement,
              placementOffset: placementOffset,
              buttonRect: buttonRect,
              route: route,
              textDirection: textDirection,
              verticalOffset: verticalOffset,
              horizontalOffset: horizontalOffset,
            ),
            child: capturedThemes.wrap(menu),
          );
        },
      ),
    );
  }
}
