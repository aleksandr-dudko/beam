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

package s3

import "testing"

func Test_parseUri(t *testing.T) {
	tests := []struct {
		name       string
		uri        string
		wantBucket string
		wantKey    string
		wantErr    bool
	}{
		{
			name:       "Valid uri with non-empty key",
			uri:        "s3://bucket/path/to/key",
			wantBucket: "bucket",
			wantKey:    "path/to/key",
			wantErr:    false,
		},
		{
			name:       "Valid uri with empty key",
			uri:        "s3://bucket",
			wantBucket: "bucket",
			wantKey:    "",
			wantErr:    false,
		},
		{
			name:       "Invalid uri: missing scheme",
			uri:        "bucket/path/to/key",
			wantBucket: "",
			wantKey:    "",
			wantErr:    true,
		},
		{
			name:       "Invalid uri: wrong scheme",
			uri:        "file://bucket/path/to/key",
			wantBucket: "",
			wantKey:    "",
			wantErr:    true,
		},
		{
			name:       "Invalid uri: missing bucket",
			uri:        "s3://",
			wantBucket: "",
			wantKey:    "",
			wantErr:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gotBucket, gotKey, err := parseUri(tt.uri)
			if (err != nil) != tt.wantErr {
				t.Errorf("parseUri() err = %v, want %v", err, tt.wantErr)
			}
			if gotBucket != tt.wantBucket {
				t.Errorf("parseUri() bucket = %v, want %v", gotBucket, tt.wantBucket)
			}
			if gotKey != tt.wantKey {
				t.Errorf("parseUri() key = %v, want %v", gotKey, tt.wantKey)
			}
		})
	}
}

func Test_makeUri(t *testing.T) {
	bucket := "bucket"
	key := "path/to/key"
	want := "s3://bucket/path/to/key"

	if got := makeUri(bucket, key); got != want {
		t.Errorf("makeUri() = %v, want %v", got, want)
	}
}

func Test_getPrefix(t *testing.T) {
	tests := []struct {
		name       string
		keyPattern string
		want       string
	}{
		{
			name:       "Key pattern with wildcards",
			keyPattern: "path/**/*.json",
			want:       "path/",
		},
		{
			name:       "Key pattern without wildcards",
			keyPattern: "path/file.json",
			want:       "path/file.json",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := getPrefix(tt.keyPattern); got != tt.want {
				t.Errorf("getPrefix() = %v, want %v", got, tt.want)
			}
		})
	}
}
