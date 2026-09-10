// Copyright 2026 Lusoris
package mcp_test

import (
	"log/slog"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/lusoris/lusoris-cloud-images/pkg/mcp"
)

func TestNewServer(t *testing.T) {
	logger := slog.New(slog.DiscardHandler)
	srv := mcp.NewServer(logger)
	require.NotNil(t, srv)
}

func TestStdoutRedirect(t *testing.T) {
	// Verify that installStdoutRedirect works without error and restores stdout on Close
	r, realOut, err := mcp.InstallStdoutRedirectForTest()
	require.NoError(t, err)
	require.NotNil(t, r)
	require.NotNil(t, realOut)

	err = r.Close()
	assert.NoError(t, err)
}
