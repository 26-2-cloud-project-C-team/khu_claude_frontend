// 시작 화면(US-00) Lottie 히어로를 생성한다.
// 실행: dart run tool/generate_start_hero.dart → assets/lottie/start_hero.json
import 'dart:convert';
import 'dart:io';

const _fps = 60;
const _end = 180;
const _w = 700;
const _h = 360;

const _primary = [0xA4, 0x0F, 0x16];
const _primaryTint = [0xFB, 0xED, 0xEE];
const _blue = [0x0D, 0x32, 0x6F];
const _gray900 = [0x19, 0x1F, 0x28];
const _ground = [0xEE, 0xF2, 0xF5];
const _lawn = [0xE1, 0xEE, 0xE4];
const _building = [0xDB, 0xE1, 0xE8];
const _white = [0xFF, 0xFF, 0xFF];

const _dot = [230.0, 300.0];
const _pin = [536.0, 160.0];

List<double> _rgba(List<int> c) => [c[0] / 255, c[1] / 255, c[2] / 255, 1];

Map<String, Object> _static(Object k) => {'a': 0, 'k': k};

Map<String, Object> _anim(List<(int, List<double>)> keys) {
  final frames = <Map<String, Object>>[];
  for (var i = 0; i < keys.length; i++) {
    final (t, s) = keys[i];
    frames.add({
      't': t,
      's': s,
      if (i < keys.length - 1) ...{
        'o': {'x': [0.33], 'y': [0]},
        'i': {'x': [0.25], 'y': [1]},
      },
    });
  }
  return {'a': 1, 'k': frames};
}

Map<String, Object> _transform({
  List<double> p = const [0, 0, 0],
  Object? position,
  Object? scale,
  Object? opacity,
}) => {
  'o': opacity ?? _static(100),
  'r': _static(0),
  'p': position ?? _static(p),
  'a': _static([0, 0, 0]),
  's': scale ?? _static([100, 100, 100]),
};

Map<String, Object> _groupTransform() => {
  'ty': 'tr',
  'p': _static([0, 0]),
  'a': _static([0, 0]),
  's': _static([100, 100]),
  'r': _static(0),
  'o': _static(100),
};

Map<String, Object> _fill(List<int> c, [double opacity = 100]) => {
  'ty': 'fl',
  'c': _static(_rgba(c)),
  'o': _static(opacity),
  'r': 1,
};

Map<String, Object> _stroke(List<int> c, double width) => {
  'ty': 'st',
  'c': _static(_rgba(c)),
  'o': _static(100),
  'w': _static(width),
  'lc': 2,
  'lj': 2,
  'ml': 4,
};

Map<String, Object> _rect(double x, double y, double w, double h, double r) => {
  'ty': 'rc',
  'p': _static([x + w / 2, y + h / 2]),
  's': _static([w, h]),
  'r': _static(r),
};

Map<String, Object> _ellipse(double x, double y, Object size) => {
  'ty': 'el',
  'p': _static([x, y]),
  's': size is Map ? size : _static(size),
};

Map<String, Object> _path(List<List<double>> points, {bool closed = false}) => {
  'ty': 'sh',
  'ks': _static({
    'i': [for (final _ in points) [0, 0]],
    'o': [for (final _ in points) [0, 0]],
    'v': points,
    'c': closed,
  }),
};

Map<String, Object> _group(String name, List<Map<String, Object>> items) => {
  'ty': 'gr',
  'nm': name,
  'it': [...items, _groupTransform()],
};

Map<String, Object> _shapeLayer(
  int index,
  String name,
  List<Map<String, Object>> shapes, {
  Map<String, Object>? transform,
}) => {
  'ddd': 0,
  'ind': index,
  'ty': 4,
  'nm': name,
  'sr': 1,
  'ks': transform ?? _transform(),
  'ao': 0,
  'shapes': shapes,
  'ip': 0,
  'op': _end,
  'st': 0,
  'bm': 0,
};

final _routePoints = [
  _dot,
  [230.0, 196.0],
  [536.0, 196.0],
  [_pin[0], _pin[1] + 4],
];

Map<String, Object> _map(int index) => _shapeLayer(index, 'map', [
  _group('lawn', [_rect(36, 36, 168, 128, 18), _fill(_lawn)]),
  _group('buildings', [
    _rect(270, 36, 140, 124, 14),
    _rect(36, 236, 160, 96, 14),
    _rect(270, 236, 150, 96, 14),
    _rect(460, 236, 204, 96, 14),
    _fill(_building),
  ]),
  _group('destination', [_rect(446, 36, 218, 124, 14), _fill(_primaryTint)]),
  _group('roads', [
    _rect(0, 182, _w.toDouble(), 28, 0),
    _rect(216, 0, 28, _h.toDouble(), 0),
    _rect(428, 196, 22, (_h - 196).toDouble(), 0),
    _fill(_white),
  ]),
  _group('ground', [_rect(0, 0, _w.toDouble(), _h.toDouble(), 0), _fill(_ground)]),
]);

Map<String, Object> _route(int index) {
  Map<String, Object> trim() => {
    'ty': 'tm',
    's': _static(0),
    'e': _anim([(84, [0]), (156, [100])]),
    'o': _static(0),
    'm': 1,
  };
  return _shapeLayer(index, 'route', [
    _group('line', [_path(_routePoints), trim(), _stroke(_primary, 9)]),
    _group('outline', [_path(_routePoints), trim(), _stroke(_white, 17)]),
  ]);
}

Map<String, Object> _currentLocation(int index) => _shapeLayer(
  index,
  'current-location',
  [
    _group('dot', [_ellipse(0, 0, [20, 20]), _fill(_blue)]),
    _group('ring', [_ellipse(0, 0, [32, 32]), _fill(_white)]),
    _group('halo', [
      _ellipse(0, 0, _anim([(8, [0, 0]), (40, [96, 96]), (60, [64, 64])])),
      _fill(_blue, 18),
    ]),
  ],
  transform: _transform(
    p: [..._dot, 0],
    scale: _anim([(0, [0, 0, 100]), (22, [115, 115, 100]), (32, [100, 100, 100])]),
  ),
);

Map<String, Object> _destinationPin(int index) => _shapeLayer(
  index,
  'pin',
  [
    _group('hole', [_ellipse(0, -36, [16, 16]), _fill(_white)]),
    _group('head', [_ellipse(0, -36, [44, 44]), _fill(_primary)]),
    _group('tip', [_path([[-19, -27], [19, -27], [0, 0]], closed: true), _fill(_primary)]),
  ],
  transform: _transform(
    position: _anim([
      (36, [_pin[0], _pin[1] - 80, 0]),
      (62, [_pin[0], _pin[1] + 6, 0]),
      (72, [_pin[0], _pin[1], 0]),
    ]),
    opacity: _anim([(36, [0]), (46, [100])]),
  ),
);

const _bubbleIndex = 2;
const _bubbleBottom = 92.0;

Map<String, Object> _bubble() => _shapeLayer(
  _bubbleIndex,
  'bubble',
  [
    _group('box', [
      _rect(-150, -56, 300, 50, 25),
      _path([[-10, -7], [10, -7], [0, 4]], closed: true),
      _fill(_white),
    ]),
    _group('shadow', [_rect(-150, -54, 300, 52, 26), _fill(_gray900, 10)]),
  ],
  transform: _transform(
    p: [_pin[0], _bubbleBottom, 0],
    scale: _anim([(66, [0, 0, 100]), (82, [106, 106, 100]), (90, [100, 100, 100])]),
    opacity: _anim([(66, [0]), (74, [100])]),
  ),
);

Map<String, Object> _bubbleText() => {
  'ddd': 0,
  'ind': 1,
  'ty': 5,
  'nm': 'bubble-text',
  'parent': _bubbleIndex,
  'sr': 1,
  'ks': _transform(p: [0, -24, 0]),
  'ao': 0,
  't': {
    'd': {
      'k': [
        {
          's': {
            's': 22,
            'f': 'Pretendard-SemiBold',
            't': '지금 이용 가능 · 도보 3분',
            'j': 2,
            'tr': 0,
            'lh': 26,
            'ls': 0,
            'fc': _rgba(_gray900).sublist(0, 3),
          },
          't': 0,
        },
      ],
    },
    'p': <String, Object>{},
    'm': {'g': 1, 'a': _static([0, 0])},
    'a': <Object>[],
  },
  'ip': 0,
  'op': _end,
  'st': 0,
  'bm': 0,
};

void main() {
  final composition = {
    'v': '5.7.4',
    'fr': _fps,
    'ip': 0,
    'op': _end,
    'w': _w,
    'h': _h,
    'nm': 'start_hero',
    'ddd': 0,
    'assets': <Object>[],
    'fonts': {
      'list': [
        {'fName': 'Pretendard-SemiBold', 'fFamily': 'Pretendard', 'fStyle': 'SemiBold', 'ascent': 75},
      ],
    },
    'layers': [
      _bubbleText(),
      _bubble(),
      _destinationPin(3),
      _currentLocation(4),
      _route(5),
      _map(6),
    ],
  };
  final file = File('assets/lottie/start_hero.json')..createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(composition));
  stdout.writeln('wrote ${file.path} (${file.lengthSync()} bytes)');
}
