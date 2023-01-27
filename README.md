<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# Onyxsio Grid View

Provides a Flutter grids layout.

## Getting started

In the `pubspec.yaml` of your flutter project, add the following dependency:

```yaml
dependencies:
  onyxsio_grid_view: <latest_version>
```

In your library add the following import:

```dart
import 'package:onyxsio_grid_view/onyxsio_grid_view.dart';
```

For help getting started with Flutter, view the online [documentation][flutter_documentation].

## Features

This layout facilitates the browsing of uncropped peer content. Container heights are sized based on the widget size.

### UI

![Staired Grid Layout][staired_preview]

## Usage

Below you'll find the code to create this grid layout:

```dart
      OnyxsioGridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: 20,
        physics: const BouncingScrollPhysics(),
        staggeredTileBuilder: (index) => const OnyxsioStaggeredTile.fit(2),
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        shrinkWrap: true,
        itemBuilder: (context, index) => OnyxsioGridTile(
          index: index,
          heightList: const [300, 220, 220, 520],
          child: Container(color: Colors.blue),
        ),
      )
```

### Optional information

```dart
staggeredTileBuilder: (index) =>
  OnyxsioStaggeredTile.count(2, index.isEven ? 2 : 1),

```

### Optional information

```dart
staggeredTileBuilder: (index) =>
  OnyxsioStaggeredTile.extent(2, index.isEven ? 200 : 50),
```

## Additional information

I'm working on my packages on my free-time, but I don't have as much time as I would. If this package or any other package I created is helping you, please consider to sponsor me so that I can take time to read the issues, fix bugs, merge pull requests and add features to these packages.

<!-- [![Pub][pub_badge]][pub] [![BuyMeACoffee][buy_me_a_coffee_badge]][buy_me_a_coffee] -->

## Contributions

Feel free to contribute to this project.

If you find a bug or want a feature, but don't know how to fix/implement it, please fill an [issue][issue].  
If you fixed a bug or implemented a feature, please send a [pull request][pr].

<!-- Links -->

[issue]: https://github.com/sudeshnb/onyxsio_grid_view/issues
[pr]: https://github.com/sudeshnb/onyxsio_grid_view/pulls
[flutter_documentation]: https://docs.flutter.dev/
[pub]: https://pub.dartlang.org/packages/onyxsio_grid_view
[staired_preview]: https://user-images.githubusercontent.com/33403844/214500635-7860d799-67c7-4f98-b031-725bc0e1922c.png

<!-- [buy_me_a_coffee]: https://www.buymeacoffee.com/sudeshnb -->
<!-- [buy_me_a_coffee_badge]: https://user-images.githubusercontent.com/33403844/214502169-982df8a4-a758-44e7-8c0f-cc85fd29547e.svg -->
