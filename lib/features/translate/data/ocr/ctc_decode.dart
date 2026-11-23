/// Text read by a recognition model, with its mean confidence.
typedef Recognized = ({String text, double score});

/// Greedy CTC decoding of one line from its best class at each of [steps]
/// time steps ([best], with its [scores]), starting at [offset]: repeats
/// merged and blanks (class 0) dropped. Classes are blank, then
/// [dictionary], then a space (PaddleOCR's `use_space_char`).
Recognized ctcDecode(
  List<int> best,
  List<double> scores, {
  required int offset,
  required int steps,
  required List<String> dictionary,
}) {
  final text = StringBuffer();
  var previous = 0;
  var total = 0.0;
  var kept = 0;
  for (var t = offset; t < offset + steps; t++) {
    final c = best[t];
    if (c != 0 && c != previous) {
      text.write(c - 1 < dictionary.length ? dictionary[c - 1] : ' ');
      total += scores[t];
      kept++;
    }
    previous = c;
  }
  return (text: text.toString().trim(), score: kept == 0 ? 0 : total / kept);
}
