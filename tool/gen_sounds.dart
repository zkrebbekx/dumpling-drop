// Generates every sound asset as a 16-bit mono WAV file.
//
// Run from the repo root:
//   dart run tool/gen_sounds.dart
//
// All audio is synthesized, so the game ships with zero licensed
// assets and works fully offline.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 22050;

void main() {
  final out = Directory('assets/audio');
  out.createSync(recursive: true);

  write('click', _click());
  write('move', _move());
  write('rotate', _rotate());
  write('drop', _drop());
  write('squish', _squish());
  write('pop', _pop());
  write('feast', _feast());
  write('combo', _combo());
  write('fanfare', _fanfare());
  write('sad', _sad());
  write('star', _star());
  write('badge', _badge());
  write('bgm', _bgm());
  stdout.writeln('Wrote ${out.listSync().length} files to ${out.path}');
}

void write(String name, List<double> samples) {
  final file = File('assets/audio/$name.wav');
  file.writeAsBytesSync(wav(samples));
  stdout.writeln('  $name.wav  ${(samples.length / sampleRate).toStringAsFixed(2)}s');
}

// ---------- Synthesis helpers ----------

List<double> silence(double seconds) =>
    List.filled((seconds * sampleRate).round(), 0.0);

/// A tone with a pitch sweep, percussive envelope, and optional vibrato.
List<double> tone({
  required double f0,
  double? f1,
  required double seconds,
  double gain = 0.8,
  double attack = 0.005,
  double harmonics = 0.0,
  double vibratoHz = 0.0,
  double vibratoDepth = 0.0,
}) {
  final n = (seconds * sampleRate).round();
  final samples = List<double>.filled(n, 0);
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / n;
    var f = f1 == null ? f0 : f0 + (f1 - f0) * t;
    if (vibratoHz > 0) {
      f += vibratoDepth * sin(2 * pi * vibratoHz * i / sampleRate);
    }
    phase += 2 * pi * f / sampleRate;
    var s = sin(phase);
    if (harmonics > 0) s += harmonics * sin(2 * phase) * 0.5;
    final env = _env(i / sampleRate, seconds, attack);
    samples[i] = s * env * gain;
  }
  return samples;
}

/// A soft noise burst, for thuds and puffs.
List<double> noise({
  required double seconds,
  double gain = 0.3,
  int smooth = 8,
}) {
  final rng = Random(7);
  final n = (seconds * sampleRate).round();
  final raw = List<double>.generate(n, (_) => rng.nextDouble() * 2 - 1);
  final samples = List<double>.filled(n, 0);
  var acc = 0.0;
  for (var i = 0; i < n; i++) {
    acc += (raw[i] - acc) / smooth; // cheap low-pass
    samples[i] = acc * _env(i / sampleRate, seconds, 0.002) * gain;
  }
  return samples;
}

double _env(double t, double seconds, double attack) {
  if (t < attack) return t / attack;
  final rest = (t - attack) / (seconds - attack);
  return pow(1 - rest, 2.2).toDouble();
}

List<double> mix(List<List<double>> parts) {
  final n = parts.map((p) => p.length).reduce(max);
  final out = List<double>.filled(n, 0);
  for (final part in parts) {
    for (var i = 0; i < part.length; i++) {
      out[i] += part[i];
    }
  }
  return out;
}

List<double> seq(List<List<double>> parts) =>
    [for (final p in parts) ...p];

/// Overlay [part] onto [base] starting at [at] seconds.
List<double> at(List<double> base, List<double> part, double atSeconds) {
  final start = (atSeconds * sampleRate).round();
  final n = max(base.length, start + part.length);
  final out = List<double>.filled(n, 0)..setAll(0, base);
  for (var i = 0; i < part.length; i++) {
    out[start + i] += part[i];
  }
  return out;
}

Uint8List wav(List<double> samples) {
  // Normalize with headroom.
  var peak = 0.0;
  for (final s in samples) {
    peak = max(peak, s.abs());
  }
  final scale = peak > 0 ? 0.9 / peak : 0.0;

  final data = ByteData(44 + samples.length * 2);
  void str(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, (samples[i] * scale * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

// ---------- The sounds ----------

List<double> _click() => tone(f0: 650, f1: 480, seconds: 0.05, gain: 0.5);

List<double> _move() => tone(f0: 340, seconds: 0.035, gain: 0.35);

List<double> _rotate() => tone(f0: 420, f1: 720, seconds: 0.07, gain: 0.45);

List<double> _drop() => mix([
      tone(f0: 260, f1: 110, seconds: 0.12, gain: 0.8, harmonics: 0.4),
      noise(seconds: 0.08, gain: 0.25),
    ]);

List<double> _squish() => tone(
      f0: 520,
      f1: 180,
      seconds: 0.16,
      gain: 0.7,
      vibratoHz: 28,
      vibratoDepth: 40,
      harmonics: 0.3,
    );

List<double> _popOne(double f) => mix([
      tone(f0: f, f1: f * 1.6, seconds: 0.07, gain: 0.7),
      noise(seconds: 0.03, gain: 0.15),
    ]);

List<double> _pop() => at(
      at(_popOne(560), _popOne(700), 0.07),
      _popOne(880),
      0.14,
    );

List<double> _feast() {
  var s = _pop();
  s = at(s, _popOne(1050), 0.21);
  s = at(s, tone(f0: 1046, seconds: 0.18, gain: 0.4, harmonics: 0.6), 0.28);
  s = at(s, tone(f0: 1318, seconds: 0.22, gain: 0.4, harmonics: 0.6), 0.36);
  s = at(s, tone(f0: 1568, seconds: 0.3, gain: 0.45, harmonics: 0.6), 0.44);
  return s;
}

List<double> _combo() => seq([
      tone(f0: 660, seconds: 0.07, gain: 0.5),
      tone(f0: 880, seconds: 0.1, gain: 0.55),
    ]);

List<double> _fanfare() {
  var s = silence(1.1);
  const notes = [523.25, 659.25, 783.99, 1046.5];
  for (var i = 0; i < notes.length; i++) {
    s = at(s, tone(f0: notes[i], seconds: 0.22, gain: 0.55, harmonics: 0.5), i * 0.13);
  }
  s = at(
      s,
      mix([
        tone(f0: 523.25, seconds: 0.5, gain: 0.35, harmonics: 0.4),
        tone(f0: 659.25, seconds: 0.5, gain: 0.3, harmonics: 0.4),
        tone(f0: 783.99, seconds: 0.5, gain: 0.3, harmonics: 0.4),
      ]),
      0.55);
  return s;
}

List<double> _sad() => seq([
      tone(f0: 392, seconds: 0.22, gain: 0.4, harmonics: 0.3),
      tone(f0: 330, seconds: 0.22, gain: 0.4, harmonics: 0.3),
      tone(f0: 262, seconds: 0.4, gain: 0.4, harmonics: 0.3),
    ]);

List<double> _star() => mix([
      tone(f0: 1568, seconds: 0.25, gain: 0.5),
      tone(f0: 2093, seconds: 0.2, gain: 0.25),
    ]);

List<double> _badge() => seq([
      tone(f0: 784, seconds: 0.12, gain: 0.5, harmonics: 0.5),
      tone(f0: 1175, seconds: 0.3, gain: 0.55, harmonics: 0.5),
    ]);

/// A gentle pentatonic loop, about nine seconds, quiet and warm.
List<double> _bgm() {
  const bpm = 108.0;
  final beat = 60.0 / bpm;
  // C major pentatonic, two relaxed phrases.
  const melody = [
    523.25, 587.33, 659.25, 783.99, // C D E G
    659.25, 587.33, 523.25, 440.00, // E D C A4
    523.25, 659.25, 783.99, 880.00, // C E G A5
    783.99, 659.25, 587.33, 523.25, // G E D C
  ];
  const bass = [261.63, 220.0, 174.61, 196.0]; // C A F G
  var s = silence(beat * 16 + 0.4);
  for (var i = 0; i < melody.length; i++) {
    s = at(
        s,
        tone(
            f0: melody[i],
            seconds: beat * 0.9,
            gain: 0.30,
            attack: 0.01,
            harmonics: 0.25),
        i * beat);
  }
  for (var i = 0; i < bass.length; i++) {
    s = at(
        s,
        tone(
            f0: bass[i],
            seconds: beat * 3.6,
            gain: 0.16,
            attack: 0.03,
            harmonics: 0.15),
        i * beat * 4);
  }
  // Trim to an exact loop length.
  return s.sublist(0, (beat * 16 * sampleRate).round());
}
