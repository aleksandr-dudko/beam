<!--
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

### Run inference

The `RunInference` class is an Apache Beam transform that allows you to perform inference using a machine learning model within a Beam pipeline. It provides a way to apply inference to elements in a collection and produce the corresponding output.

```
Pipeline pipeline = Pipeline.create(options);
        PCollection<KV<Long, Iterable<Long>>> col =
                pipeline
                        .apply(TextIO.read().from(options.getInput()))
                        .apply(Filter.by(new FilterNonRecordsFn()))
                        .apply(MapElements.via(new RecordsToLabeledPixelsFn()));
        col.apply(
                        RunInference.ofKVs(getModelLoaderScript(), schema, VarLongCoder.of())
                                .withKwarg("model_uri", options.getModelPath())
                                .withExpansionService(expansionService))
                .apply(MapElements.via(new FormatOutput()))
                .apply(TextIO.write().to(options.getOutput()));
```

```
private String getModelLoaderScript() {
        String s = "from apache_beam.ml.inference.sklearn_inference import SklearnModelHandlerNumpy\n";
        s = s + "from apache_beam.ml.inference.base import KeyedModelHandler\n";
        s = s + "def get_model_handler(model_uri):\n";
        s = s + "  return KeyedModelHandler(SklearnModelHandlerNumpy(model_uri))\n";

        return s;
    }
```

The `RunInference` transform is typically used in conjunction with a model loader function. In your code, the `getModelLoaderScript()` method generates a Python function that produces a scikit-learn model loader. This function is then passed as an argument to the RunInference.ofKVs() method, along with other parameters such as the schema of the output, coder, and optional keyword arguments.

The `RunInference` transform takes the input collection, applies the model loader function to load the model, performs inference on each element in the collection, and produces the output collection with the inferred results.

The input `PCollection` is passed to the `RunInference` transform using the `apply()` method.
The `RunInference` transform is instantiated using the `RunInference.ofKVs()` method, which takes the model loader script, schema, and coder as arguments.
Additional keyword arguments can be passed using the `withKwarg()` method. In your code, the model_uri keyword argument is set to the model path obtained from the pipeline options.
The `withExpansionService()` method can be used to specify a Python expansion service URL if needed.
The `RunInference` transform is applied to the input PCollection.
The FormatOutput `SimpleFunction` is applied to format the output of the inference.
The output is written to a file using the `TextIO.write()` transform.
Overall, the `RunInference` transform allows you to incorporate machine learning model inference into your Apache Beam pipeline, enabling you to perform inference on large-scale data processing tasks.