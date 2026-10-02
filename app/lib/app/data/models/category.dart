/// Quiz category (from API or bundled fallback).
class QuizCategory {
  final String id;
  final String name;
  final String icon; // emoji or icon key
  final String colorHex;
  final int quizCount;

  const QuizCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    this.quizCount = 0,
  });

  factory QuizCategory.fromJson(Map<String, dynamic> json) => QuizCategory(
        id: '${json['id']}',
        name: '${json['name']}',
        icon: '${json['icon'] ?? '🧠'}',
        colorHex: '${json['color'] ?? json['colorHex'] ?? '#8B5CF6'}',
        quizCount: (json['quizCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': colorHex,
        'quizCount': quizCount,
      };

  /// Bundled fallback categories matching assets/questions.json.
  static List<QuizCategory> localDefaults() => const [
        QuizCategory(id: 'science', name: 'Science', icon: '🔬', colorHex: '#22D3EE'),
        QuizCategory(id: 'sports', name: 'Sports', icon: '⚽', colorHex: '#34D399'),
        QuizCategory(id: 'history', name: 'History', icon: '🏛️', colorHex: '#FBBF24'),
        QuizCategory(id: 'technology', name: 'Technology', icon: '💻', colorHex: '#8B5CF6'),
        QuizCategory(id: 'geography', name: 'Geography', icon: '🌍', colorHex: '#60A5FA'),
        QuizCategory(id: 'entertainment', name: 'Entertainment', icon: '🎬', colorHex: '#E879F9'),
      ];
}
