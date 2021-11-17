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

import os
import re
import shutil
from pathlib import Path

import yaml
from google.cloud import storage
from api.v1.api_pb2 import Sdk, SDK_JAVA
from helper import Example, find_examples

PLAYGROUND_TAG = "beam-playground"
BUCKET_NAME = "test_public_bucket_akvelon"
TEMP_FOLDER = "temp"

EXTENSIONS = {"SDK_JAVA": "java", "SDK_GO": "go", "SDK_PYTHON": "py"}
PATTERN = 'Beam-playground:\n {2} *name: \w+\n {2} *description: .+\n {2} *multifile: (true|false)\n {2} *categories:\n( {4} *- [\w\-]+\n)+'
PATTERN_START = 'Beam-playground'


class CDHelper:
    """ Helper for CD step.

    It is used to save beam examples/katas/tests and their output on the Google Cloud.
    """

    def store_examples(self, examples: [Example]):
        """ Store beam examples and their output in the Google Cloud.
        """
        self._run_code_all_examples(examples)
        self._save_to_cloud_storage(examples)
        self.clear_temp_folder()

    def _run_code_all_examples(self, examples: [Example]):
        """ Run beam examples and keep their ouput.

        Call the backend to start code processing for the examples. Then receive code output.

        Args:
            examples: beam examples that should be run
        """
        # TODO [BEAM-13258] Implement logic
        for example in examples:
            example.output = "output"
            example.pipeline_id = "testpipeline_id"
            example.sdk = SDK_JAVA

    def _save_to_cloud_storage(self, examples: [Example]):
        """ Save beam examples and their output using backend instance.

        Args:
            examples: beam examples with their output
        """
        for example in examples:
            object_meta = self._get_data_from_template(example.code)
            file_names = self._write_to_os(example, object_meta)
            for cloud_file_name, local_file_name in file_names.items():
                self._upload_blob(source_file=local_file_name, destination_blob_name=cloud_file_name)

    def _write_to_os(self, example: Example, object_meta: dict):
        """

        Args:
            example: example object
            object_meta: meta information to this example

        Returns: array of file names

        """
        path_to_object_folder = os.path.join(TEMP_FOLDER, example.pipeline_id, Sdk.Name(example.sdk),
                                             object_meta["name"])
        Path(path_to_object_folder).mkdir(parents=True, exist_ok=True)

        file_names = dict()
        code_path = self._get_cloud_file_name(sdk=example.sdk, base_folder_name=object_meta["name"],
                                              file_name=object_meta["name"])
        output_path = self._get_cloud_file_name(sdk=example.sdk, base_folder_name=object_meta["name"],
                                                file_name=object_meta["name"], extension="output")
        meta_path = self._get_cloud_file_name(sdk=example.sdk, base_folder_name=object_meta["name"],
                                              file_name="meta", extension="info")
        file_names[code_path] = example.code
        file_names[output_path] = example.output
        file_names[meta_path] = str(object_meta)
        for file_name, file_content in file_names.items():
            local_file_path = os.path.join(TEMP_FOLDER, example.pipeline_id, file_name)
            with open(local_file_path, 'w') as file:
                file.write(file_content)
            file_names[
                file_name] = local_file_path  ## don't need content anymore, change to the local os path of the stored file
        return file_names

    def _get_data_from_template(self, code):
        """
        Args:
            code:  source code of an example

        Returns: dictionary with name, description, categories, etc of the source code

        """
        res = re.search(PATTERN, code)
        if res is not None and res.span() is not None:
            m = res.span()
            yaml_code = code[m[0]:m[1]]
            try:
                object_meta = yaml.load(yaml_code, Loader=yaml.SafeLoader)
                return object_meta[PATTERN_START]
            except Exception as exp:
                print(exp)  ## todo add logErr

    def _get_cloud_file_name(self, sdk: Sdk, base_folder_name: str, file_name: str, extension: str = None):
        """
        Args:
            sdk:
            file_name:
            base_folder_name:
            extension:

        Returns:

        """
        if extension is None:
            extension = EXTENSIONS[Sdk.Name(sdk)]
        return os.path.join(Sdk.Name(sdk), base_folder_name, "{}.{}".format(file_name, extension))

    def _upload_blob(self, source_file: str, destination_blob_name: str):
        """
        Uploads a file to the bucket.
        Args:
            source_file: name of the file to be stored
            destination_blob_name: "storage-object-name"
        Returns:

        """
        storage_client = storage.Client()
        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(destination_blob_name)
        blob.upload_from_filename(source_file)

        print("File uploaded to {}.".format(destination_blob_name))

    def clear_temp_folder(self):
        """
        Remove temporary folder with source files
        Returns: nothing

        """
        shutil.rmtree(TEMP_FOLDER)


if __name__ == '__main__':
    cd = CDHelper()
    examples = find_examples("/home/daria/IdeaProjects/beam/")
    cd.store_examples(examples)
