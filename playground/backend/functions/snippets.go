package functions

import (
	"beam.apache.org/playground/backend/internal/db/datastore"
	"beam.apache.org/playground/backend/internal/utils"
	"context"
	"fmt"
	"net/http"
	"time"

	"beam.apache.org/playground/backend/internal/db/mapper"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

const retentionPeriod = 100 * time.Hour * 24

var db *datastore.Datastore

func init() {
	fmt.Printf("Initializing snippets functions\n")

	env := GetEnvironment()

	pcMapper := mapper.NewPrecompiledObjectMapper()
	var err error
	db, err = datastore.New(context.Background(), pcMapper, nil, env.GetProjectId())
	if err != nil {
		fmt.Printf("Couldn't create the database client, err: %s\n", err.Error())
		panic(err)
	}

	ensurePost := EnsureMethod(http.MethodPost)

	functions.HTTP("cleanupSnippets", ensurePost(cleanupSnippets))
	functions.HTTP("deleteObsoleteSnippets", ensurePost(deleteObsoleteSnippets))
	functions.HTTP("incrementSnippetViews", ensurePost(incrementSnippetViews))
}

func handleError(w http.ResponseWriter, statusCode int, err error) {
	// Return 500 error and error message
	w.WriteHeader(statusCode)
	_, werr := w.Write([]byte(err.Error()))
	if werr != nil {
		fmt.Printf("Couldn't write error message, err: %s \n", werr.Error())
	}
}

// cleanupSnippets removes old snippets from the database.
func cleanupSnippets(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	err := db.DeleteUnusedSnippets(ctx, retentionPeriod)
	if err != nil {
		fmt.Printf("Couldn't delete unused code snippets, err: %s \n", err.Error())
		handleError(w, http.StatusInternalServerError, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func deleteObsoleteSnippets(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	snipId := r.URL.Query().Get("snipId")
	persistenceKey := r.URL.Query().Get("persistenceKey")

	snipKey := utils.GetSnippetKey(ctx, snipId)
	err := db.DeleteObsoleteSnippets(ctx, snipKey, persistenceKey)
	if err != nil {
		fmt.Printf("Couldn't delete obsolete code snippets for snipId %s, persistenceKey %s, err: %s \n", snipId, persistenceKey, err.Error())
		handleError(w, http.StatusInternalServerError, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func incrementSnippetViews(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	snipId := r.URL.Query().Get("snipId")

	err := db.IncrementSnippetVisitorsCount(ctx, snipId)
	if err != nil {
		fmt.Printf("Couldn't increment snippet visitors count for snipId %s, err: %s \n", snipId, err.Error())
		handleError(w, http.StatusInternalServerError, err)
		return
	}
}
