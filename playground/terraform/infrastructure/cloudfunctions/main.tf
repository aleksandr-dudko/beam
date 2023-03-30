#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

resource "google_cloudfunctions_function" "playground_function" {
  name        = "playground-function"
  description = "Playground function"
  runtime     = "go120"
  entry_point = "PlaygroundFunction"
  source_archive_bucket = var.gkebucket
  source_archive_object = "cloudfunction.zip"
  trigger_http = true

  environment_variables = {
    example_env_var = "example_value"
  }

  timeout = "120"
  available_memory_mb = 2048
  service_account_email = var.service_account_email_cf
}