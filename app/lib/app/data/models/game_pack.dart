/// GamePack — a user-publishable custom game (backend: /api/packs).
///
/// A pack bundles its own questions with the mode it was authored for.
/// Browse cards never carry answers; the full detail (with answers) is only
/// returned to the author or on install, so the app can cache it and grade
/// offline play.
class GamePack {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String label;
  final String mode; // 'quiz' | 'bluff'
  final int questionCount;
  final int version;
  final String? authorId;
  final String? authorName;
  final int installs;
  final int plays;
  final String status; // 'draft' | 'published' (only on mine)

  const GamePack({
    required this.id,
    required this.title,
    required this.slug,
    this.description = '',
    this.label = 'Custom',
    this.mode = 'quiz',
    this.questionCount = 0,
    this.version = 1,
    this.authorId,
    this.authorName,
    this.installs = 0,
    this.plays = 0,
    this.status = 'published',
  });

  factory GamePack.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    return GamePack(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? 'Untitled pack'}',
      slug: '${json['slug'] ?? ''}',
      description: '${json['description'] ?? ''}',
      label: '${json['label'] ?? 'Custom'}',
      mode: '${json['mode'] ?? 'quiz'}',
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 1,
      authorId: author is Map ? '${author['id'] ?? ''}' : null,
      authorName: author is Map ? '${author['username'] ?? ''}' : null,
      installs: (json['installs'] as num?)?.toInt() ?? 0,
      plays: (json['plays'] as num?)?.toInt() ?? 0,
      status: '${json['status'] ?? 'published'}',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'description': description,
        'label': label,
        'mode': mode,
        'questionCount': questionCount,
        'version': version,
        'authorId': authorId,
        'authorName': authorName,
        'installs': installs,
        'plays': plays,
        'status': status,
      };
}

/// A single pack question. [answerIndex] is null unless this copy came from
/// the author view or an install (both entitled to grade locally).
class PackQuestion {
  final String question;
  final List<String> options;
  final int? answerIndex;
  final String explanation;

  const PackQuestion({
    required this.question,
    required this.options,
    this.answerIndex,
    this.explanation = '',
  });

  factory PackQuestion.fromJson(Map<String, dynamic> json) {
    return PackQuestion(
      question: '${json['question'] ?? ''}',
      options: ((json['options'] as List?) ?? const [])
          .map((e) => '$e')
          .toList(),
      answerIndex: (json['answerIndex'] as num?)?.toInt(),
      explanation: '${json['explanation'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'answerIndex': answerIndex,
        'explanation': explanation,
      };
}

/// Full pack detail (browse detail / install payload).
class GamePackDetail extends GamePack {
  final List<PackQuestion> questions;

  const GamePackDetail({
    required super.id,
    required super.title,
    required super.slug,
    super.description,
    super.label,
    super.mode,
    super.questionCount,
    super.version,
    super.authorId,
    super.authorName,
    super.installs,
    super.plays,
    super.status,
    this.questions = const [],
  });

  factory GamePackDetail.fromJson(Map<String, dynamic> json) {
    final base = GamePack.fromJson(json);
    return GamePackDetail(
      id: base.id,
      title: base.title,
      slug: base.slug,
      description: base.description,
      label: base.label,
      mode: base.mode,
      questionCount: base.questionCount,
      version: base.version,
      authorId: base.authorId,
      authorName: base.authorName,
      installs: base.installs,
      plays: base.plays,
      status: base.status,
      questions: ((json['questions'] as List?) ?? const [])
          .map((e) => PackQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}
