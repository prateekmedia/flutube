import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pstube/utils/utils.dart';
import 'package:pstube/widgets/video_player.dart';
import 'package:pstube/widgets/video_screen/video_actions.dart';
import 'package:pstube/widgets/video_screen/video_screen.dart';
import 'package:pstube/widgets/vlc_player.dart';
import 'package:pstube/widgets/widgets.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoWidget extends StatelessWidget {
  const VideoWidget({
    Key? key,
    required this.hasData,
    required this.videoData,
    required this.downloadsSideWidget,
    required this.commentSideWidget,
    required this.replyComment,
    required this.snapshot,
    required this.commentsSnapshot,
  }) : super(key: key);

  final bool hasData;
  final Video videoData;
  final ValueNotifier<Widget?> downloadsSideWidget;
  final ValueNotifier<Widget?> commentSideWidget;
  final ValueNotifier<Comment?> replyComment;
  final AsyncSnapshot<StreamManifest> snapshot;
  final AsyncSnapshot<CommentsList?> commentsSnapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (mobVideoPlatforms && hasData)
          VideoPlayer(
            url: snapshot.data!.muxed
                .firstWhere(
                  (element) => element.qualityLabel.contains(
                    '360',
                  ),
                  orElse: () => snapshot.data!.muxed.first,
                )
                .url
                .toString(),
            resolutions: snapshot.data!.muxed.asMap().map(
                  (key, value) => MapEntry(
                    value.qualityLabel,
                    value.url.toString(),
                  ),
                ),
          )
        else if (hasData)
          VlcPlayer(
            url: snapshot.data!.muxed
                .firstWhere(
                  (element) => element.qualityLabel.contains(
                    '360',
                  ),
                  orElse: () => snapshot.data!.muxed.first,
                )
                .url
                .toString(),
            resolutions: snapshot.data!.muxed.asMap().map(
                  (key, value) => MapEntry(
                    value.qualityLabel,
                    value.url.toString(),
                  ),
                ),
          )
        else
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: videoData.thumbnails.mediumResUrl,
                    fit: BoxFit.fill,
                  ),
                ),
                if (mobVideoPlatforms) ...[
                  Container(
                    color: Colors.black.withOpacity(0.25),
                  ),
                  const Align(
                    child: CircularProgressIndicator(),
                  ),
                ]
              ],
            ),
          ),
        Flexible(
          child: Stack(
            children: [
              ListView(
                shrinkWrap: true,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          videoData.title,
                          style: context.textTheme.headline3,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Text(
                              '${videoData.engagement.viewCount.formatNumber}'
                              ' views',
                            ),
                            Text(
                              videoData.publishDate != null
                                  ? '  •  ${timeago.format(
                                      videoData.publishDate!,
                                    )}'
                                  : '',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  VideoActions(
                    videoData: videoData,
                    downloadsSideWidget: downloadsSideWidget,
                    commentSideWidget: commentSideWidget,
                    snapshot: snapshot,
                  ),
                  const Divider(),
                  ChannelInfo(
                    channel: null,
                    channelId: videoData.channelId.value,
                    isOnVideo: true,
                  ),
                  const Divider(height: 4),
                  ListTile(
                    onTap: commentsSnapshot.data == null
                        ? null
                        : commentSideWidget.value != null
                            ? () => commentSideWidget.value = null
                            : () {
                                downloadsSideWidget.value = null;
                                commentSideWidget.value = CommentsWidget(
                                  onClose: () => commentSideWidget.value = null,
                                  replyComment: replyComment,
                                  snapshot: commentsSnapshot,
                                );
                              },
                    title: Text(
                      context.locals.comments,
                    ),
                    trailing: Text(
                      (commentsSnapshot.data != null
                              ? commentsSnapshot.data!.totalLength
                              : 0)
                          .formatNumber,
                    ),
                  ),
                  const Divider(
                    height: 4,
                  ),
                  if (context.isMobile) DescriptionWidget(video: videoData),
                ],
              ),
              if (context.isMobile) ...[
                if (commentSideWidget.value != null) commentSideWidget.value!,
                if (downloadsSideWidget.value != null)
                  downloadsSideWidget.value!
              ],
            ],
          ),
        ),
      ],
    );
  }
}
