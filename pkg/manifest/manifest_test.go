// Copyright 2026 Lusoris
package manifest_test

import (
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/lusoris/lusoris-cloud-images/pkg/manifest"
)

func TestLoadActualVersionsJSON(t *testing.T) {
	rootPath, err := filepath.Abs("../../versions.json")
	require.NoError(t, err)

	m, err := manifest.Load(rootPath)
	require.NoError(t, err)
	require.NotNil(t, m)

	assert.Equal(t, "ubuntu", m.Distro.Name)
	assert.Equal(t, "resolute", m.Distro.Release)
	assert.NotEmpty(t, m.Distro.ISOUrl)
	assert.NotEmpty(t, m.Distro.ISOChecksum)

	assert.NotEmpty(t, m.Kubernetes.Version)
	assert.NotEmpty(t, m.Kubernetes.Images.Cilium)
	assert.NotEmpty(t, m.Kubernetes.Images.CalicoCNI)
	assert.NotEmpty(t, m.Kubernetes.Images.Flannel)

	assert.NotEmpty(t, m.Drivers.NVIDIA.MainstreamDriver)
	assert.NotEmpty(t, m.Drivers.NVIDIA.ModernDriver)
	assert.NotEmpty(t, m.Drivers.NVIDIA.BleedingDriver)

	assert.NotEmpty(t, m.K3s.Version)
	assert.NotEmpty(t, m.Runtimes.Containerd)
	assert.NotEmpty(t, m.Runtimes.DockerCE)

	assert.NotEmpty(t, m.Time.AnycastNTS)
	assert.NotEmpty(t, m.Time.Stratum1NTS)
}

func TestValidateRejectsInvalid(t *testing.T) {
	m := &manifest.Manifest{}
	assert.Error(t, m.Validate())
}
