import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:libadwaita/libadwaita.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:open_file/open_file.dart';
import 'package:pstube/data/extensions/extensions.dart';

import 'package:pstube/data/models/models.dart';
import 'package:pstube/ui/screens/screens.dart';
import 'package:pstube/ui/states/download_list/download_list.dart';
import 'package:pstube/ui/states/states.dart';
import 'package:pstube/ui/widgets/widgets.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadListUtils = ref.watch(downloadListProvider);
    final downloadList = downloadListUtils.downloadList;
    return AdwClamp.scrollable(
      maximumSize: 800,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          if (downloadList.isEmpty) ...[
            const SizedBox(height: 60),
            const Icon(LucideIcons.download, size: 30),
            const SizedBox(height: 10),
            Text(context.locals.noDownloadsFound).center()
          ] else
            for (DownloadItem item in downloadList)
              DownloadItemBuilder(
                item: item,
                downloadListUtils: downloadListUtils,
              ),
        ],
      ),
    );
  }
}

class DownloadItemBuilder extends StatelessWidget {
  const DownloadItemBuilder({
    super.key,
    required this.item,
    required this.downloadListUtils,
  });

  final DownloadItem item;
  final DownloadList downloadListUtils;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.total != 0 && item.total == item.downloaded
          ? () => OpenFile.open(item.queryVideo.path + item.queryVideo.name)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                context.pushPage(
                  VideoScreen(
                    video: null,
                    videoId: item.queryVideo.id,
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 60,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: item.queryVideo.thumbnail,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: const Alignment(0.98, 0.94),
                        child: IconWithLabel(
                          label:
                              item.queryVideo.duration.parseDuration().format(),
                          secColor: SecColor.dark,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.queryVideo.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        IconWithLabel(
                          label:
                              '${((item.downloaded / item.total) * 100).toStringAsFixed(1)}%',
                        ),
                        const SizedBox(width: 5),
                        IconWithLabel(label: item.total.getFileSize()),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: LinearProgressIndicator(
                        value:
                            item.total != 0 ? item.downloaded / item.total : 0,
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AdwButton.circular(
              onPressed: item.total == 0 ||
                      item.total == item.downloaded ||
                      item.cancelToken != null && item.cancelToken!.isCancelled
                  ? () {
                      final deleteFromStorage = ValueNotifier<bool>(true);
                      showPopoverForm(
                        context: context,
                        title: context.locals.confirm,
                        builder: (ctx) => ValueListenableBuilder<bool>(
                          valueListenable: deleteFromStorage,
                          builder: (_, value, ___) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.locals.clearItemFromDownloadList,
                                  style: context.textTheme.bodyText1,
                                ),
                                CheckboxListTile(
                                  value: value,
                                  onChanged: (val) =>
                                      deleteFromStorage.value = val!,
                                  title: Text(
                                    context.locals.alsoDeleteThemFromStorage,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        confirmText: context.locals.yes,
                        onConfirm: () {
                          if (File(
                                item.queryVideo.path + item.queryVideo.name,
                              ).existsSync() &&
                              deleteFromStorage.value) {
                            File(item.queryVideo.path + item.queryVideo.name)
                                .deleteSync();
                          }
                          downloadListUtils.removeDownload(item.queryVideo);
                          context.back();
                        },
                      );
                    }
                  : () {
                      item.cancelToken!.cancel();
                      downloadListUtils.refresh();
                    },
              child: Icon(
                item.cancelToken != null && item.cancelToken!.isCancelled
                    ? LucideIcons.minus
                    : item.total != 0 && item.total != item.downloaded
                        ? LucideIcons.x
                        : LucideIcons.trash,
              ),
            )
          ],
        ),
      ),
    );
  }
}
