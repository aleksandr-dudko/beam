/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:playground_components/playground_components.dart';
import 'package:playground_components_dev/playground_components_dev.dart';
import 'package:tour_of_beam/cache/content_tree.dart';
import 'package:tour_of_beam/cache/sdk.dart';
import 'package:tour_of_beam/cache/unit_content.dart';
import 'package:tour_of_beam/components/builders/content_tree.dart';
import 'package:tour_of_beam/models/content_tree.dart';
import 'package:tour_of_beam/models/group.dart';
import 'package:tour_of_beam/models/module.dart';
import 'package:tour_of_beam/models/unit.dart';
import 'package:tour_of_beam/pages/tour/screen.dart';
import 'package:tour_of_beam/pages/tour/state.dart';
import 'package:tour_of_beam/pages/tour/widgets/unit.dart';
import 'package:tour_of_beam/pages/tour/widgets/unit_content.dart';

import 'common/common.dart';
import 'common/common_finders.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'ToB miscellaneous ui',
    (wt) async {
      await init(wt);
      await wt.tapAndSettle(find.text(Sdk.java.title));
      await wt.tapAndSettle(find.startTourButton());

      await _checkContentTreeBuildsProperly(wt);
      await _checkContentTreeScrollsProperly(wt);
      await _checkHighlightsSelectedUnit(wt);
      // TODO(nausharipov): fix tests
      // await _checkRunCodeWorks(wt);
      // await _checkResizeUnitContent(wt);
      await _checkSdkChanges(wt);
    },
  );
}

Future<void> _checkContentTreeBuildsProperly(WidgetTester wt) async {
  final modules = _getModules(wt);

  for (final module in modules) {
    await _checkModule(module, wt);
  }
}

List<ModuleModel> _getModules(WidgetTester wt) {
  final contentTreeCache = GetIt.instance.get<ContentTreeCache>();
  final controller = getContentTreeController(wt);
  final contentTree = contentTreeCache.getContentTree(controller.sdk);
  return contentTree?.nodes ?? (throw Exception('Cannot load modules'));
}

Future<void> _checkModule(ModuleModel module, WidgetTester wt) async {
  if (!_getExpandedIds(wt).contains(module.id)) {
    await wt.ensureVisible(find.byKey(Key(module.id)));
    await wt.tapAndSettle(find.byKey(Key(module.id)));
  }

  for (final node in module.nodes) {
    if (node is UnitModel) {
      await _checkNode(node, wt);
    }
    if (node is GroupModel) {
      await _checkGroup(node, wt);
    }
  }
}

Future<void> _checkNode(UnitModel node, WidgetTester wt) async {
  final finder = find.byKey(Key(node.id));
  expect(finder, findsOneWidget, reason: node.id);

  await wt.ensureVisible(finder);
  expect(
    find.descendant(
      of: find.byType(ContentTreeBuilder),
      matching: find.text(node.title),
    ),
    findsAtLeastNWidgets(1),
  );

  await _checkUnitContentLoadsProperly(node, wt);
}

Future<void> _checkUnitContentLoadsProperly(
  UnitModel unit,
  WidgetTester wt,
) async {
  await wt.tapAndSettle(find.byKey(Key(unit.id)));

  // TODO(nausharipov): fix the test.
  // final hasSnippet = _getTourNotifier(wt).isUnitContainsSnippet;

  // expect(
  //   find.byType(PlaygroundWidget),
  //   hasSnippet ? findsOneWidget : findsNothing,
  // );

  expect(
    find.descendant(
      of: find.byType(UnitContentWidget),
      matching: find.text(unit.title),
    ),
    findsAtLeastNWidgets(1),
  );
}

Future<void> _checkGroup(GroupModel group, WidgetTester wt) async {
  await wt.ensureVisible(find.byKey(Key(group.id)));
  await wt.tapAndSettle(find.byKey(Key(group.id)));

  for (final n in group.nodes) {
    if (n is GroupModel) {
      await _checkGroup(n, wt);
    }
    if (n is UnitModel) {
      await _checkNode(n, wt);
    }
  }
}

Future<void> _checkContentTreeScrollsProperly(WidgetTester wt) async {
  final modules = _getModules(wt);
  final lastNode = modules.expand((m) => m.nodes).whereType<UnitModel>().last;

  await wt.ensureVisible(find.byKey(Key(lastNode.id)));
  await wt.pumpAndSettle();
}

Future<void> _checkHighlightsSelectedUnit(WidgetTester wt) async {
  final controller = getContentTreeController(wt);
  final selectedUnit = controller.currentNode;

  if (selectedUnit == null) {
    fail('No unit selected');
  }

  final selectedUnitText = find.descendant(
    of: find.byKey(Key(selectedUnit.id)),
    matching: find.text(selectedUnit.title),
    skipOffstage: false,
  );

  final selectedUnitContainer = find.ancestor(
    of: selectedUnitText,
    matching: find.byKey(UnitWidget.containerKey),
  );

  final context = wt.element(selectedUnitText);

  expect(
    (wt.widget<Container>(selectedUnitContainer).decoration as BoxDecoration?)
        ?.color,
    Theme.of(context).selectedRowColor,
  );
}

Future<void> _checkRunCodeWorks(WidgetTester wt) async {
  const text = 'OK';
  const code = '''
public class MyClass {
  public static void main(String[] args) {
    System.out.print("$text");
  }
}
''';

  await _selectExampleWithSnippet(wt);
  await wt.pumpAndSettle();

  await wt.enterText(find.snippetCodeField(), code);
  await wt.pumpAndSettle();

  await _runAndCancelExample(wt, const Duration(milliseconds: 300));

  await wt.tapAndSettle(find.runOrCancelButton());

  final playgroundController = _getPlaygroundController(wt);
  expect(
    playgroundController.codeRunner.resultLogOutput,
    contains(text),
  );
}

Future<void> _runAndCancelExample(WidgetTester wt, Duration duration) async {
  await wt.tap(find.runOrCancelButton());

  await wt.pumpAndSettleNoException(timeout: duration);
  await wt.tapAndSettle(find.runOrCancelButton());

  final playgroundController = _getPlaygroundController(wt);
  expect(
    playgroundController.codeRunner.resultLogOutput,
    contains('Pipeline cancelled'),
  );
}

Future<void> _checkResizeUnitContent(WidgetTester wt) async {
  var dragHandleFinder = find.byKey(TourScreen.dragHandleKey);

  final startHandlePosition = wt.getCenter(dragHandleFinder);

  await wt.drag(dragHandleFinder, const Offset(100, 0));
  await wt.pumpAndSettle();

  dragHandleFinder = find.byKey(TourScreen.dragHandleKey);

  final movedHandlePosition = wt.getCenter(dragHandleFinder);

  expectSimilar(startHandlePosition.dx, movedHandlePosition.dx - 100);
}

Future<void> _selectExampleWithSnippet(WidgetTester wt) async {
  final tourNotifier = _getTourNotifier(wt);
  final modules = _getModules(wt);

  for (final module in modules) {
    for (final node in module.nodes) {
      if (node is UnitModel) {
        await _checkNode(node, wt);
        if (tourNotifier.isUnitContainsSnippet) {
          return;
        }
      }
    }
  }
}

TourNotifier _getTourNotifier(WidgetTester wt) {
  return (wt.widget(find.byType(UnitContentWidget)) as UnitContentWidget)
      .tourNotifier;
}

PlaygroundController _getPlaygroundController(WidgetTester wt) {
  return _getTourNotifier(wt).playgroundController;
}

Set<String> _getExpandedIds(WidgetTester wt) {
  final controller = getContentTreeController(wt);
  return controller.expandedIds;
}

Future<void> _checkSdkChanges(WidgetTester wt) async {
  await _selectUnitWithSnippetsInAllSdks(wt);
  await _checkSnippetChangesOnSdkChanging(wt);
}

Future<void> _selectUnitWithSnippetsInAllSdks(WidgetTester wt) async {
  final unitContentCache = GetIt.instance.get<UnitContentCache>();
  final commonUnits = await _getCommonUnitsInAllSdks(wt);
  final sdks = GetIt.instance.get<SdkCache>().getSdks();

  UnitModel? unitWithSnippets;
  for (final unit in commonUnits) {
    var areAllSdksContainsSnippet = true;
    for (final sdk in sdks) {
      final unitContent =
          await unitContentCache.getUnitContent(sdk.id, unit.id);
      if (unitContent.taskSnippetId == null) {
        areAllSdksContainsSnippet = false;
        break;
      }
    }
    if (areAllSdksContainsSnippet) {
      unitWithSnippets = unit;
      break;
    }
  }

  if (unitWithSnippets == null) {
    fail('No unit with snippets in all sdks');
  }
  
  final controller = getContentTreeController(wt);
  controller.onNodePressed(unitWithSnippets);
  await wt.pumpAndSettle();
}

Future<List<UnitModel>> _getCommonUnitsInAllSdks(WidgetTester wt) async {
  final contentTrees = await _loadAllContentTrees(wt);
  final sdkUnits = List<List<UnitModel>>.empty(growable: true);
  for (final tree in contentTrees) {
    sdkUnits.add(tree.getUnits().toList());
  }

  final commonUnitTitles = sdkUnits.first;
  for (final units in sdkUnits.skip(1)) {
    commonUnitTitles.removeWhere((u) => !units.contains(u));
  }

  return commonUnitTitles;
}

Future<List<ContentTreeModel>> _loadAllContentTrees(WidgetTester wt) async {
  final sdkCache = GetIt.instance.get<SdkCache>();
  final contentTreeCache = GetIt.instance.get<ContentTreeCache>();
  final sdks = sdkCache.getSdks();
  final nullableTrees = await Future.wait(
    sdks.map((sdk) async => contentTreeCache.getContentTree(sdk)),
  );

  return nullableTrees.where((t) => t != null).map((t) => t!).toList();
}

Future<void> _checkSnippetChangesOnSdkChanging(WidgetTester wt) async {
  final defaultSdk = _getTourNotifier(wt).playgroundController.sdk;
  final sdkCache = GetIt.instance.get<SdkCache>();

  String? previousPath;
  Sdk? previousSdk;
  for (final sdk in sdkCache.getSdks()) {
    if (sdk.title == defaultSdk?.title) {
      continue;
    }

    await _setSdk(sdk.title, wt);

    final selectedExample =
        _getTourNotifier(wt).playgroundController.selectedExample;
    final actualPath = selectedExample?.path;
    final actualSdk = selectedExample?.sdk;
    expect(actualPath, isNot(previousPath));
    expect(actualSdk, isNot(previousSdk));
    previousPath = actualPath;
    previousSdk = actualSdk;
  }

  await _setSdk(defaultSdk!.title, wt);
}

Future<void> _setSdk(String title, WidgetTester wt) async {
  await wt.tapAndSettle(find.sdkDropdown());
  await wt.tapAndSettle(
    find.dropdownMenuItemWithText(title).first,
    warnIfMissed: false,
  );
}
