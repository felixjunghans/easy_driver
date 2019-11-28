import 'package:easy_driver/easy_driver.dart';
import 'package:easy_driver/src/log_messages.dart';
import 'package:easy_driver/src/test_group.dart';
import 'package:test/test.dart';

class EasyDriver {
  EasyDriver._({
    List<TestGroup> testGroups = const <TestGroup>[],
    bool withNavigation = false,
    bool withScreenshots = true,
    String reportDirectory = 'easydriver',
  }) {
    setUpAll(() async {
      if (withScreenshots) {
        warning(screenShotWarning);
        await createDirectory(reportDirectory);
      }
    });

    for (TestGroup testGroup in testGroups) {
      testGroup.runTests(
          withNavigation: withNavigation,
          withScreenshots: withScreenshots,
          reportDirectory: reportDirectory);
    }
  }

  factory EasyDriver.runTestGroupsInSequence(List<TestGroup> testGroups,
      {bool withNavigation = false, bool withScreenshots = true}) {
    return EasyDriver._(
        testGroups: testGroups,
        withNavigation: withNavigation,
        withScreenshots: withScreenshots);
  }

  factory EasyDriver.runSpecificTestGroupWithNavigation(TestGroup testGroup,
      {bool withScreenshots = true}) {
    return EasyDriver._(
        testGroups: [testGroup],
        withNavigation: true,
        withScreenshots: withScreenshots);
  }
}
