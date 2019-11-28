import 'package:meta/meta.dart';
import 'package:flutter_driver/flutter_driver.dart';

enum FinderType {
  type,
  text,
  key,
  semanticsLabel,
  tooltip,
}

enum TapType {
  tap,
  doubleTap,
  longPress,
}

class DriverExtension {
  FlutterDriver _driver;
  SerializableFinder currentScreenFinder;

  DriverExtension._(this._driver) : assert(_driver != null);

  FlutterDriver get driver => _driver;

  static Future<DriverExtension> connect({
    String dartVmServiceUrl,
    bool printCommunication = false,
    bool logCommunicationToFile = true,
    int isolateNumber,
    Pattern fuchsiaModuleTarget,
  }) async {
    final FlutterDriver driver = await FlutterDriver.connect(
        dartVmServiceUrl: dartVmServiceUrl,
        printCommunication: printCommunication,
        isolateNumber: isolateNumber,
        fuchsiaModuleTarget: fuchsiaModuleTarget);
    return DriverExtension._(driver);
  }

  Future<void> close() async {
    await _driver.close();
  }

  Future<void> findWidgetOnScreen(
    SerializableFinder scrollable,
    SerializableFinder item, {
    double alignment = 0.0,
    double dxScroll = 0.0,
    double dyScroll = 0.0,
    Duration timeout,
  }) async {
    assert(scrollable != null);
    assert(item != null);
    assert(alignment != null);
    assert(dxScroll != null);
    assert(dyScroll != null);
    assert((dxScroll != 0.0 && dyScroll == 0.0) ||
        (dxScroll == 0.0 && dyScroll != 0.0));
    assert(dxScroll != 0.0 || dyScroll != 0.0);

    bool isVisible = false;
    await _driver.scroll(
        scrollable, 0, 10000, const Duration(milliseconds: 100));
    _driver.waitFor(item, timeout: timeout).then<void>((_) {
      isVisible = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1000));
    while (!isVisible) {
      await _driver.scroll(
          scrollable, 0.0, -400.0, const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    return _driver.scrollIntoView(item, alignment: alignment);
  }

  SerializableFinder _getAppropriateFinder(FinderType type, String target) {
    switch (type) {
      case FinderType.type:
        return find.byType(target);
        break;
      case FinderType.text:
        return find.text(target);
        break;
      case FinderType.key:
        return find.byValueKey(target);
        break;
      case FinderType.semanticsLabel:
        return find.bySemanticsLabel(target);
        break;
      case FinderType.tooltip:
        return find.byTooltip(target);
        break;
      default:
        return find.byType(target);
    }
  }

  Function _getAppropriateTap(TapType type) {
    switch (type) {
      case TapType.tap:
        return findAndTap;
        break;
      case TapType.doubleTap:
        return findAndDoubleTap;
        break;
      case TapType.longPress:
        return findAndLongPress;
        break;
      default:
        return findAndTap;
    }
  }

  Future<void> _findBeforeAction(SerializableFinder finder,
      {SerializableFinder scrollable}) async {
    await findWidgetOnScreen(scrollable ?? currentScreenFinder, finder,
        dyScroll: 300, timeout: Duration(seconds: 30));
  }

  Future<void> findAndTap(SerializableFinder finder,
      {Duration timeout, SerializableFinder scrollable}) async {
    await _findBeforeAction(finder, scrollable: scrollable);
    await _driver.tap(finder, timeout: timeout);
  }

  Future<void> findAndDoubleTap(SerializableFinder finder,
      {Duration timeout}) async {
    await _findBeforeAction(finder);
    _driver.tap(finder);
    await _driver.tap(finder, timeout: timeout);
  }

  Future<void> findAndLongPress(SerializableFinder finder,
      {Duration timeout}) async {
    await _findBeforeAction(finder);
    await _driver.scroll(finder, 0, 0, Duration(milliseconds: 500),
        timeout: timeout);
  }

  Future<void> tapByType(String target,
      {Duration timeout, TapType type = TapType.tap}) async {
    final finder = _getAppropriateFinder(FinderType.type, target);
    await _getAppropriateTap(type)(finder, timeout: timeout);
  }

  Future<void> tapByText(String target,
      {Duration timeout, TapType type = TapType.tap}) async {
    final finder = _getAppropriateFinder(FinderType.text, target);
    await _getAppropriateTap(type)(finder, timeout: timeout);
  }

  Future<void> tapByValueKey(String target,
      {Duration timeout, TapType type = TapType.tap}) async {
    final finder = _getAppropriateFinder(FinderType.key, target);
    await _getAppropriateTap(type)(finder, timeout: timeout);
  }

  Future<void> tapBySemanticsLabel(String target,
      {Duration timeout, TapType type = TapType.tap}) async {
    final finder = _getAppropriateFinder(FinderType.semanticsLabel, target);
    await _getAppropriateTap(type)(finder, timeout: timeout);
  }

  Future<void> tapByTooltip(String target,
      {Duration timeout, TapType type = TapType.tap}) async {
    final finder = _getAppropriateFinder(FinderType.tooltip, target);
    await _getAppropriateTap(type)(finder, timeout: timeout);
  }

  Future<void> findAndEnterText(SerializableFinder finder, String text) async {
    await findAndTap(finder);
    await _driver.enterText(text);
  }

  Future<void> enterTextByType(String target, String text) async {
    final finder = _getAppropriateFinder(FinderType.type, target);
    await findAndEnterText(finder, text);
  }

  Future<void> enterTextByText(String target, String text) async {
    final finder = _getAppropriateFinder(FinderType.text, target);
    await findAndEnterText(finder, text);
  }

  Future<void> enterTextByValueKey(String target, String text) async {
    final finder = _getAppropriateFinder(FinderType.key, target);
    await findAndEnterText(finder, text);
  }

  Future<void> enterTextBySemanticsLabel(String target, String text) async {
    final finder = _getAppropriateFinder(FinderType.semanticsLabel, target);
    await findAndEnterText(finder, text);
  }

  Future<void> enterTextByTooltip(String target, String text) async {
    final finder = _getAppropriateFinder(FinderType.tooltip, target);
    await findAndEnterText(finder, text);
  }

  Future<void> dismissOverlay([SerializableFinder modalBarrier]) async {
    if (modalBarrier != null) {
      await findAndTap(modalBarrier);
    } else {
      await findAndTap(_getAppropriateFinder(FinderType.type, 'ModalBarrier'));
    }
  }

  Future<bool> tryToTap(SerializableFinder item,
      {SerializableFinder scrollable}) async {
    try {
      await _driver.tap(item, timeout: Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> selectItem(
      SerializableFinder dropDownButton, SerializableFinder item,
      {SerializableFinder scrollable, SerializableFinder dismiss}) async {
    await findAndTap(dropDownButton);
    final menu = scrollable ?? find.byType("_DropdownMenu");
    await findAndTap(find.descendant(of: menu, matching: item),
        scrollable: menu);
    if (dismiss != null) {
      dismissOverlay();
    }
  }

  Future<void> closeDrawer({bool isLeft = true}) async {
    await _driver.scroll(currentScreenFinder, isLeft ? -300 : 300, 0,
        const Duration(milliseconds: 300));
  }
}
