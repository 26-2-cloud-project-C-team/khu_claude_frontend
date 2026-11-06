import 'package:flutter/widgets.dart';
import 'package:team_frontend/core/map/app_map.dart';

/// 실제 SDK 없이 [AppMap]을 띄운다. 마지막으로 받은 값과 지도 명령을 기록한다.
class FakeMapViewFactory implements MapViewFactory {
  final controller = FakeMapController();
  LatLng? initialCenter;
  MapOverlays? overlays;

  @override
  Widget create({
    required LatLng initialCenter,
    required MapOverlays overlays,
    ValueChanged<MapController>? onCreated,
  }) {
    this.initialCenter = initialCenter;
    this.overlays = overlays;
    return _FakeMapView(controller: controller, onCreated: onCreated);
  }
}

class FakeMapController implements MapController {
  final fittedBounds = <List<LatLng>>[];
  final movedTo = <LatLng>[];

  @override
  void fitBounds(List<LatLng> points, {EdgeInsets padding = EdgeInsets.zero}) {
    fittedBounds.add(points);
  }

  @override
  void moveTo(LatLng point) => movedTo.add(point);
}

class _FakeMapView extends StatefulWidget {
  const _FakeMapView({required this.controller, this.onCreated});

  final FakeMapController controller;
  final ValueChanged<MapController>? onCreated;

  @override
  State<_FakeMapView> createState() => _FakeMapViewState();
}

class _FakeMapViewState extends State<_FakeMapView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onCreated?.call(widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
