import 'dart:convert';
import 'dart:typed_data';

/// Names of the outputs [withBestClass] adds.
const bestClassOutput = 'yoru_best_class';
const bestScoreOutput = 'yoru_best_score';

/// A recognition model ([model], ONNX bytes) that also outputs, for each
/// line and time step, its best class ([bestClassOutput], int64 `[N, T]`)
/// and that class's score ([bestScoreOutput], float `[N, T]`): an ArgMax and
/// a ReduceMax over the last axis of its first output.
///
/// The model's own output is `[N, T, classes]`, some 18,000 classes for
/// Chinese and Japanese: reading it back would move tens of millions of
/// numbers a page. With these, a few hundred per line.
///
/// Edits the protobuf directly: appends nodes and outputs to the graph and
/// leaves everything else as it is.
Uint8List withBestClass(Uint8List model) {
  final reader = _Reader(model);
  var opset = 0;
  ({int start, int end})? graph;
  for (final f in reader.fields(0, model.length)) {
    if (f.number == 7 && f.wire == 2) graph = f.bytes!;
    if (f.number == 8 && f.wire == 2) {
      // OperatorSetIdProto: domain (1), version (2). The default domain
      // is empty or absent.
      var domain = '';
      var version = 0;
      for (final g in reader.fields(f.bytes!.start, f.bytes!.end)) {
        if (g.number == 1) domain = reader.string(g.bytes!);
        if (g.number == 2) version = g.value!;
      }
      if (domain.isEmpty || domain == 'ai.onnx') opset = version;
    }
  }
  if (graph == null) throw const FormatException('No graph in the model');

  String? output;
  for (final f in reader.fields(graph.start, graph.end)) {
    if (f.number == 12 && f.wire == 2) {
      for (final g in reader.fields(f.bytes!.start, f.bytes!.end)) {
        if (g.number == 1) {
          output = reader.string(g.bytes!);
          break;
        }
      }
      break;
    }
  }
  if (output == null) throw const FormatException('No output in the graph');

  final extra = BytesBuilder();
  // ArgMax(axis = -1, keepdims = 0): the best class.
  extra.add(
    _field(
      1,
      _node(
        op: 'ArgMax',
        inputs: [output],
        outputs: [bestClassOutput],
        attributes: [_intAttribute('axis', 2), _intAttribute('keepdims', 0)],
      ),
    ),
  );
  // ReduceMax over the last axis: its score. Axes became an input in
  // opset 18.
  if (opset >= 18) {
    const axes = 'yoru_best_axes';
    extra.add(
      _field(
        1,
        _node(
          op: 'Constant',
          inputs: const [],
          outputs: const [axes],
          attributes: [
            _tensorAttribute('value', _int64Tensor(const [2])),
          ],
        ),
      ),
    );
    extra.add(
      _field(
        1,
        _node(
          op: 'ReduceMax',
          inputs: [output, axes],
          outputs: [bestScoreOutput],
          attributes: [_intAttribute('keepdims', 0)],
        ),
      ),
    );
  } else {
    extra.add(
      _field(
        1,
        _node(
          op: 'ReduceMax',
          inputs: [output],
          outputs: [bestScoreOutput],
          attributes: [
            _intsAttribute('axes', const [2]),
            _intAttribute('keepdims', 0),
          ],
        ),
      ),
    );
  }
  extra.add(_field(12, _valueInfo(bestClassOutput, _int64)));
  extra.add(_field(12, _valueInfo(bestScoreOutput, _float)));

  final patchedGraph = BytesBuilder()
    ..add(Uint8List.sublistView(model, graph.start, graph.end))
    ..add(extra.takeBytes());

  // The model again, its graph field replaced.
  final out = BytesBuilder();
  for (final f in reader.fields(0, model.length)) {
    if (f.number == 7 && f.wire == 2) {
      out.add(_field(7, patchedGraph.takeBytes()));
    } else {
      out.add(Uint8List.sublistView(model, f.start, f.end));
    }
  }
  return out.takeBytes();
}

/// The graph outputs of [model], for checking a patch.
List<String> onnxOutputs(Uint8List model) {
  final reader = _Reader(model);
  final names = <String>[];
  for (final f in reader.fields(0, model.length)) {
    if (f.number != 7 || f.wire != 2) continue;
    for (final g in reader.fields(f.bytes!.start, f.bytes!.end)) {
      if (g.number != 12 || g.wire != 2) continue;
      for (final h in reader.fields(g.bytes!.start, g.bytes!.end)) {
        if (h.number == 1) names.add(reader.string(h.bytes!));
      }
    }
  }
  return names;
}

const _float = 1;
const _int64 = 7;

typedef _Field = ({
  int number,
  int wire,
  int start,
  int end,
  int? value,
  ({int start, int end})? bytes,
});

class _Reader {
  _Reader(this.data);

  final Uint8List data;

  (int, int) _varint(int i) {
    var result = 0;
    var shift = 0;
    while (true) {
      final b = data[i++];
      result |= (b & 0x7f) << shift;
      if (b < 0x80) return (result, i);
      shift += 7;
    }
  }

  Iterable<_Field> fields(int start, int end) sync* {
    var i = start;
    while (i < end) {
      final begin = i;
      final (key, afterKey) = _varint(i);
      i = afterKey;
      final number = key >> 3;
      final wire = key & 7;
      switch (wire) {
        case 0:
          final (v, next) = _varint(i);
          i = next;
          yield (
            number: number,
            wire: wire,
            start: begin,
            end: i,
            value: v,
            bytes: null,
          );
        case 1:
          i += 8;
          yield (
            number: number,
            wire: wire,
            start: begin,
            end: i,
            value: null,
            bytes: null,
          );
        case 2:
          final (length, next) = _varint(i);
          final bytes = (start: next, end: next + length);
          i = next + length;
          yield (
            number: number,
            wire: wire,
            start: begin,
            end: i,
            value: null,
            bytes: bytes,
          );
        case 5:
          i += 4;
          yield (
            number: number,
            wire: wire,
            start: begin,
            end: i,
            value: null,
            bytes: null,
          );
        default:
          throw FormatException('Unknown protobuf wire type $wire');
      }
    }
  }

  String string(({int start, int end}) bytes) =>
      utf8.decode(Uint8List.sublistView(data, bytes.start, bytes.end));
}

Uint8List _varintBytes(int value) {
  final out = BytesBuilder();
  var v = value;
  while (v >= 0x80) {
    out.addByte((v & 0x7f) | 0x80);
    v >>= 7;
  }
  out.addByte(v);
  return out.takeBytes();
}

/// A length-delimited field.
Uint8List _field(int number, List<int> bytes) =>
    (BytesBuilder()
          ..add(_varintBytes(number << 3 | 2))
          ..add(_varintBytes(bytes.length))
          ..add(bytes))
        .takeBytes();

Uint8List _string(int number, String value) =>
    _field(number, utf8.encode(value));

Uint8List _varintField(int number, int value) =>
    (BytesBuilder()
          ..add(_varintBytes(number << 3))
          ..add(_varintBytes(value)))
        .takeBytes();

/// NodeProto: input (1), output (2), name (3), op_type (4), attribute (5).
Uint8List _node({
  required String op,
  required List<String> inputs,
  required List<String> outputs,
  required List<Uint8List> attributes,
}) {
  final b = BytesBuilder();
  for (final i in inputs) {
    b.add(_string(1, i));
  }
  for (final o in outputs) {
    b.add(_string(2, o));
  }
  b
    ..add(_string(3, 'yoru_${outputs.first}'))
    ..add(_string(4, op));
  for (final a in attributes) {
    b.add(_field(5, a));
  }
  return b.takeBytes();
}

/// AttributeProto: name (1), i (3), t (5), ints (8), type (20).
Uint8List _intAttribute(String name, int value) =>
    (BytesBuilder()
          ..add(_string(1, name))
          ..add(_varintField(3, value))
          ..add(_varintField(20, 2)))
        .takeBytes();

Uint8List _intsAttribute(String name, List<int> values) {
  final b = BytesBuilder()..add(_string(1, name));
  for (final v in values) {
    b.add(_varintField(8, v));
  }
  b.add(_varintField(20, 7));
  return b.takeBytes();
}

Uint8List _tensorAttribute(String name, Uint8List tensor) =>
    (BytesBuilder()
          ..add(_string(1, name))
          ..add(_field(5, tensor))
          ..add(_varintField(20, 4)))
        .takeBytes();

/// TensorProto: dims (1), data_type (2), raw_data (9).
Uint8List _int64Tensor(List<int> values) {
  final raw = ByteData(values.length * 8);
  for (final (i, v) in values.indexed) {
    raw.setInt64(i * 8, v, Endian.little);
  }
  return (BytesBuilder()
        ..add(_varintField(1, values.length))
        ..add(_varintField(2, _int64))
        ..add(_field(9, raw.buffer.asUint8List())))
      .takeBytes();
}

/// ValueInfoProto: name (1), type (2) → TypeProto.tensor_type (1) →
/// elem_type (1).
Uint8List _valueInfo(String name, int elementType) =>
    (BytesBuilder()
          ..add(_string(1, name))
          ..add(_field(2, _field(1, _varintField(1, elementType)))))
        .takeBytes();
