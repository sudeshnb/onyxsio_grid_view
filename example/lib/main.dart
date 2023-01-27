import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:onyxsio_grid_view/onyxsio_grid_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onyxsio GridView builder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Onyxsio GridView builder"),
      ),
      body: OnyxsioGridView.builder(
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
      ),
    );
  }
}
