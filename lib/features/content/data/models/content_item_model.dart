import '../../../../core/constants/content_types.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/content_item.dart';

extension ContentItemMapper on ContentItem$ {
  ContentItem toDomain() => ContentItem(
        id: id,
        title: title,
        type: ContentType.values.byName(type),
        status: ContentStatus.values.byName(status),
        score: score,
        notes: notes,
        imageUrl: imageUrl,
        externalId: externalId,
        externalSource: externalSource,
        addedAt: addedAt,
        updatedAt: updatedAt,
      );
}

extension ContentItemEntityMapper on ContentItem {
  ContentItemsCompanion toCompanion() => ContentItemsCompanion.insert(
        title: title,
        type: type.name,
        status: status.name,
        score: Value(score),
        notes: Value(notes),
        imageUrl: Value(imageUrl),
        externalId: Value(externalId),
        externalSource: Value(externalSource),
        addedAt: Value(addedAt),
        updatedAt: Value(updatedAt),
      );
}
