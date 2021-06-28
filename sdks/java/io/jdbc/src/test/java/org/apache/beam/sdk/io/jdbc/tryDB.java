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
package org.apache.beam.sdk.io.jdbc;

import org.apache.beam.runners.dataflow.DataflowRunner;
import org.apache.beam.runners.dataflow.options.DataflowPipelineOptions;
import org.apache.beam.sdk.Pipeline;
import org.apache.beam.sdk.coders.SerializableCoder;
import org.apache.beam.sdk.io.common.TestRow;
import org.apache.beam.sdk.options.PipelineOptions;
import org.apache.beam.sdk.options.PipelineOptionsFactory;
import org.apache.beam.sdk.testing.PAssert;
import org.apache.beam.sdk.transforms.Count;
import org.apache.beam.sdk.values.PCollection;

public class tryDB {

  public static void main(String[] args) {

    // Create a PipelineOptions object. This object lets us set various execution
    // options for our pipeline, such as the runner you wish to use. This example
    // will run with the DirectRunner by default, based on the class path configured
    // in its dependencies.
    PipelineOptions options = PipelineOptionsFactory.create();
    DataflowPipelineOptions dataflowOptions = options.as(DataflowPipelineOptions.class);
    dataflowOptions.setRunner(DataflowRunner.class);
    dataflowOptions.setProject("datatokenization");
    dataflowOptions.setTempLocation("gs://go_test/dasha/temp");
    dataflowOptions.setRegion("us-west1");

    // In order to run your pipeline, you need to make following runner specific changes:
    //
    // CHANGE 1/3: Select a Beam runner, such as BlockingDataflowRunner
    // or FlinkRunner.
    // CHANGE 2/3: Specify runner-required options.
    // For BlockingDataflowRunner, set project and temp location as follows:
    //   DataflowPipelineOptions dataflowOptions = options.as(DataflowPipelineOptions.class);
    //   dataflowOptions.setRunner(BlockingDataflowRunner.class);
    //   dataflowOptions.setProject("SET_YOUR_PROJECT_ID_HERE");
    //   dataflowOptions.setTempLocation("gs://SET_YOUR_BUCKET_NAME_HERE/AND_TEMP_DIRECTORY");
    // For FlinkRunner, set the runner as follows. See {@code FlinkPipelineOptions}
    // for more details.
    //   options.as(FlinkPipelineOptions.class)
    //      .setRunner(FlinkRunner.class);

    // Create the Pipeline object with the options we defined above
    Pipeline p = Pipeline.create(dataflowOptions);

    // Concept #1: Apply a root transform to the pipeline; in this case, TextIO.Read to read a set
    // of input text files. TextIO.Read returns a PCollection where each element is one line from
    // the input text (a set of Shakespeare's texts).

    // This example reads a public data set consisting of the complete works of Shakespeare.

    PCollection<TestRow> rows =
        p.apply(
            JdbcIO.<TestRow>readWithPartitions()
                .withDataSourceConfiguration(DATA_SOURCE_CONFIGURATION)
                .withRowMapper(new JdbcTestHelper.CreateTestRowOfNameAndId())
                .withCoder(SerializableCoder.of(TestRow.class))
                .withTable(READ_TABLE_NAME)
                .withNumPartitions(1)
                .withPartitionColumn("id")
                .withLowerBound(0)
                .withUpperBound(1000));
    PAssert.thatSingleton(rows.apply("Count All", Count.globally())).isEqualTo(1000L);

//    p.apply(TextIO.read().from("gs://go_test/dasha/text.txt"))
//
//        // Concept #2: Apply a FlatMapElements transform the PCollection of text lines.
//        // This transform splits the lines in PCollection<String>, where each element is an
//        // individual word in Shakespeare's collected texts.
//        .apply(
//            FlatMapElements.into(TypeDescriptors.strings())
//                .via((String line) -> Arrays.asList(line.split("[^\\p{L}]+"))))
//        // We use a Filter transform to avoid empty word
//        .apply(Filter.by((String word) -> !word.isEmpty()))
//        // Concept #3: Apply the Count transform to our PCollection of individual words. The Count
//        // transform returns a new PCollection of key/value pairs, where each key represents a
//        // unique word in the text. The associated value is the occurrence count for that word.
//        .apply(Count.perElement())
//        // Apply a MapElements transform that formats our PCollection of word counts into a
//        // printable string, suitable for writing to an output file.
//        .apply(
//            MapElements.into(TypeDescriptors.strings())
//                .via(
//                    (KV<String, Long> wordCount) ->
//                        wordCount.getKey() + ": " + wordCount.getValue()))
//        // Concept #4: Apply a write transform, TextIO.Write, at the end of the pipeline.
//        // TextIO.Write writes the contents of a PCollection (in this case, our PCollection of
//        // formatted strings) to a series of text files.
//        //
//        // By default, it will write to a set of files with names like wordcounts-00001-of-00005
//        .apply(TextIO.write().to("gs://go_test/dasha/output/"));

    p.run().waitUntilFinish();
  }
}
