class SyncRun {
  SyncRun({
    required this.source,
    required this.startedAt,
    this.finishedAt,
    required this.status,
    this.errorMessage,
    this.recordsCount,
  });

  final String source;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String status;
  final String? errorMessage;
  final int? recordsCount;

  factory SyncRun.fromJson(Map<String, dynamic> json) => SyncRun(
        source: json['source'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt:
            json['finishedAt'] != null ? DateTime.parse(json['finishedAt'] as String) : null,
        status: json['status'] as String,
        errorMessage: json['errorMessage'] as String?,
        recordsCount: json['recordsCount'] as int?,
      );
}
