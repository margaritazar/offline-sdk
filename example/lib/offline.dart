import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_example/main.dart';
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
    return Center(
        child: Column(
      children: [
        OutlinedButton(onPressed: _onPressedDeleteAll, child: Text("Debug Delete All")),
        OutlinedButton(onPressed: _onPressedDownload, child: Text("Debug Download")),
        OutlinedButton(onPressed: _onPressedCancel, child: Text("Debug Cancel Downloading")),
        OutlinedButton(onPressed: _onPressedResult, child: Text("Debug Result")),
        OutlinedButton(onPressed: _onPressedGetAndDelete, child: Text("Debug Get Tiles And Delete")),
      ],
    ));
  }

  Future<void> _onPressedGetAndDelete() async {
    print("Get and Delete Button tapped");
    var ids = await getDownloadedRegionsIds();
    print("Get and Delete: Ids ${ids}");
    if (ids is List) {
      deleteTilesByIds(ids.map((e) => e.toString()).toList());
    }
  }

  void _onPressedDownload() async {
    print("Download Button tapped");
    await downloadOfflineRegion(MockData.mockRegionDefenition, MockData.mockStyleDefenition, channelName: 'testChannelName', accessToken: MapsDemo.ACCESS_TOKEN);
    EventChannel("testChannelName").receiveBroadcastStream().handleError((error) {
      print("Offline Maps Download: Download Error $error");
      return;
    }).listen((data) {
      print("Offline Maps Download: process $data");
    });
  }

  void _onPressedCancel() {
    print("Cancel Downloading tapped");
    cancelDownload();
  }

  void _onPressedDeleteAll() {
    print("Delete All Button tapped");
    deleteAllTilesAndStyles(accessToken: MapsDemo.ACCESS_TOKEN);
  }

  void _onPressedResult() {
    print("Result Button tapped");
    getDownloadedRegionsIds().then((result) => print("Result Button tapped: $result"));
  }
}
