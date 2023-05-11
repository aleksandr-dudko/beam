#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# pytype: skip-file

import os
import shutil
import tempfile
import unittest
from typing import Any
from typing import Dict
from typing import Iterable
from typing import Optional
from typing import Sequence
from typing import Union

import numpy
import pytest

try:
  import tensorflow as tf
  import apache_beam as beam
  from apache_beam.testing.test_pipeline import TestPipeline
  from apache_beam.ml.inference.sklearn_inference_test import _compare_prediction_result
  from apache_beam.ml.inference.base import KeyedModelHandler, PredictionResult, RunInference
  from apache_beam.ml.inference.tensorflow_inference import TFModelHandlerNumpy, TFModelHandlerTensor
  from apache_beam.ml.inference import tensorflow_inference, utils
  from apache_beam.testing.util import assert_that, equal_to
except ImportError:
  raise unittest.SkipTest(
      'Tensorflow dependencies are not installed. ' +
      'Make sure you have both tensorflow and tensorflow_hub installed.')


class FakeTFNumpyModel:
  def predict(self, input: numpy.ndarray):
    return numpy.multiply(input, 10)


class FakeTFTensorModel:
  def predict(self, input: tf.Tensor, add=False):
    if add:
      return tf.math.add(tf.math.multiply(input, 10), 10)
    return tf.math.multiply(input, 10)


def _create_mult2_model():
  inputs = tf.keras.Input(shape=(3))
  outputs = tf.keras.layers.Lambda(lambda x: x * 2, dtype='float32')(inputs)
  return tf.keras.Model(inputs=inputs, outputs=outputs)


def _compare_tensor_prediction_result(x, y):
  return tf.reduce_all(tf.math.equal(x.inference, y.inference))


def fake_inference_fn(
    model: tf.Module,
    batch: Union[Sequence[numpy.ndarray], Sequence[tf.Tensor]],
    inference_args: Dict[str, Any],
    model_id: Optional[str] = None) -> Iterable[PredictionResult]:
  predictions = model.predict(batch, **inference_args)
  return utils._convert_to_result(batch, predictions, model_id)


@pytest.mark.uses_tf
class TFRunInferenceTest(unittest.TestCase):
  def setUp(self):
    self.tmpdir = tempfile.mkdtemp()

  def tearDown(self):
    shutil.rmtree(self.tmpdir)

  def test_predict_numpy(self):
    fake_model = FakeTFNumpyModel()
    inference_runner = TFModelHandlerNumpy(
        model_uri='unused', inference_fn=fake_inference_fn)
    batched_examples = [numpy.array([1]), numpy.array([10]), numpy.array([100])]
    expected_predictions = [
        PredictionResult(numpy.array([1]), 10),
        PredictionResult(numpy.array([10]), 100),
        PredictionResult(numpy.array([100]), 1000)
    ]
    inferences = inference_runner.run_inference(batched_examples, fake_model)
    for actual, expected in zip(inferences, expected_predictions):
      self.assertTrue(_compare_prediction_result(actual, expected))

  def test_predict_tensor(self):
    fake_model = FakeTFTensorModel()
    inference_runner = TFModelHandlerTensor(
        model_uri='unused', inference_fn=fake_inference_fn)
    batched_examples = [
        tf.convert_to_tensor(numpy.array([1])),
        tf.convert_to_tensor(numpy.array([10])),
        tf.convert_to_tensor(numpy.array([100])),
    ]
    expected_predictions = [
        PredictionResult(ex, pred) for ex,
        pred in zip(
            batched_examples,
            [tf.math.multiply(n, 10) for n in batched_examples])
    ]

    inferences = inference_runner.run_inference(batched_examples, fake_model)
    for actual, expected in zip(inferences, expected_predictions):
      self.assertTrue(_compare_tensor_prediction_result(actual, expected))

  def test_predict_tensor_with_batch_size(self):
    model = _create_mult2_model()
    model_path = os.path.join(self.tmpdir, 'mult2')
    tf.keras.models.save_model(model, model_path)
    with TestPipeline() as pipeline:

      def fake_batching_inference_fn(
          model: tf.Module,
          batch: Union[Sequence[numpy.ndarray], Sequence[tf.Tensor]],
          inference_args: Dict[str, Any],
          model_id: Optional[str] = None) -> Iterable[PredictionResult]:
        if len(batch) != 2:
          raise Exception(
              f'Expected batch of size 2, received batch of size {len(batch)}')
        batch = tf.stack(batch, axis=0)
        predictions = model(batch)
        return utils._convert_to_result(batch, predictions, model_id)

      model_handler = TFModelHandlerTensor(
          model_uri=model_path,
          inference_fn=fake_batching_inference_fn,
          min_batch_size=2,
          max_batch_size=2)
      examples = [
          tf.convert_to_tensor(numpy.array([1.1, 2.2, 3.3], dtype='float32')),
          tf.convert_to_tensor(
              numpy.array([10.1, 20.2, 30.3], dtype='float32')),
          tf.convert_to_tensor(
              numpy.array([100.1, 200.2, 300.3], dtype='float32')),
          tf.convert_to_tensor(
              numpy.array([200.1, 300.2, 400.3], dtype='float32')),
      ]
      expected_predictions = [
          PredictionResult(ex, pred) for ex,
          pred in zip(examples, [tf.math.multiply(n, 2) for n in examples])
      ]

      pcoll = pipeline | 'start' >> beam.Create(examples)
      predictions = pcoll | RunInference(model_handler)
      assert_that(
          predictions,
          equal_to(
              expected_predictions,
              equals_fn=_compare_tensor_prediction_result))

  def test_predict_numpy_with_batch_size(self):
    model = _create_mult2_model()
    model_path = os.path.join(self.tmpdir, 'mult2_numpy')
    tf.keras.models.save_model(model, model_path)
    with TestPipeline() as pipeline:

      def fake_batching_inference_fn(
          model: tf.Module,
          batch: Sequence[numpy.ndarray],
          inference_args: Dict[str, Any],
          model_id: Optional[str] = None) -> Iterable[PredictionResult]:
        if len(batch) != 2:
          raise Exception(
              f'Expected batch of size 2, received batch of size {len(batch)}')
        vectorized_batch = numpy.stack(batch, axis=0)
        predictions = model.predict(vectorized_batch, **inference_args)
        return utils._convert_to_result(batch, predictions, model_id)

      model_handler = TFModelHandlerNumpy(
          model_uri=model_path,
          inference_fn=fake_batching_inference_fn,
          min_batch_size=2,
          max_batch_size=2)
      examples = [
          numpy.array([1.1, 2.2, 3.3], dtype='float32'),
          numpy.array([10.1, 20.2, 30.3], dtype='float32'),
          numpy.array([100.1, 200.2, 300.3], dtype='float32'),
          numpy.array([200.1, 300.2, 400.3], dtype='float32'),
      ]
      expected_predictions = [
          PredictionResult(ex, pred) for ex,
          pred in zip(examples, [numpy.multiply(n, 2) for n in examples])
      ]

      pcoll = pipeline | 'start' >> beam.Create(examples)
      predictions = pcoll | RunInference(model_handler)
      assert_that(
          predictions,
          equal_to(
              expected_predictions,
              equals_fn=_compare_tensor_prediction_result))

  def test_predict_tensor_with_args(self):
    fake_model = FakeTFTensorModel()
    inference_runner = TFModelHandlerTensor(
        model_uri='unused', inference_fn=fake_inference_fn)
    batched_examples = [
        tf.convert_to_tensor(numpy.array([1])),
        tf.convert_to_tensor(numpy.array([10])),
        tf.convert_to_tensor(numpy.array([100])),
    ]
    expected_predictions = [
        PredictionResult(ex, pred) for ex,
        pred in zip(
            batched_examples, [
                tf.math.add(tf.math.multiply(n, 10), 10)
                for n in batched_examples
            ])
    ]

    inferences = inference_runner.run_inference(
        batched_examples, fake_model, inference_args={"add": True})
    for actual, expected in zip(inferences, expected_predictions):
      self.assertTrue(_compare_tensor_prediction_result(actual, expected))

  def test_predict_keyed_numpy(self):
    fake_model = FakeTFNumpyModel()
    inference_runner = KeyedModelHandler(
        TFModelHandlerNumpy(model_uri='unused', inference_fn=fake_inference_fn))
    batched_examples = [
        ('k1', numpy.array([1], dtype=numpy.int64)),
        ('k2', numpy.array([10], dtype=numpy.int64)),
        ('k3', numpy.array([100], dtype=numpy.int64)),
    ]
    expected_predictions = [
        (ex[0], PredictionResult(ex[1], pred)) for ex,
        pred in zip(
            batched_examples,
            [numpy.multiply(n[1], 10) for n in batched_examples])
    ]
    inferences = inference_runner.run_inference(batched_examples, fake_model)
    for actual, expected in zip(inferences, expected_predictions):
      self.assertTrue(_compare_prediction_result(actual[1], expected[1]))

  def test_predict_keyed_tensor(self):
    fake_model = FakeTFTensorModel()
    inference_runner = KeyedModelHandler(
        TFModelHandlerTensor(
            model_uri='unused', inference_fn=fake_inference_fn))
    batched_examples = [
        ('k1', tf.convert_to_tensor(numpy.array([1]))),
        ('k2', tf.convert_to_tensor(numpy.array([10]))),
        ('k3', tf.convert_to_tensor(numpy.array([100]))),
    ]
    expected_predictions = [
        (ex[0], PredictionResult(ex[1], pred)) for ex,
        pred in zip(
            batched_examples,
            [tf.math.multiply(n[1], 10) for n in batched_examples])
    ]
    inferences = inference_runner.run_inference(batched_examples, fake_model)
    for actual, expected in zip(inferences, expected_predictions):
      self.assertTrue(_compare_tensor_prediction_result(actual[1], expected[1]))


@pytest.mark.uses_tf
class TFRunInferenceTestWithMocks(unittest.TestCase):
  def setUp(self):
    self._load_model = tensorflow_inference._load_model
    tensorflow_inference._load_model = unittest.mock.MagicMock()

  def tearDown(self):
    tensorflow_inference._load_model = self._load_model

  def test_load_model_args(self):
    load_model_args = {compile: False, 'custom_objects': {'optimizer': 1}}
    model_handler = TFModelHandlerNumpy(
        "dummy_model", load_model_args=load_model_args)
    model_handler.load_model()
    tensorflow_inference._load_model.assert_called_with(
        "dummy_model", "", load_model_args)

  def test_load_model_with_args_and_custom_weights(self):
    load_model_args = {compile: False, 'custom_objects': {'optimizer': 1}}
    model_handler = TFModelHandlerNumpy(
        "dummy_model",
        custom_weights="dummy_weights",
        load_model_args=load_model_args)
    model_handler.load_model()
    tensorflow_inference._load_model.assert_called_with(
        "dummy_model", "dummy_weights", load_model_args)


if __name__ == '__main__':
  unittest.main()
