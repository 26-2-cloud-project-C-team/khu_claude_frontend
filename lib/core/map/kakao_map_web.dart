import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'app_map.dart';
import 'map_placeholder.dart';

class KakaoMapView extends StatefulWidget {
  const KakaoMapView({
    super.key,
    required this.appKey,
    required this.initialCenter,
    required this.overlays,
    this.onCreated,
  });

  final String appKey;
  final LatLng initialCenter;
  final MapOverlays overlays;
  final ValueChanged<MapController>? onCreated;

  @override
  State<KakaoMapView> createState() => _KakaoMapViewState();
}

class _KakaoMapViewState extends State<KakaoMapView> {
  late final Future<void> _sdk = _loadSdk(widget.appKey);
  _KakaoMapController? _controller;
  web.ResizeObserver? _resizeObserver;

  @override
  void didUpdateWidget(KakaoMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlays != widget.overlays) {
      _controller?.draw(widget.overlays);
    }
  }

  @override
  void dispose() {
    _resizeObserver?.disconnect();
    super.dispose();
  }

  void _onElementCreated(Object element) {
    final container = element as web.HTMLElement;
    container.style
      ..width = '100%'
      ..height = '100%'
      // SDK가 지도 안쪽 요소에 z-index를 주므로, 그 값이 지도 위에 그린 Flutter 위젯을 덮지 않게 가둔다.
      ..setProperty('isolation', 'isolate');

    // 요소는 화면에 붙은 뒤에야 크기가 생긴다. 크기가 0일 때 지도를 만들면 일부만 그려지므로,
    // 실제 크기가 잡힌 뒤에 만들고 이후 크기가 바뀔 때마다 다시 잰다.
    _resizeObserver = web.ResizeObserver(
      (JSArray<web.ResizeObserverEntry> _, web.ResizeObserver _) {
        if (container.clientWidth == 0 || container.clientHeight == 0) return;
        final controller = _controller;
        if (controller != null) {
          controller.map.relayout();
          return;
        }
        _createMap(container);
      }.toJS,
    )..observe(container);
  }

  void _createMap(web.HTMLElement container) {
    final map = _KMap(
      container,
      _KMapOptions(center: _latLng(widget.initialCenter), level: 3),
    );
    final controller = _KakaoMapController(map)..draw(widget.overlays);
    _controller = controller;
    widget.onCreated?.call(controller);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appKey.isEmpty) {
      return const MapPlaceholder('KAKAO_MAP_KEY가 설정되지 않았어요');
    }
    return FutureBuilder<void>(
      future: _sdk,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const MapPlaceholder('지도를 불러오지 못했어요');
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const MapPlaceholder('');
        }
        return HtmlElementView.fromTagName(
          tagName: 'div',
          onElementCreated: _onElementCreated,
        );
      },
    );
  }
}

class _KakaoMapController implements MapController {
  _KakaoMapController(this.map);

  final _KMap map;

  static const _primary = '#A40F16';
  static const _primaryTint = '#FBEDEE';
  static const _khuBlue = '#0D326F';
  static const _white = '#FFFFFF';

  // 도착 판정 거리(30m)와 같은 반경으로 목적 건물 주변을 칠한다.
  static const _destinationRadiusM = 30;

  late final _routeOutline = _KPolyline(
    _KPolylineOptions(strokeWeight: 9, strokeColor: _white, strokeOpacity: 1),
  );
  late final _routeLine = _KPolyline(
    _KPolylineOptions(strokeWeight: 5, strokeColor: _primary, strokeOpacity: 1),
  );
  late final _destinationArea = _KCircle(
    _KCircleOptions(
      radius: _destinationRadiusM,
      strokeWeight: 0,
      fillColor: _primaryTint,
      fillOpacity: 0.7,
    ),
  );
  late final _destinationPin = _KCustomOverlay(
    _KCustomOverlayOptions(content: _pinHtml.toJS, xAnchor: 0.5, yAnchor: 1),
  );
  late final _currentLocationDot = _KCustomOverlay(
    _KCustomOverlayOptions(content: _dotHtml.toJS, xAnchor: 0.5, yAnchor: 0.5),
  );

  static const _pinHtml =
      '<svg width="28" height="36" viewBox="0 0 28 36" style="display:block" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M14 0C6.3 0 0 6.2 0 13.9 0 24.3 14 36 14 36s14-11.7 14-22.1C28 6.2 21.7 0 14 0z" fill="$_primary"/>'
      '<circle cx="14" cy="14" r="5" fill="$_white"/></svg>';

  static const _dotHtml =
      '<div style="width:16px;height:16px;border-radius:50%;background:$_khuBlue;'
      'border:3px solid $_white;box-shadow:0 0 0 6px rgba(13,50,111,0.2);box-sizing:border-box"></div>';

  void draw(MapOverlays overlays) {
    final route = overlays.route;
    if (route.length >= 2) {
      final path = [for (final p in route) _latLng(p)].toJS;
      _routeOutline
        ..setPath(path)
        ..setMap(map);
      _routeLine
        ..setPath(path)
        ..setMap(map);
    } else {
      _routeOutline.setMap(null);
      _routeLine.setMap(null);
    }

    final destination = overlays.destination;
    if (destination != null) {
      final position = _latLng(destination);
      _destinationArea
        ..setPosition(position)
        ..setMap(map);
      _destinationPin
        ..setPosition(position)
        ..setMap(map);
    } else {
      _destinationArea.setMap(null);
      _destinationPin.setMap(null);
    }

    final current = overlays.currentLocation;
    if (current != null) {
      _currentLocationDot
        ..setPosition(_latLng(current))
        ..setMap(map);
    } else {
      _currentLocationDot.setMap(null);
    }
  }

  @override
  void fitBounds(
    List<LatLng> points, {
    EdgeInsets padding = const EdgeInsets.all(48),
  }) {
    if (points.isEmpty) return;
    final bounds = _KLatLngBounds();
    for (final point in points) {
      bounds.extend(_latLng(point));
    }
    map.setBounds(
      bounds,
      padding.top,
      padding.right,
      padding.bottom,
      padding.left,
    );
  }

  @override
  void moveTo(LatLng point) => map.panTo(_latLng(point));
}

_KLatLng _latLng(LatLng point) => _KLatLng(point.lat, point.lng);

Future<void>? _sdkLoading;

/// SDK 스크립트를 한 번만 넣는다. `autoload=false`라 `kakao.maps.load`가 끝나야 지도를 만들 수 있다.
Future<void> _loadSdk(String appKey) {
  return _sdkLoading ??= () async {
    final loaded = Completer<void>();
    final script = web.HTMLScriptElement()
      ..src =
          'https://dapi.kakao.com/v2/maps/sdk.js?appkey=$appKey&autoload=false'
      ..async = true;
    script
      ..addEventListener('load', ((web.Event _) => loaded.complete()).toJS)
      ..addEventListener(
        'error',
        ((web.Event _) => loaded.completeError(
          StateError('카카오맵 SDK를 불러오지 못했습니다'),
        )).toJS,
      );
    web.document.head!.append(script);
    await loaded.future;

    final ready = Completer<void>();
    _kakaoMapsLoad((() => ready.complete()).toJS);
    await ready.future;
  }();
}

@JS('kakao.maps.load')
external void _kakaoMapsLoad(JSFunction callback);

@JS('kakao.maps.LatLng')
extension type _KLatLng._(JSObject _) implements JSObject {
  external factory _KLatLng(double lat, double lng);
}

@JS('kakao.maps.LatLngBounds')
extension type _KLatLngBounds._(JSObject _) implements JSObject {
  external factory _KLatLngBounds();

  external void extend(_KLatLng point);
}

extension type _KMapOptions._(JSObject _) implements JSObject {
  external factory _KMapOptions({_KLatLng center, int level});
}

@JS('kakao.maps.Map')
extension type _KMap._(JSObject _) implements JSObject {
  external factory _KMap(web.HTMLElement container, _KMapOptions options);

  external void relayout();
  external void setCenter(_KLatLng center);
  external void panTo(_KLatLng center);
  external void setBounds(
    _KLatLngBounds bounds,
    double paddingTop,
    double paddingRight,
    double paddingBottom,
    double paddingLeft,
  );
}

extension type _KPolylineOptions._(JSObject _) implements JSObject {
  external factory _KPolylineOptions({
    int strokeWeight,
    String strokeColor,
    double strokeOpacity,
  });
}

@JS('kakao.maps.Polyline')
extension type _KPolyline._(JSObject _) implements JSObject {
  external factory _KPolyline(_KPolylineOptions options);

  external void setPath(JSArray<_KLatLng> path);
  external void setMap(_KMap? map);
}

extension type _KCircleOptions._(JSObject _) implements JSObject {
  external factory _KCircleOptions({
    int radius,
    int strokeWeight,
    String fillColor,
    double fillOpacity,
  });
}

@JS('kakao.maps.Circle')
extension type _KCircle._(JSObject _) implements JSObject {
  external factory _KCircle(_KCircleOptions options);

  external void setPosition(_KLatLng position);
  external void setMap(_KMap? map);
}

extension type _KCustomOverlayOptions._(JSObject _) implements JSObject {
  external factory _KCustomOverlayOptions({
    JSString content,
    double xAnchor,
    double yAnchor,
  });
}

@JS('kakao.maps.CustomOverlay')
extension type _KCustomOverlay._(JSObject _) implements JSObject {
  external factory _KCustomOverlay(_KCustomOverlayOptions options);

  external void setPosition(_KLatLng position);
  external void setMap(_KMap? map);
}
