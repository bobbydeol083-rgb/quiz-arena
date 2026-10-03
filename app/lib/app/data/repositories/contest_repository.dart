import 'package:quiz_arena/app/data/providers/api_service.dart';

class ContestQuestion {
  final int index;
  final String question;
  final List<String> options;

  const ContestQuestion({
    required this.index,
    required this.question,
    required this.options,
  });

  factory ContestQuestion.fromJson(Map<String, dynamic> json) =>
      ContestQuestion(
        index: (json['index'] as num?)?.toInt() ?? 0,
        question: '${json['question'] ?? ''}',
        options:
            ((json['options'] as List?) ?? []).map((e) => '$e').toList(),
      );
}

class ContestCard {
  final String id;
  final String name;
  final String description;
  final String image;
  final DateTime? startDate;
  final DateTime? endDate;
  final int entryFee;
  final String phase; // live | upcoming | ended | inactive
  final int prizePool;
  final int prizeCount;
  final int questionCount;
  final int participants;
  final bool played;

  const ContestCard({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.startDate,
    required this.endDate,
    required this.entryFee,
    required this.phase,
    required this.prizePool,
    required this.prizeCount,
    required this.questionCount,
    required this.participants,
    required this.played,
  });

  factory ContestCard.fromJson(Map<String, dynamic> json) => ContestCard(
        id: '${json['id']}',
        name: '${json['name'] ?? ''}',
        description: '${json['description'] ?? ''}',
        image: '${json['image'] ?? ''}',
        startDate: DateTime.tryParse('${json['startDate'] ?? ''}'),
        endDate: DateTime.tryParse('${json['endDate'] ?? ''}'),
        entryFee: (json['entryFee'] as num?)?.toInt() ?? 0,
        phase: '${json['phase'] ?? 'upcoming'}',
        prizePool: (json['prizePool'] as num?)?.toInt() ?? 0,
        prizeCount: (json['prizeCount'] as num?)?.toInt() ?? 0,
        questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
        participants: (json['participants'] as num?)?.toInt() ?? 0,
        played: json['played'] == true,
      );
}

class ContestRepository {
  final ApiService api;

  ContestRepository({required this.api});

  Future<List<ContestCard>> list() async {
    final json = await api.getJson('/contests');
    final list = (json as Map)['contests'] as List? ?? [];
    return list
        .map((e) => ContestCard.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> detail(String id) async {
    final json = await api.getJson('/contests/$id');
    return Map<String, dynamic>.from(json as Map);
  }

  /// Join a live contest: pays the entry fee, returns questions + coin balance.
  Future<({List<ContestQuestion> questions, int coins})> join(String id) async {
    final json = await api.postJson('/contests/$id/join', body: {});
    final map = Map<String, dynamic>.from(json as Map);
    final qs = ((map['questions'] as List?) ?? [])
        .map((e) => ContestQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return (questions: qs, coins: (map['coins'] as num?)?.toInt() ?? 0);
  }

  Future<Map<String, dynamic>> submit(String id, List<int> answers) async {
    final json = await api.postJson('/contests/$id/submit', body: {'answers': answers});
    return Map<String, dynamic>.from(json as Map);
  }

  Future<List<Map<String, dynamic>>> leaderboard(String id) async {
    final json = await api.getJson('/contests/$id/leaderboard');
    final list = (json as Map)['leaderboard'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> transactions({int limit = 20}) async {
    final json = await api.getJson('/rewards/transactions', query: {'limit': '$limit'});
    return Map<String, dynamic>.from(json as Map);
  }
}
