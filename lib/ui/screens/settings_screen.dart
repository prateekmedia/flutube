import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:libadwaita/libadwaita.dart';
import 'package:libadwaita_bitsdojo/libadwaita_bitsdojo.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:piped_api/piped_api.dart';
import 'package:pstube/config/info/app_info.dart';
import 'package:pstube/data/extensions/extensions.dart';
import 'package:pstube/data/services/services.dart';
import 'package:pstube/ui/states/states.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  late String version = '';

  @override
  void initState() {
    super.initState();
    http
        .get(
      Uri.parse(
        'https://api.github.com/repos/prateekmedia/pstube/releases',
      ),
    )
        .then((http.Response response) async {
      // ignore: implicit_dynamic_invoke
      await compute(
        jsonDecode,
        response.body,
      ).then(
        (dynamic value) => setState(
          () {
            final json = value as List<Map<String, String>>;
            version = json.first['tag_name']!;
          },
        ),
      );
    }).catchError((dynamic exception) {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final path = ref.watch(downloadPathProvider).path;
    return AdwClamp.scrollable(
      child: AdwPreferencesGroup(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          AdwActionRow(
            title: context.locals.downloadFolder,
            subtitle: path,
            onActivated: () async => ref.read(downloadPathProvider).path =
                await FilePicker.platform.getDirectoryPath(
              dialogTitle: context.locals.chooseDownloadFolder,
            ),
          ),
          AdwSwitchRow(
            title: context.locals.darkMode,
            value: context.isDark,
            onChanged: (bool value) =>
                ref.read(themeTypeProvider.notifier).toggle = value,
          ),
          AdwSwitchRow(
            title: context.locals.thumbnailDownloader,
            subtitle: context.locals.showThumbnailDownloaderInDownloadPopup,
            value: ref.watch(thumbnailDownloaderProvider),
            onChanged: (bool value) =>
                ref.read(thumbnailDownloaderProvider.notifier).value = value,
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final hasData = snapshot.hasData && snapshot.data != null;
              final isLatest = hasData && version.isNotEmpty
                  ? version == snapshot.data!.version
                  : null;
              return AdwActionRow(
                title: context.locals.update,
                onActivated: hasData && isLatest != null
                    ? (isLatest
                        ? null
                        : '${AppInfo.myApp.url}/releases/latest'.launchIt)
                    : null,
                subtitle: hasData && isLatest != null
                    ? isLatest
                        ? context.locals.youAreUsingTheLatestVersion
                        : '$version ${context.locals.isAvailable}'
                    : context.locals.lookingForNewVersion,
              );
            },
          ),
          AdwComboRow(
            title: context.locals.region,
            onSelected: (val) => ref.watch(regionProvider.notifier).region =
                Regions.values.toList()[val],
            selectedIndex:
                Regions.values.toList().indexOf(ref.watch(regionProvider)),
            choices: Regions.values
                .map(
                  (Regions e) => e.toString(),
                )
                .toList(),
          ),
          AdwActionRow(
            title: context.locals.resetSettings,
            onActivated: () => resetSettings(ref),
          ),
          AdwActionRow(
            title: '${context.locals.about} ${AppInfo.myApp.name}',
            onActivated: () => showDialog<dynamic>(
              context: context,
              builder: (_) => AdwAboutWindow(
                issueTrackerLink:
                    'https://github.com/prateekmedia/pstube/issues',
                appName: AppInfo.myApp.name,
                actions: AdwActions(
                  onDoubleTap: appWindow?.maximizeOrRestore,
                  onHeaderDrag: appWindow?.startDragging,
                  onClose: Navigator.of(context).pop,
                ),
                headerBarStyle: const HeaderBarStyle(
                  isTransparent: true,
                  autoPositionWindowButtons: false,
                ),
                appIcon: Image.asset(AppInfo.myApp.imagePath),
                credits: [
                  AdwPreferencesGroup.credits(
                    title: 'Developers',
                    children: AppInfo.developerInfos
                        .map(
                          (e) => AdwActionRow(
                            title: e.name,
                            onActivated: e.url.launchIt,
                          ),
                        )
                        .toList(),
                  ),
                  AdwPreferencesGroup.credits(
                    title: 'Translations',
                    children: AppInfo.translatorsInfos
                        .map(
                          (e) => AdwActionRow(
                            title: e.name,
                            onActivated: e.url.launchIt,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            subtitle: context.locals.infoAboutTheAppAndtheDevelopers,
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
