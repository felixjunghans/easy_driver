import 'package:easy_driver/easy_driver.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_driver/src/common/find.dart';

class TestScreen extends TestGroup {
  @override
  String get testGroupName => "TestGroup";

  @override
  SerializableFinder get screenFinder => find.byType('MyApp');

  @override
  List<TestElement> get tests => [
        TestElement('Test Taps with scrolling', () async {
          await driver.tapByText('List element 59');
          await driver.tapByText('List element 2');
          await driver.tapByText('List element 155');
          await screenShot("List Element 155 tapped");
          await driver.tapByText('List element 468');
          await driver.tapByText('List element 15');
        }),
        TestElement('Test Enter Text in Textfield', () async {
          await driver.enterTextByValueKey('TextField', 'This is a test.');
        }),
        TestElement('Test Select an element', () async {
          await driver.selectItem(
              find.byValueKey('Dropdown'), find.text('Select element 49'),
              scrollable: find.byType('_DropdownMenu<int>'));
        }),
        TestElement('Test open and close drawer', () async {
          await driver.findAndTap(find.byType("IconButton"));
          await Future.delayed(Duration(seconds: 3));
          await driver.closeDrawer();
        }),
      ];
}
