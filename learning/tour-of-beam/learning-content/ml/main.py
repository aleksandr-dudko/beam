import argparse

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions, GoogleCloudOptions, SetupOptions

PROJECT = 'tess-372508'
BUCKET = 'btestq'
schema = 'id:INTEGER,region:STRING'


class Split(beam.DoFn):

    def process(self, element):
        id, region = element.split(",")

        return [{
            'id': int(id),
            'region': region,
        }]


def run(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument('--project={0}'.format(PROJECT))
    parser.add_argument('--temp_location=gs://{0}/staging/'.format(BUCKET))
    parser.add_argument('--no_auth=True')
    parser.add_argument('--service_account=service-account@tess-372508.iam.gserviceaccount.com')

    known_args, pipeline_args = parser.parse_known_args(argv)

    pipeline_options = GoogleCloudOptions(pipeline_args)

    with beam.Pipeline(options=pipeline_options, argv=argv) as p:
        (p | 'WriteToBigQuery' >> beam.io.ReadFromBigQuery(gcs_location = '{0}:fir.xasw'.format(PROJECT),query='SELECT * FROM `tess-372508:fir.xasw`'))

if __name__ == '__main__':
    run()
