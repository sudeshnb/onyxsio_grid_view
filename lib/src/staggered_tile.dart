class OnyxsioStaggeredTile {
  const OnyxsioStaggeredTile.count(
      this.crossAxisCellCount, this.mainAxisCellCount)
      : assert(crossAxisCellCount >= 0),
        assert(mainAxisCellCount != null && mainAxisCellCount >= 0),
        mainAxisExtent = null;

  const OnyxsioStaggeredTile.extent(
      this.crossAxisCellCount, this.mainAxisExtent)
      : assert(crossAxisCellCount >= 0),
        assert(mainAxisExtent != null && mainAxisExtent >= 0),
        mainAxisCellCount = null;

  const OnyxsioStaggeredTile.fit(this.crossAxisCellCount)
      : assert(crossAxisCellCount >= 0),
        mainAxisExtent = null,
        mainAxisCellCount = null;

  /// The number of cells occupied in the cross axis.
  final int crossAxisCellCount;

  /// The number of cells occupied in the main axis.
  final double? mainAxisCellCount;

  /// The number of pixels occupied in the main axis.
  final double? mainAxisExtent;

  bool get fitContent => mainAxisCellCount == null && mainAxisExtent == null;
}
