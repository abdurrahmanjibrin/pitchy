class FillerStat {
  final int? id;
  final String sessionId;
  final String fillerWord;
  final int count;

  FillerStat({
    this.id,
    required this.sessionId,
    required this.fillerWord,
    required this.count,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'session_id': sessionId,
        'filler_word': fillerWord,
        'count': count,
      };

  factory FillerStat.fromMap(Map<String, dynamic> map) => FillerStat(
        id: map['id'] as int?,
        sessionId: map['session_id']?.toString() ?? '',
        fillerWord: map['filler_word']?.toString() ?? '',
        count: map['count'] is int
            ? map['count']
            : int.tryParse(map['count']?.toString() ?? '0') ?? 0,
      );
}

