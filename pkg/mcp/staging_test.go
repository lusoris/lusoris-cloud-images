// Copyright 2026 Lusoris
package mcp_test

import (
	"testing"

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
