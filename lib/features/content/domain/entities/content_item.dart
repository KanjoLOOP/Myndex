import '../../../../core/constants/content_types.dart';

class ContentItem {
  final int? id;
  final String title;
  final ContentType type;
  final ContentStatus status;
  final double? score;
  final String? notes;
  final String? imageUrl;
  final String? externalId;
  final String? externalSource;
  final DateTime addedAt;
  final DateTime updatedAt;

  const ContentItem({
    this.id,
    required this.title,
    required this.type,
    required this.status,
    this.score,
    this.notes,
    this.imageUrl,
    this.externalId,
    this.externalSource,
    required this.addedAt,
    required this.updatedAt,
  });

  ContentItem copyWith({
    int? id,
    String? title,
    ContentType? type,
    ContentStatus? status,
    double? score,
    String? notes,
    String? imageUrl,
    String? externalId,
    String? externalSource,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      score: score ?? this.score,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      externalId: externalId ?? this.externalId,
      externalSource: externalSource ?? this.externalSource,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'status': status.name,
        'score': score,
        'notes': notes,
        'imageUrl': imageUrl,
        'externalId': externalId,
        'externalSource': externalSource,
        'addedAt': addedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
        id: json['id'] as int?,
        title: json['title'] as String,
        type: ContentType.values.byName(json['type'] as String),
        status: ContentStatus.values.byName(json['status'] as String),
        score: (json['score'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        imageUrl: json['imageUrl'] as String?,
        externalId: json['externalId'] as String?,
        externalSource: json['externalSource'] as String?,
        addedAt: DateTime.parse(json['addedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
