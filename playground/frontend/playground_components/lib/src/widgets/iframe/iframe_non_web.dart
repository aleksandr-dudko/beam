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

// ignore: avoid_web_libraries_in_flutter

import 'package:flutter/widgets.dart';

class IFrameWidget extends StatefulWidget {
  final String url;
  final String viewType;

  const IFrameWidget({
    required this.url,
    required this.viewType,
  });

  @override
  State<IFrameWidget> createState() => _IFrameWidgetState();
}

class _IFrameWidgetState extends State<IFrameWidget> {
  @override
  Widget build(BuildContext context) {
    return ErrorWidget('This only works in web.');
  }
}
