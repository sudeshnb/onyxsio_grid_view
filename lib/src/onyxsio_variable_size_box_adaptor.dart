import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'tile_container_render_object_mixin.dart';

abstract class RenderOnyxsioVariableSizeBoxChildManager {
  void createChild(int index);

  void removeChild(RenderBox child);

  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  });

  int get childCount;

  void didAdoptChild(RenderBox child);

  void setDidUnderflow(bool value);

  /// Called at the beginning of layout to indicate that layout is about to
  /// occur.
  void didStartLayout() {}

  /// Called at the end of layout to indicate that layout is now complete.
  void didFinishLayout() {}

  bool debugAssertChildListLocked() => true;
}

/// Parent data structure used by [RenderOnyxsioVariableSizeBoxAdaptor].
class OnyxsioVariableSizeBoxAdaptorParentData
    extends SliverMultiBoxAdaptorParentData {
  late double crossAxisOffset;

  /// Whether the widget is currently in the
  /// [RenderOnyxsioVariableSizeBoxAdaptor._keepAliveBucket].
  bool _keptAlive = false;

  @override
  String toString() => 'crossAxisOffset=$crossAxisOffset; ${super.toString()}';
}

abstract class RenderOnyxsioVariableSizeBoxAdaptor extends RenderSliver
    with
        TileContainerRenderObjectMixin<RenderBox,
            OnyxsioVariableSizeBoxAdaptorParentData>,
        RenderSliverWithKeepAliveMixin,
        RenderSliverHelpers {
  RenderOnyxsioVariableSizeBoxAdaptor(
      {required RenderOnyxsioVariableSizeBoxChildManager childManager})
      : _childManager = childManager;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! OnyxsioVariableSizeBoxAdaptorParentData) {
      child.parentData = OnyxsioVariableSizeBoxAdaptorParentData();
    }
  }

  @protected
  RenderOnyxsioVariableSizeBoxChildManager get childManager => _childManager;
  final RenderOnyxsioVariableSizeBoxChildManager _childManager;

  /// The nodes being kept alive despite not being visible.
  final Map<int, RenderBox> _keepAliveBucket = <int, RenderBox>{};

  @override
  void adoptChild(RenderObject child) {
    super.adoptChild(child);
    final childParentData =
        child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
    if (!childParentData._keptAlive) {
      childManager.didAdoptChild(child as RenderBox);
    }
  }

  bool _debugAssertChildListLocked() =>
      childManager.debugAssertChildListLocked();

  @override
  void remove(int index) {
    final RenderBox? child = this[index];

    // if child is null, it means this element was cached - drop the cached element
    if (child == null) {
      final RenderBox? cachedChild = _keepAliveBucket[index];
      if (cachedChild != null) {
        dropChild(cachedChild);
        _keepAliveBucket.remove(index);
      }
      return;
    }

    final childParentData =
        child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
    if (!childParentData._keptAlive) {
      super.remove(index);
      return;
    }
    assert(_keepAliveBucket[childParentData.index!] == child);
    _keepAliveBucket.remove(childParentData.index);
    dropChild(child);
  }

  @override
  void removeAll() {
    super.removeAll();
    _keepAliveBucket.values.forEach(dropChild);
    _keepAliveBucket.clear();
  }

  void _createOrObtainChild(int index) {
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      assert(constraints == this.constraints);
      if (_keepAliveBucket.containsKey(index)) {
        final RenderBox child = _keepAliveBucket.remove(index)!;
        final childParentData =
            child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
        assert(childParentData._keptAlive);
        dropChild(child);
        child.parentData = childParentData;
        this[index] = child;
        childParentData._keptAlive = false;
      } else {
        _childManager.createChild(index);
      }
    });
  }

  void _destroyOrCacheChild(int index) {
    final RenderBox child = this[index]!;
    final childParentData =
        child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
    if (childParentData.keepAlive) {
      assert(!childParentData._keptAlive);
      remove(index);
      _keepAliveBucket[childParentData.index!] = child;
      child.parentData = childParentData;
      super.adoptChild(child);
      childParentData._keptAlive = true;
    } else {
      assert(child.parent == this);
      _childManager.removeChild(child);
      assert(child.parent == null);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (var child in _keepAliveBucket.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (var child in _keepAliveBucket.values) {
      child.detach();
    }
  }

  @override
  void redepthChildren() {
    super.redepthChildren();
    _keepAliveBucket.values.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    super.visitChildren(visitor);
    _keepAliveBucket.values.forEach(visitor);
  }

  bool addChild(int index) {
    assert(_debugAssertChildListLocked());
    _createOrObtainChild(index);
    final child = this[index];
    if (child != null) {
      assert(indexOf(child) == index);
      return true;
    }
    childManager.setDidUnderflow(true);
    return false;
  }

  RenderBox? addAndLayoutChild(
    int index,
    BoxConstraints childConstraints, {
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());
    _createOrObtainChild(index);
    final child = this[index];
    if (child != null) {
      assert(indexOf(child) == index);
      child.layout(childConstraints, parentUsesSize: parentUsesSize);
      return child;
    }
    childManager.setDidUnderflow(true);
    return null;
  }

  @protected
  void collectGarbage(Set<int> visibleIndices) {
    assert(_debugAssertChildListLocked());
    assert(childCount >= visibleIndices.length);
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      // We destroy only those which are not visible.
      indices.toSet().difference(visibleIndices).forEach(_destroyOrCacheChild);
      _keepAliveBucket.values
          .where((RenderBox child) {
            final childParentData =
                child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
            return !childParentData.keepAlive;
          })
          .toList()
          .forEach(_childManager.removeChild);
      assert(_keepAliveBucket.values.where((RenderBox child) {
        final childParentData =
            child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
        return !childParentData.keepAlive;
      }).isEmpty);
    });
  }

  int indexOf(RenderBox child) {
    final childParentData =
        child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
    assert(childParentData.index != null);
    return childParentData.index!;
  }

  @protected
  double paintExtentOf(RenderBox child) {
    assert(child.hasSize);
    switch (constraints.axis) {
      case Axis.horizontal:
        return child.size.width;
      case Axis.vertical:
        return child.size.height;
    }
  }

  @override
  bool hitTestChildren(HitTestResult result,
      {required double mainAxisPosition, required double crossAxisPosition}) {
    for (final child in children) {
      if (hitTestBoxChild(BoxHitTestResult.wrap(result), child,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition)) {
        return true;
      }
    }
    return false;
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    return childScrollOffset(child)! - constraints.scrollOffset;
  }

  @override
  double childCrossAxisPosition(RenderBox child) {
    final childParentData =
        child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
    return childParentData.crossAxisOffset;
  }

  @override
  double? childScrollOffset(RenderObject child) {
    assert(child.parent == this);
    final childParentData =
        child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
    assert(childParentData.layoutOffset != null);
    return childParentData.layoutOffset;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    applyPaintTransformForBoxChild(child as RenderBox, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (childCount == 0) {
      return;
    }
    // offset is to the top-left corner, regardless of our axis direction.
    // originOffset gives us the delta from the real origin to the origin in the axis direction.
    Offset? mainAxisUnit, crossAxisUnit, originOffset;
    bool? addExtent;
    switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        mainAxisUnit = const Offset(0, -1);
        crossAxisUnit = const Offset(1, 0);
        originOffset = offset + Offset(0, geometry!.paintExtent);
        addExtent = true;
        break;
      case AxisDirection.right:
        mainAxisUnit = const Offset(1, 0);
        crossAxisUnit = const Offset(0, 1);
        originOffset = offset;
        addExtent = false;
        break;
      case AxisDirection.down:
        mainAxisUnit = const Offset(0, 1);
        crossAxisUnit = const Offset(1, 0);
        originOffset = offset;
        addExtent = false;
        break;
      case AxisDirection.left:
        mainAxisUnit = const Offset(-1, 0);
        crossAxisUnit = const Offset(0, 1);
        originOffset = offset + Offset(geometry!.paintExtent, 0);
        addExtent = true;
        break;
    }

    for (final child in children) {
      final double mainAxisDelta = childMainAxisPosition(child);
      final double crossAxisDelta = childCrossAxisPosition(child);
      Offset childOffset = Offset(
        originOffset.dx +
            mainAxisUnit.dx * mainAxisDelta +
            crossAxisUnit.dx * crossAxisDelta,
        originOffset.dy +
            mainAxisUnit.dy * mainAxisDelta +
            crossAxisUnit.dy * crossAxisDelta,
      );
      if (addExtent) {
        childOffset += mainAxisUnit * paintExtentOf(child);
      }
      context.paintChild(child, childOffset);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsNode.message(childCount > 0
        ? 'currently live children: ${indices.join(',')}'
        : 'no children current live'));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> childList = <DiagnosticsNode>[];
    if (childCount > 0) {
      for (final child in children) {
        final childParentData =
            child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
        childList.add(child.toDiagnosticsNode(
            name: 'child with index ${childParentData.index}'));
      }
    }
    if (_keepAliveBucket.isNotEmpty) {
      final List<int> indices = _keepAliveBucket.keys.toList()..sort();
      for (final index in indices) {
        childList.add(_keepAliveBucket[index]!.toDiagnosticsNode(
          name: 'child with index $index (kept alive offstage)',
          style: DiagnosticsTreeStyle.offstage,
        ));
      }
    }
    return childList;
  }
}
