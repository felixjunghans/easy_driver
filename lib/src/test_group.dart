import 'package:easy_driver/src/driver_extension.dart';
import 'package:easy_driver/src/log_messages.dart';
import 'package:easy_driver/src/test_element.dart';
import 'package:easy_driver/src/utils.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

abstract class TestGroup {
  String _reportDirectory;
  bool _withScreenshots;

  DriverExtension _driver;

  @protected
  DriverExtension get driver => _driver;

  @protected
  SerializableFinder get screenFinder;

  @protected
  String get testGroupName;

  String get _groupFolderName =>
      testGroupName.toLowerCase().replaceAll(" ", "_");

  Future<bool> isLoading({Duration timeout}) async {
    return !(await isReady(timeout: timeout));
  }

  Future<bool> isReady({Duration timeout}) async =>
      await widgetExists(_driver.driver, screenFinder);

  Future<void> expectWidget(SerializableFinder finder) async {
    expect(await widgetExists(_driver.driver, finder), isTrue);
  }

  Future<void> expectWidgetAbsent(SerializableFinder finder) async {
    expect(await widgetAbsent(_driver.driver, finder), isTrue);
  }

  @protected
  @mustCallSuper
  Future<void> connectDriver() async {
    _driver = await DriverExtension.connect();
  }

  @protected
  @mustCallSuper
  Future<void> closeDriver() async {
    await _driver.close();
  }

  @protected
  @mustCallSuper
  Future<void> navigateToScreen() async {}

  @protected
  List<TestElement> get tests;

  Future<void> screenShot(String title) async {
    if (_withScreenshots) {
      await takeScreenshot(title,
          "$_reportDirectory/$_groupFolderName/screenshots", _driver.driver);
    }
  }

  Future<void> traceAction(Function test, String title) async {
    final timeline = await _driver.driver.traceAction(() async {
      await test();
    });
    final summary = new TimelineSummary.summarize(timeline);
    summary.writeSummaryToFile(title,
        destinationDirectory:
            "$_reportDirectory/$_groupFolderName/performance/",
        pretty: true);
  }

  void runTests({
    bool withNavigation = false,
    bool withScreenshots = true,
    String reportDirectory,
  }) async {
    IsolatesWorkaround workaround;
    group(testGroupName, () {
      setUpAll(() async {
        await connectDriver();
        workaround = IsolatesWorkaround(_driver.driver);
        await workaround.resumeIsolates();

        _driver.currentScreenFinder = screenFinder;
        _reportDirectory = reportDirectory;
        _withScreenshots = withScreenshots;

        if (withNavigation) {
          info(navigationInfo);
          await navigateToScreen();
        }

        await createDirectory("$_reportDirectory/$_groupFolderName");
        await createDirectory(
            "$_reportDirectory/$_groupFolderName/performance");

        if (withScreenshots) {
          await createDirectory(
              "$_reportDirectory/$_groupFolderName/screenshots");
        }
      });

      test("Screen is Ready", () async {
        await isReady();
      });

      for (TestElement test in tests) {
        test.run(screenShot: screenShot, traceAction: traceAction);
      }

      tearDownAll(() async {
        await closeDriver();
        await workaround.tearDown();
      });
    });
  }
}
