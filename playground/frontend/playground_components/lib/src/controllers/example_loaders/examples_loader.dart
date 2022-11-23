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

import 'package:collection/collection.dart';

import '../../models/example_loading_descriptors/example_loading_descriptor.dart';
import '../../models/example_loading_descriptors/examples_loading_descriptor.dart';
import '../../models/sdk.dart';
import '../playground_controller.dart';
import 'catalog_default_example_loader.dart';
import 'content_example_loader.dart';
import 'empty_example_loader.dart';
import 'example_loader.dart';
import 'example_loader_factory.dart';
import 'exceptions/example_loading_exceptions.dart';
import 'http_example_loader.dart';
import 'standard_example_loader.dart';
import 'user_shared_example_loader.dart';

class ExamplesLoader {
  final defaultFactory = ExampleLoaderFactory();
  PlaygroundController? _playgroundController;
  ExamplesLoadingDescriptor? _descriptor;

  ExamplesLoader() {
    defaultFactory.add(CatalogDefaultExampleLoader.new);
    defaultFactory.add(ContentExampleLoader.new);
    defaultFactory.add(EmptyExampleLoader.new);
    defaultFactory.add(HttpExampleLoader.new);
    defaultFactory.add(StandardExampleLoader.new);
    defaultFactory.add(UserSharedExampleLoader.new);
  }

  void setPlaygroundController(PlaygroundController value) {
    _playgroundController = value;
  }

  /// Loads examples from [descriptor]'s immediate list.
  ///
  /// Sets empty editor for SDKs of failed examples.
  Future<void> load(ExamplesLoadingDescriptor descriptor) async {
    if (_descriptor == descriptor) {
      return;
    }

    _descriptor = descriptor;
    final loaders = <ExampleLoader>[];

    for (final one in descriptor.descriptors) {
      final loader = _createLoader(one);
      if (loader == null) {
        continue;
      }
      loaders.add(loader);
    }

    try {
      final loadFutures = loaders.map(_loadOne);
      await Future.wait(loadFutures);
    } on Exception catch (ex) {
      _emptyMissing(loaders);
      throw ExampleLoadingException(ex);
    }

    final sdk = descriptor.initialSdk;
    if (sdk != null) {
      _playgroundController!.setSdk(sdk);
    }
  }

  ExampleLoader? _createLoader(ExampleLoadingDescriptor descriptor) {
    final loader = defaultFactory.create(
      descriptor: descriptor,
      exampleCache: _playgroundController!.exampleCache,
    );

    if (loader == null) {
      // TODO: Log.
      print('Cannot create example loader for $descriptor');
      return null;
    }

    return loader;
  }

  void _emptyMissing(List<ExampleLoader> loaders) {
    loaders.forEach(_emptyIfMissing);
  }

  Future<void> _emptyIfMissing(ExampleLoader loader) async {
    final sdk = loader.sdk;

    if (sdk == null) {
      return;
    }

    final setCurrent = _shouldSetCurrentSdk(sdk);
    _playgroundController!.setEmptyIfNotExists(sdk, setCurrentSdk: setCurrent);
  }

  Future<void> loadDefaultIfAny(Sdk sdk) async {
    final group = _descriptor;
    final one = group?.lazyLoadDescriptors[sdk]?.firstOrNull;

    if (group == null || one == null) {
      return;
    }

    final loader = _createLoader(one);
    if (loader == null) {
      return;
    }

    await _loadOne(loader);
  }

  Future<void> _loadOne(ExampleLoader loader) async {
    final example = await loader.future;
    _playgroundController!.setExample(
      example,
      setCurrentSdk: _shouldSetCurrentSdk(example.sdk),
    );
  }

  bool _shouldSetCurrentSdk(Sdk sdk) {
    final descriptor = _descriptor;

    if (descriptor == null) {
      return false;
    }

    if (descriptor.initialSdk == null) {
      return true;
    }

    return descriptor.initialSdk == sdk;
  }
}
