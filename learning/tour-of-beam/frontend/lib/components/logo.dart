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

import '../constants/assets.dart';
import '../constants/font_weights.dart';
import '../constants/fonts.dart';
import '../constants/sizes.dart';

class Logo extends StatelessWidget {
  const Logo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          ProjectAssets.beamLogo,
          width: ProjectIconSizes.large,
          height: ProjectIconSizes.large,
        ),
        RichText(
          text: TextSpan(
            style: getLogoFontStyle(
              textStyle: const TextStyle(
                fontSize: ProjectFontSizes.logo,
                fontWeight: ProjectFontWeights.light,
              ),
            ),
            children: [
              TextSpan(
                text: 'Tour of',
                style: TextStyle(
                  color: theme.textTheme.bodyText1?.color,
                ),
              ),
              TextSpan(
                text: ' Beam',
                style: TextStyle(color: theme.primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
