import 'package:easy_driver/easy_driver.dart';

import 'tests/test_screen.dart';

void main() async {
  EasyDriver.runTestGroupsInSequence([TestScreen()]);
}