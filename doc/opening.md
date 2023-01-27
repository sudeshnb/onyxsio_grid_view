# Opening a Onyxsio GridView

## Use this package as a library

This will add a line like this to your package's pubspec.yaml (and run an implicit flutter pub get). Alternatively, your editor might support flutter pub get. Check the docs for your editor to learn more.

```dart
dependencies:
  onyxsio_grid_view: <latest_version>
```

## Import library

In your library add the following import.

```dart
import 'package:qr_code_scanner/qr_code_scanner.dart';
```

## Usage

Below you'll find the code to create this grid layout.

```dart
    OnyxsioGridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: 20,
        physics: const BouncingScrollPhysics(),
        staggeredTileBuilder: (index) =>
            // OnyxsioStaggeredTile.count(2, index.isEven ? 2 : 1),
            // OnyxsioStaggeredTile.extent(2, index.isEven ? 200 : 50),
            const OnyxsioStaggeredTile.fit(2),
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

<!-- ## Solving exceptions

If you get exception when opening a database:

- check the [troubleshooting](troubleshooting.md) section
- Make sure the directory where you create the database exists
- Make sure the database path points to an existing database (or nothing) and
  not to a file which is not a sqlite database
- Handle any expected exception in the open callbacks (onCreate/onUpgrade/onConfigure/onOpen) -->
