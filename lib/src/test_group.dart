import 'package:easy_driver/src/driver_extension.dart';
import 'package:easy_driver/src/log_messages.dart';
import 'package:easy_driver/src/test_element.dart';
import 'package:easy_driver/src/utils.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

abstract class TestGroup {
  String _screenShotDirectory;

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
    if (_screenShotDirectory != null) {
      await takeScreenshot(
          title, "$_screenShotDirectory/$_groupFolderName", _driver.driver);
    }
  }

  void runTests({
    bool withNavigation = false,
    String screenShotDirectory,
  }) async {
    group(testGroupName, () {
      setUpAll(() async {
        await connectDriver();
        _driver.currentScreenFinder = screenFinder;
        _screenShotDirectory = screenShotDirectory;

        if (withNavigation) {
          info(navigationInfo);
          await navigateToScreen();
        }

        if (screenShotDirectory != null) {
          await createDirectory("$screenShotDirectory/$_groupFolderName");
        }
      });

      test("Screen is Ready", () async {
        await isReady();
      });

      for (TestElement test in tests) {
        test.run(screenShot: screenShot);
      }

      tearDownAll(() async {
        await closeDriver();
      });
    });
  }
}
