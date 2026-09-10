// Copyright 2026 Lusoris
package mcp_test

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/lusoris/lusoris-cloud-images/pkg/mcp"
)

func TestStagerLifecycle(t *testing.T) {
	stager := mcp.NewStager()
	require.NotNil(t, stager)

	// 1. Initial list empty
	actions := stager.List()
	assert.Empty(t, actions)

	// 2. Stage action
	payload := map[string]any{"flavor": "base-generic", "backend": "local"}
	act := stager.Stage("trigger_build", "base-generic", payload, "Build local base-generic")
	require.NotNil(t, act)
	assert.NotEmpty(t, act.ID)
	assert.Equal(t, mcp.StatusPending, act.Status)
	assert.Equal(t, "trigger_build", act.Tool)
	assert.Equal(t, "base-generic", act.Target)

	// 3. Get action
	fetched, err := stager.Get(act.ID)
	require.NoError(t, err)
	assert.Equal(t, act.ID, fetched.ID)

	// 4. List contains 1 action
	list := stager.List()
	assert.Len(t, list, 1)

	// 5. Confirm action
	confirmed, err := stager.Confirm(act.ID)
	require.NoError(t, err)
	assert.Equal(t, mcp.StatusConfirmed, confirmed.Status)

	// 6. Confirming again should error
	_, err = stager.Confirm(act.ID)
	assert.Error(t, err)

	// 7. Discard action
	err = stager.Discard(act.ID)
	require.NoError(t, err)

	// 8. Fetch after discard should fail
	_, err = stager.Get(act.ID)
	assert.Error(t, err)
}

func TestStagerErrors(t *testing.T) {
	stager := mcp.NewStager()

	_, err := stager.Get("nonexistent-id")
	assert.Error(t, err)

	_, err = stager.Confirm("nonexistent-id")
	assert.Error(t, err)

	err = stager.Discard("nonexistent-id")
	assert.Error(t, err)
}

func TestStagerPrune(t *testing.T) {
	stager := mcp.NewStager()
	payload := map[string]any{"test": true}

	act := stager.Stage("test_tool", "target1", payload, "preview1")
	require.NotNil(t, act)

	// Pruning with negative or large TTL shouldn't remove fresh action
	pruned := stager.Prune(1 * time.Hour)
	assert.Equal(t, 0, pruned)
	assert.Len(t, stager.List(), 1)

	// Pruning with 1 nanosecond (effectively anything in past)
	// We simulate expiration by pruning with -1 ns offset or by sleeping 2ms with 1ms TTL
	time.Sleep(2 * time.Millisecond)
	pruned = stager.Prune(1 * time.Millisecond)
	assert.Equal(t, 1, pruned)
	assert.Empty(t, stager.List())
}
