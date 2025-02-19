// ignore_for_file: prefer_initializing_formals
part of 'view.dart';

/// A helper widget that implements fluent page transitions into
/// [NavigationView].
///
/// See also:
///   * [NavigationView], used alongside this to navigate through pages
///   * [NavigationAppBar], the app top bar
class NavigationBody extends StatefulWidget {
  /// Creates a navigation body.
  ///
  /// [index] must be greater than 0 and less than [children.length]
  const NavigationBody({
    Key? key,
    required this.index,
    required List<Widget> children,
    this.transitionBuilder,
    this.animationCurve,
    this.animationDuration,
  })  : assert(index >= 0 && index <= children.length),
        children = children,
        itemBuilder = null,
        itemCount = null,
        super(key: key);

  /// Creates a navigation body that uses a builder to supply child pages
  ///
  /// [index] must be greater than 0 and less than [itemCount] if it is provided
  const NavigationBody.builder({
    Key? key,
    required this.index,
    required IndexedWidgetBuilder itemBuilder,
    this.itemCount,
    this.transitionBuilder,
    this.animationCurve,
    this.animationDuration,
  })  : assert(index >= 0 && (itemCount == null || index <= itemCount)),
        itemBuilder = itemBuilder,
        children = null,
        super(key: key);

  /// The pages this body can have
  final List<Widget>? children;

  /// The builder that will be used to build the pages
  final IndexedWidgetBuilder? itemBuilder;

  /// Optional number of items to assume builder can create.
  final int? itemCount;

  /// The current page index.
  final int index;

  /// The transition builder.
  ///
  /// It can be detect the display mode of the parent [NavigationView], if any,
  /// and change the transition accordingly. By default, if the display mode is
  /// top, [EntrancePageTransition] is used, otherwise [DrillInPageTransition]
  /// is used.
  ///
  /// ```dart
  /// NavigationBody(
  ///   transitionBuilder: (child, animation) {
  ///     return DrillInPageTransition(child: child, animation: animation);
  ///   },
  /// ),
  /// ```
  final AnimatedSwitcherTransitionBuilder? transitionBuilder;

  /// The curve used by the transition. [NavigationPaneThemeData.animationCurve]
  /// is used by default.
  ///
  /// See also:
  ///   * [Curves], a collection of common animation easing curves.
  final Curve? animationCurve;

  /// The duration of the transition. [NavigationPaneThemeData.animationDuration]
  /// is used by default.
  ///
  /// See also:
  ///   * [ThemeData.fastAnimationDuration], the duration used by default.
  final Duration? animationDuration;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('index', index));
    properties.add(
      DiagnosticsProperty<Curve>('animationCurve', animationCurve),
    );
    properties.add(
      DiagnosticsProperty<Duration>('animationDuration', animationDuration),
    );
  }

  @override
  _NavigationBodyState createState() => _NavigationBodyState();
}

class _NavigationBodyState extends State<NavigationBody> {
  late int previousIndex;

  @override
  void initState() {
    super.initState();
    previousIndex = widget.index;
  }

  @override
  void didUpdateWidget(NavigationBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    previousIndex = oldWidget.index;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final _body = InheritedNavigationView.maybeOf(context);
    final theme = FluentTheme.of(context);
    final NavigationPaneThemeData paneTheme = NavigationPaneTheme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: AnimatedSwitcher(
        switchInCurve:
            widget.animationCurve ?? paneTheme.animationCurve ?? Curves.linear,
        duration: widget.animationDuration ??
            paneTheme.animationDuration ??
            Duration.zero,
        layoutBuilder: (child, children) {
          return SizedBox(child: child);
        },
        transitionBuilder: (child, animation) {
          if (widget.transitionBuilder != null) {
            return widget.transitionBuilder!(child, animation);
          }
          bool useDrillTransition = true;
          if (_body != null && _body.displayMode != null) {
            if (_body.displayMode! == PaneDisplayMode.top) {
              useDrillTransition = false;
            }
          }
          if (useDrillTransition) {
            return DrillInPageTransition(
              child: child,
              animation: animation,
            );
          } else {
            return EntrancePageTransition(
              child: child,
              animation: animation,
              vertical: true,
            );
          }
        },
        child: SizedBox(
          key: ValueKey<int>(widget.index),
          child: widget.itemBuilder?.call(context, widget.index) ??
              widget.children![widget.index],
        ),
      ),
    );
  }
}

/// A widget that tells what's the the current state of the parent
/// [NavigationView]
///
/// See also:
///
///  * [NavigationView], which provides the information for this
///  * [NavigationBody], which is used to display the content
class InheritedNavigationView extends InheritedWidget {
  /// Creates an inherited navigation view.
  const InheritedNavigationView({
    Key? key,
    required Widget child,
    required this.displayMode,
    this.minimalPaneOpen = false,
    this.pane,
    this.oldIndex = 0,
    this.itemIndex = -1,
  }) : super(key: key, child: child);

  /// The current pane display mode.
  final PaneDisplayMode? displayMode;

  /// Whether the minimal pane is open or not
  final bool minimalPaneOpen;

  /// The current navigation pane
  final NavigationPane? pane;

  /// The old index
  final int oldIndex;

  /// Used by [NavigationIndicator] to know what's the current index of the
  /// item
  final int itemIndex;

  static InheritedNavigationView? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedNavigationView>();
  }

  static InheritedNavigationView of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedNavigationView>()!;
  }

  static Widget merge({
    Key? key,
    required Widget child,
    int? itemIndex,
    NavigationPane? pane,
    PaneDisplayMode? displayMode,
    bool? minimalPaneOpen,
    int? oldIndex,
  }) {
    return Builder(builder: (context) {
      final current = InheritedNavigationView.maybeOf(context);
      return InheritedNavigationView(
        key: key,
        child: child,
        displayMode: displayMode ?? current?.displayMode,
        minimalPaneOpen: minimalPaneOpen ?? current?.minimalPaneOpen ?? false,
        itemIndex: itemIndex ?? current?.itemIndex ?? -1,
        pane: pane ?? current?.pane,
        oldIndex: oldIndex ?? current?.oldIndex ?? 0,
      );
    });
  }

  @override
  bool updateShouldNotify(InheritedNavigationView oldWidget) {
    return oldWidget.displayMode != displayMode ||
        oldWidget.minimalPaneOpen != minimalPaneOpen ||
        oldWidget.pane != pane ||
        oldWidget.itemIndex != oldWidget.itemIndex;
  }
}
