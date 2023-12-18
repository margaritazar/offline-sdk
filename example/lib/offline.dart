import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'page.dart';

class OfflinePage extends ExamplePage {
  OfflinePage() : super(const Icon(Icons.map), 'Offline');

  @override
  Widget build(BuildContext context) {
    return const OfflinePageBody();
  }
}

class OfflinePageBody extends StatefulWidget {
  const OfflinePageBody();

  @override
  State<StatefulWidget> createState() => OfflinePageBodyState();
}

class OfflinePageBodyState extends State<OfflinePageBody> {
  OfflinePageBodyState();

  @override
  Widget build(BuildContext context) {
    return Center(child: OutlinedButton(onPressed: _onPressed, child: Text("Debug")));
  }

  void _onPressed() {
    print("Button tapped");
    downloadOfflineRegion(MockData.mockRegionDefenition);
  }
}
