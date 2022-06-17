import 'package:hive_flutter/hive_flutter.dart';
import 'package:newpipeextractor_dart/models/comment.dart';

part 'liked_comment.g.dart';

@HiveType(typeId: 0)
class LikedComment {
  LikedComment({
    required this.channelId,
    required this.author,
    required this.text,
    required this.publishedTime,
    required this.likeCount,
  });

  LikedComment.fromComment(YoutubeComment comment)
      : channelId = comment.uploaderUrl ?? '',
        author = comment.author ?? '',
        text = comment.commentText ?? '',
        publishedTime = comment.uploadDate ?? '',
        likeCount = comment.likeCount ?? 0;

  @HiveField(0)
  String channelId;

  @HiveField(1)
  String author;

  @HiveField(2)
  String text;

  @HiveField(4)
  String publishedTime;

  @HiveField(5)
  int likeCount;
}
