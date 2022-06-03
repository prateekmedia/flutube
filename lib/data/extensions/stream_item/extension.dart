import 'package:piped_api/piped_api.dart';
import 'package:pstube/data/services/constants.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

extension Stream2Video on StreamItem {
  Video get toVideo => Video(
        VideoId('${Constants.ytCom}$url'),
        title,
        uploaderName ?? '',
        ChannelId('${Constants.ytCom}$uploaderUrl'),
        DateTime.now(),
        DateTime.now(),
        '',
        Duration(seconds: duration),
        ThumbnailSet(url.replaceAll('/watch?v=', '')),
        [''],
        Engagement(views ?? 0, 0, 0),
        false,
      );
}
