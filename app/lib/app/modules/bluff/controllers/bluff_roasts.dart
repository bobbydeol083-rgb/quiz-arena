import 'dart:math';

/// The Bluff & Brain host's roast lines — fired when you vote for a fake.
/// Game-show host energy: playful, never mean.
class BluffRoasts {
  BluffRoasts._();

  static const List<String> _lines = [
    'Ouch. That fake had "liar" written all over it.',
    'Bold choice. Wrong, but bold.',
    'The truth was RIGHT THERE and you walked past it.',
    'My goldfish saw through that one.',
    'That answer fooled exactly… you.',
    'Plot twist: the truth was the boring one.',
    'You just got out-bluffed by your own friend.',
    'Somewhere, a trivia champion is crying.',
    'That fake answer sends its regards.',
    'Confidence: 100. Accuracy: 0.',
    'You voted with your heart. Your heart lied.',
    'Even the fake answers are laughing.',
    'New strategy needed. This one ain\'t it.',
    'The truth called — it feels ignored.',
    'Deceived! Bamboozled! Hoodwinked!',
  ];

  static final _rand = Random();

  static String pick() => _lines[_rand.nextInt(_lines.length)];
}
