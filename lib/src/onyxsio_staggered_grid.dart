import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'staggered_tile.dart';
import 'onyxsio_variable_size_box_adaptor.dart';

/// Signature for a function that creates [OnyxsioStaggeredTile] for a given index.
typedef OnyxsioIndexedStaggeredTileBuilder = OnyxsioStaggeredTile? Function(
    int index);

/// Specifies how a staggered grid is configured.
@immutable
class OnyxsioStaggeredGridConfiguration {
  ///  Creates an object that holds the configuration of a staggered grid.
  const OnyxsioStaggeredGridConfiguration({
    required this.crossAxisCount,
    required this.staggeredTileBuilder,
    required this.cellExtent,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.reverseCrossAxis,
    required this.staggeredTileCount,
    this.mainAxisOffsetsCacheSize = 3,
  })  : assert(crossAxisCount > 0),
        assert(cellExtent >= 0),
        assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        assert(mainAxisOffsetsCacheSize > 0),
        cellStride = cellExtent + crossAxisSpacing;

  /// The maximum number of children in the cross axis.
  final int crossAxisCount;

  /// The number of pixels from the leading edge of one cell to the trailing
  /// edge of the same cell in both axis.
  final double cellExtent;

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  /// Called to get the tile at the specified index for the

  final OnyxsioIndexedStaggeredTileBuilder staggeredTileBuilder;

  /// The total number of tiles this delegate can provide.

  final int? staggeredTileCount;

  final bool reverseCrossAxis;

  final double cellStride;

  /// The number of pages necessary to cache a mainAxisOffsets value.
  final int mainAxisOffsetsCacheSize;

  List<double> generateMainAxisOffsets() =>
      List.generate(crossAxisCount, (i) => 0.0);

  /// Gets a normalized tile for the given index.
  OnyxsioStaggeredTile? getStaggeredTile(int index) {
    OnyxsioStaggeredTile? tile;
    if (staggeredTileCount == null || index < staggeredTileCount!) {
      // There is maybe a tile for this index.
      tile = _normalizeStaggeredTile(staggeredTileBuilder(index));
    }
    return tile;
  }

  /// Computes the main axis extent of any staggered tile.
  double _getStaggeredTileMainAxisExtent(OnyxsioStaggeredTile tile) {
    return tile.mainAxisExtent ??
        (tile.mainAxisCellCount! * cellExtent) +
            (tile.mainAxisCellCount! - 1) * mainAxisSpacing;
  }

  /// Creates a staggered tile with the computed extent from the given tile.
  OnyxsioStaggeredTile? _normalizeStaggeredTile(
      OnyxsioStaggeredTile? staggeredTile) {
    if (staggeredTile == null) {
      return null;
    } else {
      final crossAxisCellCount =
          staggeredTile.crossAxisCellCount.clamp(0, crossAxisCount).toInt();
      if (staggeredTile.fitContent) {
        return OnyxsioStaggeredTile.fit(crossAxisCellCount);
      } else {
        return OnyxsioStaggeredTile.extent(
            crossAxisCellCount, _getStaggeredTileMainAxisExtent(staggeredTile));
      }
    }
  }
}

class _Block {
  const _Block(this.index, this.crossAxisCount, this.minOffset, this.maxOffset);

  final int index;
  final int crossAxisCount;
  final double minOffset;
  final double maxOffset;
}

const double _epsilon = 0.0001;

bool _nearEqual(double d1, double d2) {
  return (d1 - d2).abs() < _epsilon;
}

@immutable
class OnyxsioStaggeredGridGeometry {
  /// Creates an object that describes the placement of a child in a RenderSliverStaggeredGrid.
  const OnyxsioStaggeredGridGeometry({
    required this.scrollOffset,
    required this.crossAxisOffset,
    required this.mainAxisExtent,
    required this.crossAxisExtent,
    required this.crossAxisCellCount,
    required this.blockIndex,
  });

  /// The scroll offset of the leading edge of the child relative to the leading
  /// edge of the parent.
  final double scrollOffset;

  /// The offset of the child in the non-scrolling axis.
  ///
  /// If the scroll axis is vertical, this offset is from the left-most edge of
  /// the parent to the left-most edge of the child. If the scroll axis is
  /// horizontal, this offset is from the top-most edge of the parent to the
  /// top-most edge of the child.
  final double crossAxisOffset;

  /// The extent of the child in the scrolling axis.
  ///
  /// If the scroll axis is vertical, this extent is the child's height. If the
  /// scroll axis is horizontal, this extent is the child's width.
  final double? mainAxisExtent;

  /// The extent of the child in the non-scrolling axis.
  ///
  /// If the scroll axis is vertical, this extent is the child's width. If the
  /// scroll axis is horizontal, this extent is the child's height.
  final double crossAxisExtent;

  final int crossAxisCellCount;

  final int blockIndex;

  bool get hasTrailingScrollOffset => mainAxisExtent != null;

  /// The scroll offset of the trailing edge of the child relative to the
  /// leading edge of the parent.
  double get trailingScrollOffset => scrollOffset + (mainAxisExtent ?? 0);

  OnyxsioStaggeredGridGeometry copyWith({
    double? scrollOffset,
    double? crossAxisOffset,
    double? mainAxisExtent,
    double? crossAxisExtent,
    int? crossAxisCellCount,
    int? blockIndex,
  }) {
    return OnyxsioStaggeredGridGeometry(
      scrollOffset: scrollOffset ?? this.scrollOffset,
      crossAxisOffset: crossAxisOffset ?? this.crossAxisOffset,
      mainAxisExtent: mainAxisExtent ?? this.mainAxisExtent,
      crossAxisExtent: crossAxisExtent ?? this.crossAxisExtent,
      crossAxisCellCount: crossAxisCellCount ?? this.crossAxisCellCount,
      blockIndex: blockIndex ?? this.blockIndex,
    );
  }

  /// Returns a tight [BoxConstraints] that forces the child to have the
  /// required size.
  BoxConstraints getBoxConstraints(SliverConstraints constraints) {
    return constraints.asBoxConstraints(
      minExtent: mainAxisExtent ?? 0.0,
      maxExtent: mainAxisExtent ?? double.infinity,
      crossAxisExtent: crossAxisExtent,
    );
  }

  @override
  String toString() {
    return 'SliverStaggeredGridGeometry('
        'scrollOffset: $scrollOffset, '
        'crossAxisOffset: $crossAxisOffset, '
        'mainAxisExtent: $mainAxisExtent, '
        'crossAxisExtent: $crossAxisExtent, '
        'crossAxisCellCount: $crossAxisCellCount, '
        'startIndex: $blockIndex)';
  }
}

///    array with a fixed extent in the main axis.
class RenderOnyxsioStaggeredGrid extends RenderOnyxsioVariableSizeBoxAdaptor {
  /// Creates a sliver that contains multiple box children that whose size and
  /// position are determined by a delegate.
  ///
  /// The [configuration] and [childManager] arguments must not be null.
  RenderOnyxsioStaggeredGrid({
    required RenderOnyxsioVariableSizeBoxChildManager childManager,
    required OnyxsioStaggeredGridDelegate gridDelegate,
  })  : _gridDelegate = gridDelegate,
        _pageSizeToViewportOffsets =
            HashMap<double, SplayTreeMap<int, _ViewportOffsets?>>(),
        super(childManager: childManager);

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! OnyxsioVariableSizeBoxAdaptorParentData) {
      final data = OnyxsioVariableSizeBoxAdaptorParentData();

      // By default we will keep it true.
      //data.keepAlive = true;
      child.parentData = data;
    }
  }

  /// The delegate that controls the configuration of the staggered grid.
  OnyxsioStaggeredGridDelegate get gridDelegate => _gridDelegate;
  OnyxsioStaggeredGridDelegate _gridDelegate;
  set gridDelegate(OnyxsioStaggeredGridDelegate value) {
    if (_gridDelegate == value) {
      return;
    }
    if (value.runtimeType != _gridDelegate.runtimeType ||
        value.shouldRelayout(_gridDelegate)) {
      markNeedsLayout();
    }
    _gridDelegate = value;
  }

  final HashMap<double, SplayTreeMap<int, _ViewportOffsets?>>
      _pageSizeToViewportOffsets;

  @override
  void performLayout() {
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    bool reachedEnd = false;
    double trailingScrollOffset = 0;
    double leadingScrollOffset = double.infinity;
    bool visible = false;
    int firstIndex = 0;
    int lastIndex = 0;

    final configuration = _gridDelegate.getConfiguration(constraints);

    final pageSize = configuration.mainAxisOffsetsCacheSize *
        constraints.viewportMainAxisExtent;
    if (pageSize == 0.0) {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }
    final pageIndex = scrollOffset ~/ pageSize;
    assert(pageIndex >= 0);

    // If the viewport is resized, we keep the in memory the old offsets caches. (Useful if only the orientation changes multiple times).
    final viewportOffsets = _pageSizeToViewportOffsets.putIfAbsent(
        pageSize, () => SplayTreeMap<int, _ViewportOffsets?>());

    _ViewportOffsets? viewportOffset;
    if (viewportOffsets.isEmpty) {
      viewportOffset =
          _ViewportOffsets(configuration.generateMainAxisOffsets(), pageSize);
      viewportOffsets[0] = viewportOffset;
    } else {
      final smallestKey = viewportOffsets.lastKeyBefore(pageIndex + 1);
      viewportOffset = viewportOffsets[smallestKey!];
    }

    // A staggered grid always have to layout the child from the zero-index based one to the last visible.
    final mainAxisOffsets = viewportOffset!.mainAxisOffsets.toList();
    final visibleIndices = HashSet<int>();

    // Iterate through all children while they can be visible.
    for (var index = viewportOffset.firstChildIndex;
        mainAxisOffsets.any((o) => o <= targetEndScrollOffset);
        index++) {
      OnyxsioStaggeredGridGeometry? geometry =
          getSliverStaggeredGeometry(index, configuration, mainAxisOffsets);
      if (geometry == null) {
        // There are either no children, or we are past the end of all our children.
        reachedEnd = true;
        break;
      }

      final bool hasTrailingScrollOffset = geometry.hasTrailingScrollOffset;
      RenderBox? child;
      if (!hasTrailingScrollOffset) {
        // Layout the child to compute its tailingScrollOffset.
        final constraints =
            BoxConstraints.tightFor(width: geometry.crossAxisExtent);
        child = addAndLayoutChild(index, constraints, parentUsesSize: true);
        geometry = geometry.copyWith(mainAxisExtent: paintExtentOf(child!));
      }

      if (!visible &&
          targetEndScrollOffset >= geometry.scrollOffset &&
          scrollOffset <= geometry.trailingScrollOffset) {
        visible = true;
        leadingScrollOffset = geometry.scrollOffset;
        firstIndex = index;
      }

      if (visible && hasTrailingScrollOffset) {
        child =
            addAndLayoutChild(index, geometry.getBoxConstraints(constraints));
      }

      if (child != null) {
        final childParentData =
            child.parentData! as OnyxsioVariableSizeBoxAdaptorParentData;
        childParentData.layoutOffset = geometry.scrollOffset;
        childParentData.crossAxisOffset = geometry.crossAxisOffset;
        assert(childParentData.index == index);
      }

      if (visible && indices.contains(index)) {
        visibleIndices.add(index);
      }

      if (geometry.trailingScrollOffset >=
          viewportOffset!.trailingScrollOffset) {
        final nextPageIndex = viewportOffset.pageIndex + 1;
        final nextViewportOffset = _ViewportOffsets(mainAxisOffsets,
            (nextPageIndex + 1) * pageSize, nextPageIndex, index);
        viewportOffsets[nextPageIndex] = nextViewportOffset;
        viewportOffset = nextViewportOffset;
      }

      final double endOffset =
          geometry.trailingScrollOffset + configuration.mainAxisSpacing;
      for (var i = 0; i < geometry.crossAxisCellCount; i++) {
        mainAxisOffsets[i + geometry.blockIndex] = endOffset;
      }

      trailingScrollOffset = mainAxisOffsets.reduce(math.max);
      lastIndex = index;
    }

    collectGarbage(visibleIndices);

    if (!visible) {
      if (scrollOffset > viewportOffset!.trailingScrollOffset) {
        // We are outside the bounds, we have to correct the scroll.
        final viewportOffsetScrollOffset = pageSize * viewportOffset.pageIndex;
        final correction = viewportOffsetScrollOffset - scrollOffset;
        geometry = SliverGeometry(
          scrollOffsetCorrection: correction,
        );
      } else {
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
      }
      return;
    }

    double estimatedMaxScrollOffset;
    if (reachedEnd) {
      estimatedMaxScrollOffset = trailingScrollOffset;
    } else {
      estimatedMaxScrollOffset = childManager.estimateMaxScrollOffset(
        constraints,
        firstIndex: firstIndex,
        lastIndex: lastIndex,
        leadingScrollOffset: leadingScrollOffset,
        trailingScrollOffset: trailingScrollOffset,
      );
      assert(estimatedMaxScrollOffset >=
          trailingScrollOffset - leadingScrollOffset);
    }

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: trailingScrollOffset > targetEndScrollOffset ||
          constraints.scrollOffset > 0.0,
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a child.
    if (estimatedMaxScrollOffset == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }

  static OnyxsioStaggeredGridGeometry? getSliverStaggeredGeometry(int index,
      OnyxsioStaggeredGridConfiguration configuration, List<double> offsets) {
    final tile = configuration.getStaggeredTile(index);
    if (tile == null) {
      return null;
    }

    final block = _findFirstAvailableBlockWithCrossAxisCount(
        tile.crossAxisCellCount, offsets);

    final scrollOffset = block.minOffset;
    var blockIndex = block.index;
    if (configuration.reverseCrossAxis) {
      blockIndex =
          configuration.crossAxisCount - tile.crossAxisCellCount - blockIndex;
    }
    final crossAxisOffset = blockIndex * configuration.cellStride;
    final geometry = OnyxsioStaggeredGridGeometry(
      scrollOffset: scrollOffset,
      crossAxisOffset: crossAxisOffset,
      mainAxisExtent: tile.mainAxisExtent,
      crossAxisExtent: configuration.cellStride * tile.crossAxisCellCount -
          configuration.crossAxisSpacing,
      crossAxisCellCount: tile.crossAxisCellCount,
      blockIndex: block.index,
    );
    return geometry;
  }

  /// Finds the first available block with at least the specified [crossAxisCount] in the [offsets] list.
  static _Block _findFirstAvailableBlockWithCrossAxisCount(
      int crossAxisCount, List<double> offsets) {
    return _findFirstAvailableBlockWithCrossAxisCountAndOffsets(
        crossAxisCount, List.from(offsets));
  }

  /// Finds the first available block with at least the specified [crossAxisCount].
  static _Block _findFirstAvailableBlockWithCrossAxisCountAndOffsets(
      int crossAxisCount, List<double> offsets) {
    final block = _findFirstAvailableBlock(offsets);
    if (block.crossAxisCount < crossAxisCount) {
      // Not enough space for the specified cross axis count.
      // We have to fill this block and try again.
      for (var i = 0; i < block.crossAxisCount; ++i) {
        offsets[i + block.index] = block.maxOffset;
      }
      return _findFirstAvailableBlockWithCrossAxisCountAndOffsets(
          crossAxisCount, offsets);
    } else {
      return block;
    }
  }

  /// Finds the first available block for the specified [offsets] list.
  static _Block _findFirstAvailableBlock(List<double> offsets) {
    int index = 0;
    double minBlockOffset = double.infinity;
    double maxBlockOffset = double.infinity;
    int crossAxisCount = 1;
    bool contiguous = false;

    // We have to use the _nearEqual function because of floating-point arithmetic.
    // Ex: 0.1 + 0.2 = 0.30000000000000004 and not 0.3.

    for (var i = index; i < offsets.length; ++i) {
      final offset = offsets[i];
      if (offset < minBlockOffset && !_nearEqual(offset, minBlockOffset)) {
        index = i;
        maxBlockOffset = minBlockOffset;
        minBlockOffset = offset;
        crossAxisCount = 1;
        contiguous = true;
      } else if (_nearEqual(offset, minBlockOffset) && contiguous) {
        crossAxisCount++;
      } else if (offset < maxBlockOffset &&
          offset > minBlockOffset &&
          !_nearEqual(offset, minBlockOffset)) {
        contiguous = false;
        maxBlockOffset = offset;
      } else {
        contiguous = false;
      }
    }

    return _Block(index, crossAxisCount, minBlockOffset, maxBlockOffset);
  }
}

class _ViewportOffsets {
  _ViewportOffsets(
    List<double> mainAxisOffsets,
    this.trailingScrollOffset, [
    this.pageIndex = 0,
    this.firstChildIndex = 0,
  ]) : mainAxisOffsets = mainAxisOffsets.toList();

  final int pageIndex;

  final int firstChildIndex;

  final double trailingScrollOffset;

  final List<double> mainAxisOffsets;

  @override
  String toString() =>
      '[$pageIndex-$trailingScrollOffset] ($firstChildIndex, $mainAxisOffsets)';
}

abstract class OnyxsioStaggeredGridDelegate {
  /// Creates a delegate that makes staggered grid layouts

  const OnyxsioStaggeredGridDelegate({
    required this.staggeredTileBuilder,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.staggeredTileCount,
  })  : assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0);

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  final OnyxsioIndexedStaggeredTileBuilder staggeredTileBuilder;

  final int? staggeredTileCount;

  bool _debugAssertIsValid() {
    assert(mainAxisSpacing >= 0);
    assert(crossAxisSpacing >= 0);
    return true;
  }

  /// Returns information about the staggered grid configuration.
  OnyxsioStaggeredGridConfiguration getConfiguration(
      SliverConstraints constraints);

  bool shouldRelayout(OnyxsioStaggeredGridDelegate oldDelegate) {
    return oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.staggeredTileCount != staggeredTileCount ||
        oldDelegate.staggeredTileBuilder != staggeredTileBuilder;
  }
}

class SliverStaggeredGridDelegateWithFixedCrossAxisCount
    extends OnyxsioStaggeredGridDelegate {
  const SliverStaggeredGridDelegateWithFixedCrossAxisCount({
    required this.crossAxisCount,
    required OnyxsioIndexedStaggeredTileBuilder staggeredTileBuilder,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    int? staggeredTileCount,
  })  : assert(crossAxisCount > 0),
        super(
          staggeredTileBuilder: staggeredTileBuilder,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          staggeredTileCount: staggeredTileCount,
        );

  /// The number of children in the cross axis.
  final int crossAxisCount;

  @override
  bool _debugAssertIsValid() {
    assert(crossAxisCount > 0);
    return super._debugAssertIsValid();
  }

  @override
  OnyxsioStaggeredGridConfiguration getConfiguration(
      SliverConstraints constraints) {
    assert(_debugAssertIsValid());
    final double usableCrossAxisExtent =
        constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double cellExtent = usableCrossAxisExtent / crossAxisCount;
    return OnyxsioStaggeredGridConfiguration(
      crossAxisCount: crossAxisCount,
      staggeredTileBuilder: staggeredTileBuilder,
      staggeredTileCount: staggeredTileCount,
      cellExtent: cellExtent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(
      covariant SliverStaggeredGridDelegateWithFixedCrossAxisCount
          oldDelegate) {
    return oldDelegate.crossAxisCount != crossAxisCount ||
        super.shouldRelayout(oldDelegate);
  }
}

class SliverStaggeredGridDelegateWithMaxCrossAxisExtent
    extends OnyxsioStaggeredGridDelegate {
  const SliverStaggeredGridDelegateWithMaxCrossAxisExtent({
    required this.maxCrossAxisExtent,
    required OnyxsioIndexedStaggeredTileBuilder staggeredTileBuilder,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    int? staggeredTileCount,
  })  : assert(maxCrossAxisExtent > 0),
        super(
          staggeredTileBuilder: staggeredTileBuilder,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          staggeredTileCount: staggeredTileCount,
        );

  /// The maximum extent of tiles in the cross axis.
  ///
  /// This delegate will select a cross-axis extent for the tiles that is as
  /// large as possible subject to the following conditions:
  ///
  ///  - The extent evenly divides the cross-axis extent of the grid.
  ///  - The extent is at most [maxCrossAxisExtent].
  ///
  /// For example, if the grid is vertical, the grid is 500.0 pixels wide, and
  /// [maxCrossAxisExtent] is 150.0, this delegate will create a grid with 4
  /// columns that are 125.0 pixels wide.
  final double maxCrossAxisExtent;

  @override
  bool _debugAssertIsValid() {
    assert(maxCrossAxisExtent >= 0);
    return super._debugAssertIsValid();
  }

  @override
  OnyxsioStaggeredGridConfiguration getConfiguration(
      SliverConstraints constraints) {
    assert(_debugAssertIsValid());
    final int crossAxisCount =
        ((constraints.crossAxisExtent + crossAxisSpacing) /
                (maxCrossAxisExtent + crossAxisSpacing))
            .ceil();

    final double usableCrossAxisExtent =
        constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);

    final double cellExtent = usableCrossAxisExtent / crossAxisCount;
    return OnyxsioStaggeredGridConfiguration(
      crossAxisCount: crossAxisCount,
      staggeredTileBuilder: staggeredTileBuilder,
      staggeredTileCount: staggeredTileCount,
      cellExtent: cellExtent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(
      covariant SliverStaggeredGridDelegateWithMaxCrossAxisExtent oldDelegate) {
    return oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent ||
        super.shouldRelayout(oldDelegate);
  }
}
