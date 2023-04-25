import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pixiv_func_mobile/app/http.dart';
import 'package:pixiv_func_mobile/app/i18n/i18n.dart';
import 'package:pixiv_func_mobile/app/i18n/i18n_translations.dart';
import 'package:pixiv_func_mobile/app/inject.dart';
import 'package:pixiv_func_mobile/app/notification.dart';
import 'package:pixiv_func_mobile/app/platform/api/platform_api.dart';
import 'package:pixiv_func_mobile/app/services/settings_service.dart';
import 'package:pixiv_func_mobile/app/theme.dart';
import 'package:pixiv_func_mobile/global_controllers/about_controller.dart';
import 'package:pixiv_func_mobile/pages/index.dart';

import 'app/asset_manifest/asset_manifest.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initFlutterLocalNotificationsPlugin();
    await initAssetManifest();
    await initInject();

    initHttpOverrides();

    await I18nTranslations.loadExpansions();
  } catch (e) {
    const fileName = 'error_init.txt';
    final String savePath;
    if (Platform.isAndroid) {
      savePath = (await getExternalStorageDirectory())!.path;
    } else {
      savePath = (await getApplicationDocumentsDirectory()).path;
    }
    final file = File(join(savePath, fileName));
    await file.writeAsString(e.toString());
    PlatformApi.toast(
        '初始化异常,请查看日志文件${Platform.isAndroid ? savePath : fileName}');
    return;
  }

  runApp(const App());

  Get.find<AboutController>().check();

  const storageStatus = Permission.storage;
  const photosStatus = Permission.photos;

  if (!await storageStatus.isGranted) {
    storageStatus.request();
  }

  if (Platform.isIOS && !await photosStatus.isGranted) {
    photosStatus.request();
  }
}

DateTime? _lastPopTime;

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeCodes = Get.find<SettingsService>().language.split('_');
    final theme = Get.find<SettingsService>().theme;
    return GetMaterialApp(
      defaultTransition: Transition.rightToLeft,
      translations: I18nTranslations(),
      locale: Locale(localeCodes.first, localeCodes.last),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('zh', 'CN'),
        const Locale('en', 'US'),
        const Locale('ja', 'JP'),
        const Locale('ru', 'RU'),
        for (final item in I18nTranslations.expansions) item.flutterLocale
      ],
      fallbackLocale: const Locale('zh', 'CN'),
      debugShowCheckedModeBanner: false,
      title: 'Pixiv Func',
      home: WillPopScope(
        onWillPop: () async {
          if (null == _lastPopTime ||
              DateTime.now().difference(_lastPopTime!) >
                  const Duration(seconds: 1)) {
            _lastPopTime = DateTime.now();
            PlatformApi.toast(I18n.doubleClickToExitHint.tr);
            return false;
          } else {
            return true;
          }
        },
        child: const IndexWidget(),
      ),
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: -1 == theme
          ? ThemeMode.system
          : theme == 0
              ? ThemeMode.dark
              : ThemeMode.light,
      enableLog: false,
    );
  }
}
