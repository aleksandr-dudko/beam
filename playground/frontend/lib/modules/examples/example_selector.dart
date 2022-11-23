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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:playground/constants/sizes.dart';
import 'package:playground/modules/examples/components/outside_click_handler.dart';
import 'package:playground/modules/examples/examples_dropdown_content.dart';
import 'package:playground/modules/examples/models/popover_state.dart';
import 'package:playground/pages/playground/states/example_selector_state.dart';
import 'package:playground/utils/dropdown_utils.dart';
import 'package:playground_components/playground_components.dart';
import 'package:provider/provider.dart';

const int kAnimationDurationInMilliseconds = 80;
const Offset kAnimationBeginOffset = Offset(0.0, -0.02);
const Offset kAnimationEndOffset = Offset(0.0, 0.0);
const double kLgContainerHeight = 490.0;
const double kLgContainerWidth = 400.0;

class ExampleSelector extends StatefulWidget {
  final void Function() changeSelectorVisibility;
  final bool isSelectorOpened;

  const ExampleSelector({
    Key? key,
    required this.changeSelectorVisibility,
    required this.isSelectorOpened,
  }) : super(key: key);

  @override
  State<ExampleSelector> createState() => _ExampleSelectorState();
}

class _ExampleSelectorState extends State<ExampleSelector> {
  final GlobalKey selectorKey = LabeledGlobalKey('ExampleSelector');
  OverlayEntry? examplesDropdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kContainerHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(kSmBorderRadius),
      ),
      child: Consumer<PlaygroundController>(
        builder: (context, playgroundController, child) => TextButton(
          key: selectorKey,
          onPressed: () {
            if (widget.isSelectorOpened) {
              examplesDropdown?.remove();
            } else {
              unawaited(_loadCatalogIfNot(playgroundController));
              examplesDropdown = createExamplesDropdown();
              Overlay.of(context)?.insert(examplesDropdown!);
            }
            widget.changeSelectorVisibility();
          },
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Consumer<PlaygroundController>(
                builder: (context, state, child) => Text(state.examplesTitle),
              ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadCatalogIfNot(PlaygroundController controller) async {
    try {
      await controller.exampleCache.loadAllPrecompiledObjectsIfNot();
    } on Exception catch (ex) {
      PlaygroundComponents.toastNotifier.addException(ex);
    }
  }

  OverlayEntry createExamplesDropdown() {
    Offset dropdownOffset = findDropdownOffset(key: selectorKey);

    return OverlayEntry(
      builder: (context) {
        return ChangeNotifierProvider<PopoverState>(
          create: (context) => PopoverState(false),
          builder: (context, state) {
            return Consumer<PlaygroundController>(
              builder: (context, playgroundController, child) => Stack(
                children: [
                  OutsideClickHandler(
                    onTap: () {
                      _closeDropdown(playgroundController.exampleCache);
                      // handle description dialogs
                      Navigator.of(context, rootNavigator: true)
                          .popUntil((route) {
                        return route.isFirst;
                      });
                    },
                  ),
                  ChangeNotifierProvider(
                    create: (context) => ExampleSelectorState(
                      playgroundController,
                      playgroundController.exampleCache
                          .getCategories(playgroundController.sdk),
                    ),
                    builder: (context, _) => Positioned(
                      left: dropdownOffset.dx,
                      top: dropdownOffset.dy,
                      child: Material(
                        elevation: kElevation,
                        child: Container(
                          height: kLgContainerHeight,
                          width: kLgContainerWidth,
                          decoration: BoxDecoration(
                            color: Theme.of(context).backgroundColor,
                            borderRadius:
                                BorderRadius.circular(kMdBorderRadius),
                          ),
                          child: ExamplesDropdownContent(
                            onSelected: () => _closeDropdown(
                              playgroundController.exampleCache,
                            ),
                            playgroundController: playgroundController,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _closeDropdown(ExampleCache exampleCache) {
    examplesDropdown?.remove();
    exampleCache.changeSelectorVisibility();
  }
}
