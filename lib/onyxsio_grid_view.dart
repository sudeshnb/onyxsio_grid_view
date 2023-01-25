// ignore_for_file: must_be_immutable

library onyxsio_grid_view;

import 'package:flutter/widgets.dart';
import 'src/onyxsio.dart';
import 'src/onyxsio_staggered_grid.dart';

class OnyxsioGridView extends BoxScrollView {
  OnyxsioGridView({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    required this.gridDelegate,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    List<Widget> children = const <Widget>[],
    String? restorationId,
  })  : childrenDelegate = SliverChildListDelegate(
          children,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
        ),
        super(
          key: key,
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          restorationId: restorationId,
        );

  OnyxsioGridView.builder({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    required int crossAxisCount,
    required OnyxsioIndexedWidgetBuilder itemBuilder,
    required IndexedStaggeredTileBuilder staggeredTileBuilder,
    int? itemCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    String? restorationId,
  })  : gridDelegate = SliverStaggeredGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          staggeredTileBuilder: staggeredTileBuilder,
          staggeredTileCount: itemCount,
        ),
        childrenDelegate = SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
        ),
        super(
          key: key,
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          restorationId: restorationId,
        );

  final OnyxsioStaggeredGridDelegate gridDelegate;

  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return OnyxsioStaggeredGrid(
      delegate: childrenDelegate,
      gridDelegate: gridDelegate,
    );
  }
}

// typedef IndexedWidgetBuilder = Widget Function(BuildContext context, int index);

typedef OnyxsioIndexedWidgetBuilder = OnyxsioGridTile Function(
    BuildContext context, int index);

class OnyxsioGridTile extends StatelessWidget {
  OnyxsioGridTile(
      {Key? key,
      this.defaultHeight = 200.0,
      required this.heightList,
      required this.child,
      required this.index})
      : super(key: key);
  int index;
  Widget child;
  double defaultHeight;
  List<double> heightList;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: getMinHeight(index)),
      child: child,
    );
  }

  /// To return different height for different widgets
  double getMinHeight(int index) {
    for (var i = 0; i < heightList.length; i++) {
      // if (index == (index % deived))
      if (index == i) {
        return heightList[i];
      }
    }
    return defaultHeight;
  }
}
