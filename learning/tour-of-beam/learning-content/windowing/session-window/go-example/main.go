// Licensed to the Apache Software Foundation (ASF) under one or more
// contributor license agreements.  See the NOTICE file distributed with
// this work for additional information regarding copyright ownership.
// The ASF licenses this file to You under the Apache License, Version 2.0
// (the "License"); you may not use this file except in compliance with
// the License.  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// beam-playground:
//   name: session-window
//   description: Session window example.
//   multifile: false
//   context_line: 32
//   categories:
//     - Quickstart
//   complexity: ADVANCED
//   tags:
//     - hellobeam

package main

import (
  "context"
  "github.com/apache/beam/sdks/v2/go/pkg/beam"
  "github.com/apache/beam/sdks/v2/go/pkg/beam/log"
  "github.com/apache/beam/sdks/v2/go/pkg/beam/x/beamx"
  "github.com/apache/beam/sdks/v2/go/pkg/beam/core/graph/window"
  "fmt"
  "time"
)

func main() {
  p, s := beam.NewPipelineWithRoot()

  words := beam.Create(s, "Hello", "world", "it`s", "Windowing")

  sessionWindowedItems := beam.WindowInto(s, window.NewSessions(600*time.Second), words)

  output(s, sessionWindowedItems)

  err := beamx.Run(context.Background(), p)
  if err != nil {
    log.Exitf(context.Background(), "Failed to execute job: %v", err)
  }
}

func output(s beam.Scope, input beam.PCollection) {
  beam.ParDo0(s, func(element interface{}) {
    fmt.Println(element)
    }, input)
}