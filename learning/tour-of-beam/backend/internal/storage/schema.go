package storage

import (
	tob "beam.apache.org/learning/tour-of-beam/backend/internal"
	"cloud.google.com/go/datastore"
)

// ToB Datastore schema
// - Content tree has a root entity in tb_learning_path,
//   descendant entities in tb_learning_module/group/unit have it as a common ancestor
// - learning path consists of modules, modules consist of either groups or units
// - A group can have only 1 type of children: only units or only groups
// - Ordering is established by "order" property
// - To limit ancestor queries by only first-level descendants, "level" property is used

const (
	PgNamespace = "Playground"

	TbLearningPathKind   = "tb_learning_path"
	TbLearningModuleKind = "tb_learning_module"
	TbLearningGroupKind  = "tb_learning_group"
	TbLearningUnitKind   = "tb_learning_unit"

	PgSnippetsKind = "pg_snippets"
	PgSdksKind     = "pg_sdks"
)

// tb_learning_path
type TbLearningPath struct {
	Key  *datastore.Key `datastore:"__key__"`
	Name string         `datastore:"name"`
}

// 1-1 to Node model
type Node struct {
	Type  tob.NodeType
	Unit  *TbLearningUnit
	Group *TbLearningGroup
}

// tb_learning_module
type TbLearningModule struct {
	Key        *datastore.Key `datastore:"__key__"`
	Id         string         `datastore:"id"`
	Name       string         `datastore:"name"`
	Complexity string         `datastore:"complexity"`

	// internal, only db
	Order int `datastore:"order"`
}

// tb_learning_group
type TbLearningGroup struct {
	Key  *datastore.Key `datastore:"__key__"`
	Name string         `datastore:"name"`

	// internal, only db
	Order int `datastore:"order"`
	Level int `datastore:"level"`
}

// tb_learning_unit
type TbLearningUnit struct {
	// key: <sdk>_<id>
	Key *datastore.Key `datastore:"__key__"`

	Id          string   `datastore:"id"`
	Name        string   `datastore:"name"`
	Description string   `datastore:"description,noindex"`
	Hints       []string `datastore:"hints,noindex"`

	TaskSnippetId     string `datastore:"taskSnippetId"`
	SolutionSnippetId string `datastore:"solutionSnippetId"`

	// internal, only db
	Order int `datastore:"order"`
	Level int `datastore:"level"`
}

type PgSnippets struct {
	Key    *datastore.Key `datastore:"__key__"`
	Origin string         `datastore:"origin"`
	Sdk    *datastore.Key `datastore:"sdk"`
}
