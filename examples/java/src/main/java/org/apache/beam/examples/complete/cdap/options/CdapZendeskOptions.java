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
package org.apache.beam.examples.complete.cdap.options;

import org.apache.beam.sdk.options.Default;
import org.apache.beam.sdk.options.Description;
import org.apache.beam.sdk.options.PipelineOptions;
import org.apache.beam.sdk.options.Validation;

public interface CdapZendeskOptions extends PipelineOptions {

  @Validation.Required
  @Description("Zendesk base url.")
  String getZendeskBaseUrl();

  void setZendeskBaseUrl(String zendeskBaseUrl);

  @Validation.Required
  @Description("Zendesk admin email.")
  String getAdminEmail();

  void setAdminEmail(String adminEmail);

  @Validation.Required
  @Description("Zendesk api token.")
  String getApiToken();

  void setApiToken(String apiToken);

  @Default.String("api/v2")
  @Description("Zendesk subdomains.")
  String getSubdomains();

  void setSubdomains(String subdomains);

  @Default.Integer(10000)
  @Description("Zendesk maxRetryCount.")
  Integer getMaxRetryCount();

  void setMaxRetryCount(Integer maxRetryCount);

  @Default.Integer(10000)
  @Description("Zendesk maxRetryWait.")
  Integer getMaxRetryWait();

  void setMaxRetryWait(Integer maxRetryWait);

  @Default.Integer(10000)
  @Description("Zendesk maxRetryJitterWait.")
  Integer getMaxRetryJitterWait();

  void setMaxRetryJitterWait(Integer maxRetryJitterWait);

  @Default.Integer(10)
  @Description("Zendesk connectTimeout.")
  Integer getConnectTimeout();

  void setConnectTimeout(Integer connectTimeout);

  @Default.Integer(10)
  @Description("Zendesk readTimeout.")
  Integer getReadTimeout();

  void setReadTimeout(Integer readTimeout);

  @Default.String("Groups")
  @Description("Zendesk objectsToPull.")
  String getObjectsToPull();

  void setObjectsToPull(String objectsToPull);

  @Default.String("/Users/andrey/work/cdapZendeskOutput")
  @Description("FileIO output directory.")
  String getFileIoOutputDirectory();

  void setFileIoOutputDirectory(String fileIoOutputDirectory);
}
