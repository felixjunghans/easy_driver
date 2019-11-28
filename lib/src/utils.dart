import 'dart:async';
import 'dart:io';
import 'package:easy_driver/src/log_messages.dart';
import 'package:flutter_driver/flutter_driver.dart';

Future<bool> widgetExists(
  FlutterDriver driver,
  SerializableFinder finder, {
  Duration timeout = const Duration(
    seconds: 30,
  ),
}) async {
  try {
    await driver.waitFor(finder, timeout: timeout);

    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> widgetAbsent(
  FlutterDriver driver,
  SerializableFinder finder, {
  Duration timeout,
}) async {
  try {
    await driver.waitForAbsent(finder, timeout: timeout);

    return true;
  } catch (_) {
    return false;
  }
}

Future<String> getNextImageNumber(String folderPath) async {
  Directory directory = new Directory(folderPath);
  bool exists = await directory.exists();
  if (exists) {
    return directory.listSync().length > 10
        ? "${directory.listSync().length + 1}"
        : "0${directory.listSync().length + 1}";
  } else {
    return "";
  }
}

Future<void> takeScreenshot(
    String title, String folderPath, FlutterDriver driver) async {
  final String formattedTitle = title.toLowerCase().replaceAll(" ", "_");
  final List<int> pixels = await driver.screenshot();

  final imageNumber = await getNextImageNumber(folderPath);
  final String path = "$folderPath/${imageNumber}_$formattedTitle.png";

  final File file = new File(path);
  await file.writeAsBytes(pixels);
  print(path);
}

Future<void> createDirectory(String path) async {
  if (await Directory(path).exists()) {
    warning("$directoryExistsWarning Directory - $path  - ");
    await Directory(path).delete(recursive: true);
  }
  await Directory(path).create();
}

const String _ESC = "\u{1B}";

void info(String text) {
  _log("INFO! $text", 94);
}

void warning(String text) {
  _log("WARNING! $text", 91);
}

void _log(String text, int type) {
  print(_ESC + "[${type}m" + text + _ESC + "[0m");
}

/// Workaround for bug: https://github.com/flutter/flutter/issues/24703
///
/// USAGE
///
/// ```
/// FlutterDriver driver;
/// IsolatesWorkaround workaround;
///
/// setUpAll(() async {
///   driver = await FlutterDriver.connect();
///   workaround = IsolatesWorkaround(driver);
///   await workaround.resumeIsolates();
/// });
///
/// tearDownAll(() async {
///   if (driver != null) {
///     await driver.close();
///     await workaround.tearDown();
///   }
/// });
/// ```
class IsolatesWorkaround {
  IsolatesWorkaround(this._driver, {this.log = false});
  final FlutterDriver _driver;
  final bool log;
  StreamSubscription _streamSubscription;

  /// workaround for isolates
  /// https://github.com/flutter/flutter/issues/24703
  Future<void> resumeIsolates() async {
    final vm = await _driver.serviceClient.getVM();
    // // unpause any paused isolated
    for (final isolateRef in vm.isolates) {
      final isolate = await isolateRef.load();
      if (isolate.isPaused) {
        isolate.resume();
        if (log) {
          print("Resuming isolate: ${isolate.numberAsString}:${isolate.name}");
        }
      }
    }
    if (_streamSubscription != null) {
      return;
    }
    _streamSubscription = _driver.serviceClient.onIsolateRunnable
        .asBroadcastStream()
        .listen((isolateRef) async {
      final isolate = await isolateRef.load();
      if (isolate.isPaused) {
        isolate.resume();
        if (log) {
          print("Resuming isolate: ${isolate.numberAsString}:${isolate.name}");
        }
      }
    });
  }

  Future<void> tearDown() async {
    if (_streamSubscription != null) {
      await _streamSubscription.cancel();
    }
  }
}
