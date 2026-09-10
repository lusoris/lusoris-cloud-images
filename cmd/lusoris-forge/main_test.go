// Copyright 2026 Lusoris
package main

import (
	"bytes"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func executeCommand(args ...string) (string, error) {
	cmd := newRootCmd()
	buf := new(bytes.Buffer)
	cmd.SetOut(buf)
	cmd.SetErr(buf)
	cmd.SetArgs(args)
	err := cmd.Execute()
	return buf.String(), err
}

func TestRootHelp(t *testing.T) {
	out, err := executeCommand("--help")
	require.NoError(t, err)
	assert.Contains(t, out, "Lusoris Forge — Unified CLI & AI MCP Server")
	assert.Contains(t, out, "flavors")
	assert.Contains(t, out, "manifest")
	assert.Contains(t, out, "standards")
}

func TestFlavorsList(t *testing.T) {
	out, err := executeCommand("flavors", "list")
	require.NoError(t, err)
	assert.Contains(t, out, "base-generic")
	assert.Contains(t, out, "docker-generic")
	assert.Contains(t, out, "k8s-node-generic")
}

func TestFlavorsListFilterTier(t *testing.T) {
	out, err := executeCommand("flavors", "list", "--tier=base")
	require.NoError(t, err)
	assert.Contains(t, out, "base-generic")
	assert.NotContains(t, out, "appliance-game-server")
}

func TestFlavorsListJSON(t *testing.T) {
	out, err := executeCommand("flavors", "list", "--json")
	require.NoError(t, err)
	assert.Contains(t, out, `"id": "base-generic"`)
}

func TestFlavorsGet(t *testing.T) {
	out, err := executeCommand("flavors", "get", "base-generic")
	require.NoError(t, err)
	assert.Contains(t, out, `"id": "base-generic"`)
	assert.Contains(t, out, `"tier_id": "base"`)
}

func TestFlavorsGetInvalid(t *testing.T) {
	_, err := executeCommand("flavors", "get", "non-existent-flavor-xyz")
	assert.Error(t, err)
}

func TestManifestValidate(t *testing.T) {
	manifestPath, err := filepath.Abs("../../versions.json")
	require.NoError(t, err)

	out, err := executeCommand("manifest", "validate", "--path", manifestPath)
	require.NoError(t, err)
	assert.Contains(t, out, "is valid")
}

func TestStandardsList(t *testing.T) {
	out, err := executeCommand("standards", "list")
	require.NoError(t, err)
	assert.Contains(t, out, "FLAVOR ID")
}

func TestEpicsList(t *testing.T) {
	epicsPath, err := filepath.Abs("../../.github/epics.json")
	require.NoError(t, err)

	out, err := executeCommand("epics", "list", "--path", epicsPath)
	require.NoError(t, err)
	assert.Contains(t, out, "EPIC")
}

func TestMilestonesList(t *testing.T) {
	milestonesPath, err := filepath.Abs("../../.github/milestones.json")
	require.NoError(t, err)

	out, err := executeCommand("milestones", "list", "--path", milestonesPath)
	require.NoError(t, err)
	assert.Contains(t, out, "TITLE")
	assert.Contains(t, out, "v2026")
}
