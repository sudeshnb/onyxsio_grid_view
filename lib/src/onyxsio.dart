import 'dart:collection';

// import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'onyxsio_staggered_grid.dart';
import 'onyxsio_variable_size_box_adaptor.dart';

/// Helps subclasses build their children lazily using a [SliverVariableSizeChildDelegate].
abstract class OnyxsioVariableSizeBoxAdaptorWidget
    extends SliverWithKeepAliveWidget {
  /// Initializes fields for subclasses.
  const OnyxsioVariableSizeBoxAdaptorWidget({
    Key? key,
    required this.delegate,
  }) : super(key: key);

  final SliverChildDelegate delegate;

  @override
  OnyxsioVariableSizeBoxAdaptorElement createElement() =>
      OnyxsioVariableSizeBoxAdaptorElement(this);

  @override
  RenderOnyxsioVariableSizeBoxAdaptor createRenderObject(BuildContext context);

  double? estimateMaxScrollOffset(
    SliverConstraints constraints,
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    assert(lastIndex >= firstIndex);
    return delegate.estimateMaxScrollOffset(
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<SliverChildDelegate>('delegate', delegate),
    );
  }
}

class OnyxsioVariableSizeBoxAdaptorElement extends RenderObjectElement
    implements RenderOnyxsioVariableSizeBoxChildManager {
  /// Creates an element that lazily builds children for the given widget.
  OnyxsioVariableSizeBoxAdaptorElement(
      OnyxsioVariableSizeBoxAdaptorWidget widget)
      : super(widget);

  @override
  OnyxsioVariableSizeBoxAdaptorWidget get widget =>
      super.widget as OnyxsioVariableSizeBoxAdaptorWidget;

  @override
  RenderOnyxsioVariableSizeBoxAdaptor get renderObject =>
      super.renderObject as RenderOnyxsioVariableSizeBoxAdaptor;

  @override
  void update(covariant OnyxsioVariableSizeBoxAdaptorWidget newWidget) {
    final OnyxsioVariableSizeBoxAdaptorWidget oldWidget = widget;
    super.update(newWidget);
    final SliverChildDelegate newDelegate = newWidget.delegate;
    final SliverChildDelegate oldDelegate = oldWidget.delegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType ||
            newDelegate.shouldRebuild(oldDelegate))) {
      performRebuild();
    }
  }

  final Map<int, Widget?> _childWidgets = HashMap<int, Widget?>();
  final SplayTreeMap<int, Element> _childElements =
      SplayTreeMap<int, Element>();

  @override
  void performRebuild() {
    _childWidgets.clear(); // Reset the cache, as described above.
    super.performRebuild();
    assert(_currentlyUpdatingChildIndex == null);
    try {
      late final int firstIndex;
      late final int lastIndex;
      if (_childElements.isEmpty) {
        firstIndex = 0;
        lastIndex = 0;
      } else if (_didUnderflow) {
        firstIndex = _childElements.firstKey()!;
        lastIndex = _childElements.lastKey()! + 1;
      } else {
        firstIndex = _childElements.firstKey()!;
        lastIndex = _childElements.lastKey()!;
      }

      for (int index = firstIndex; index <= lastIndex; ++index) {
        _currentlyUpdatingChildIndex = index;
        final Element? newChild =
            updateChild(_childElements[index], _build(index), index);
        if (newChild != null) {
          _childElements[index] = newChild;
        } else {
          _childElements.remove(index);
        }
      }
    } finally {
      _currentlyUpdatingChildIndex = null;
    }
  }

  Widget? _build(int index) {
    return _childWidgets.putIfAbsent(
        index, () => widget.delegate.build(this, index));
  }

  @override
  void createChild(int index) {
    assert(_currentlyUpdatingChildIndex == null);
    owner!.buildScope(this, () {
      Element? newChild;
      try {
        _currentlyUpdatingChildIndex = index;
        newChild = updateChild(_childElements[index], _build(index), index);
      } finally {
        _currentlyUpdatingChildIndex = null;
      }
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    });
  }

  @override
  Element? updateChild(Element? child, Widget? newWidget, dynamic newSlot) {
    final oldParentData = child?.renderObject?.parentData
        as OnyxsioVariableSizeBoxAdaptorParentData?;
    final Element? newChild = super.updateChild(child, newWidget, newSlot);
    final newParentData = newChild?.renderObject?.parentData
        as OnyxsioVariableSizeBoxAdaptorParentData?;

    // set keepAlive to true in order to populate the cache
    if (newParentData != null) {
      newParentData.keepAlive = true;
    }

    // Preserve the old layoutOffset if the renderObject was swapped out.
    if (oldParentData != newParentData &&
        oldParentData != null &&
        newParentData != null) {
      newParentData.layoutOffset = oldParentData.layoutOffset;
    }

    return newChild;
  }

  @override
  void forgetChild(Element child) {
    assert(child.slot != null);
    assert(_childElements.containsKey(child.slot));
    _childElements.remove(child.slot);
    super.forgetChild(child);
  }

  @override
  void removeChild(RenderBox child) {
    final int index = renderObject.indexOf(child);
    assert(_currentlyUpdatingChildIndex == null);
    assert(index >= 0);
    owner!.buildScope(this, () {
      assert(_childElements.containsKey(index));
      try {
        _currentlyUpdatingChildIndex = index;
        final Element? result = updateChild(_childElements[index], null, index);
        assert(result == null);
      } finally {
        _currentlyUpdatingChildIndex = null;
      }
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  double? _extrapolateMaxScrollOffset(
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  ) {
    final int? childCount = widget.delegate.estimatedChildCount;
    if (childCount == null) {
      return double.infinity;
    }
    if (lastIndex == childCount - 1) {
      return trailingScrollOffset;
    }
    final int reifiedCount = lastIndex! - firstIndex! + 1;
    final double averageExtent =
        (trailingScrollOffset! - leadingScrollOffset!) / reifiedCount;
    final int remainingCount = childCount - lastIndex - 1;
    return trailingScrollOffset + averageExtent * remainingCount;
  }

  @override
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  }) {
    return widget.estimateMaxScrollOffset(
          constraints,
          firstIndex!,
          lastIndex!,
          leadingScrollOffset!,
          trailingScrollOffset!,
        ) ??
        _extrapolateMaxScrollOffset(
          firstIndex,
          lastIndex,
          leadingScrollOffset,
          trailingScrollOffset,
        )!;
  }

  @override
  int get childCount => widget.delegate.estimatedChildCount ?? 0;

  @override
  void didStartLayout() {
    assert(debugAssertChildListLocked());
  }

  @override
  void didFinishLayout() {
    assert(debugAssertChildListLocked());
    final int firstIndex = _childElements.firstKey() ?? 0;
    final int lastIndex = _childElements.lastKey() ?? 0;
    widget.delegate.didFinishLayout(firstIndex, lastIndex);
  }

  int? _currentlyUpdatingChildIndex;

  @override
  bool debugAssertChildListLocked() {
    assert(_currentlyUpdatingChildIndex == null);
    return true;
  }

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingChildIndex != null);
    final childParentData =
        child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
    childParentData.index = _currentlyUpdatingChildIndex;
  }

  bool _didUnderflow = false;

  @override
  void setDidUnderflow(bool value) {
    _didUnderflow = value;
  }

  @override
  void insertRenderObjectChild(covariant RenderBox child, int slot) {
    assert(_currentlyUpdatingChildIndex == slot);
    assert(renderObject.debugValidateChild(child));
    renderObject[_currentlyUpdatingChildIndex!] = child;
    assert(() {
      final childParentData =
          child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
      assert(slot == childParentData.index);
      return true;
    }());
  }

  @override
  void moveRenderObjectChild(
    covariant RenderObject child,
    covariant Object? oldSlot,
    covariant Object? newSlot,
  ) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(
    covariant RenderObject child,
    covariant Object? slot,
  ) {
    assert(_currentlyUpdatingChildIndex != null);
    renderObject.remove(_currentlyUpdatingChildIndex!);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // The toList() is to make a copy so that the underlying list can be modified by
    // the visitor:
    _childElements.values.toList().forEach(visitor);
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    _childElements.values.where((Element child) {
      final parentData =
          child.renderObject!.parentData as SliverMultiBoxAdaptorParentData?;
      late double itemExtent;
      switch (renderObject.constraints.axis) {
        case Axis.horizontal:
          itemExtent = child.renderObject!.paintBounds.width;
          break;
        case Axis.vertical:
          itemExtent = child.renderObject!.paintBounds.height;
          break;
      }

      return parentData!.layoutOffset! <
              renderObject.constraints.scrollOffset +
                  renderObject.constraints.remainingPaintExtent &&
          parentData.layoutOffset! + itemExtent >
              renderObject.constraints.scrollOffset;
    }).forEach(visitor);
  }
}

class OnyxsioStaggeredGrid extends OnyxsioVariableSizeBoxAdaptorWidget {
  const OnyxsioStaggeredGrid({
    Key? key,
    required SliverChildDelegate delegate,
    required this.gridDelegate,
  }) : super(key: key, delegate: delegate);

  // OnyxsioStaggeredGrid.count({
  //   Key? key,
  //   required int crossAxisCount,
  //   double mainAxisSpacing = 0.0,
  //   double crossAxisSpacing = 0.0,
  //   List<Widget> children = const <Widget>[],
  //   List<StaggeredTile> staggeredTiles = const <StaggeredTile>[],
  // })  : gridDelegate = SliverStaggeredGridDelegateWithFixedCrossAxisCount(
  //         crossAxisCount: crossAxisCount,
  //         mainAxisSpacing: mainAxisSpacing,
  //         crossAxisSpacing: crossAxisSpacing,
  //         staggeredTileBuilder: (i) => staggeredTiles[i],
  //         staggeredTileCount: staggeredTiles.length,
  //       ),
  //       super(
  //         key: key,
  //         delegate: SliverChildListDelegate(
  //           children,
  //         ),
  //       );

  OnyxsioStaggeredGrid.builder({
    Key? key,
    required int crossAxisCount,
    required OnyxsioIndexedStaggeredTileBuilder staggeredTileBuilder,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
  })  : gridDelegate = SliverStaggeredGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          staggeredTileBuilder: staggeredTileBuilder,
          staggeredTileCount: itemCount,
        ),
        super(
          key: key,
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: itemCount,
          ),
        );

  // OnyxsioStaggeredGrid.extent({
  //   Key? key,
  //   required double maxCrossAxisExtent,
  //   double mainAxisSpacing = 0,
  //   double crossAxisSpacing = 0,
  //   List<Widget> children = const <Widget>[],
  //   List<StaggeredTile> staggeredTiles = const <StaggeredTile>[],
  // })  : gridDelegate = SliverStaggeredGridDelegateWithMaxCrossAxisExtent(
  //         maxCrossAxisExtent: maxCrossAxisExtent,
  //         mainAxisSpacing: mainAxisSpacing,
  //         crossAxisSpacing: crossAxisSpacing,
  //         staggeredTileBuilder: (i) => staggeredTiles[i],
  //         staggeredTileCount: staggeredTiles.length,
  //       ),
  //       super(
  //         key: key,
  //         delegate: SliverChildListDelegate(
  //           children,
  //         ),
  //       );

  // OnyxsioStaggeredGrid.extentBuilder({
  //   Key? key,
  //   required double maxCrossAxisExtent,
  //   required IndexedStaggeredTileBuilder staggeredTileBuilder,
  //   required IndexedWidgetBuilder itemBuilder,
  //   required int itemCount,
  //   double mainAxisSpacing = 0,
  //   double crossAxisSpacing = 0,
  // })  : gridDelegate = SliverStaggeredGridDelegateWithMaxCrossAxisExtent(
  //         maxCrossAxisExtent: maxCrossAxisExtent,
  //         mainAxisSpacing: mainAxisSpacing,
  //         crossAxisSpacing: crossAxisSpacing,
  //         staggeredTileBuilder: staggeredTileBuilder,
  //         staggeredTileCount: itemCount,
  //       ),
  //       super(
  //         key: key,
  //         delegate: SliverChildBuilderDelegate(
  //           itemBuilder,
  //           childCount: itemCount,
  //         ),
  //       );

  /// The delegate that controls the size and position of the children.
  final OnyxsioStaggeredGridDelegate gridDelegate;

  @override
  RenderOnyxsioStaggeredGrid createRenderObject(BuildContext context) {
    final element = context as OnyxsioVariableSizeBoxAdaptorElement;
    return RenderOnyxsioStaggeredGrid(
        childManager: element, gridDelegate: gridDelegate);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderOnyxsioStaggeredGrid renderObject) {
    renderObject.gridDelegate = gridDelegate;
  }
}
