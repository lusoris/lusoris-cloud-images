// Copyright 2026 Lusoris
// Package mcp wires a Model Context Protocol (MCP) server exposing lusoris-cloud-images
// tool capabilities to AI agents and IDEs.
package mcp

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"

	sdkmcp "github.com/modelcontextprotocol/go-sdk/mcp"

	"github.com/lusoris/lusoris-cloud-images/pkg/builder"
	"github.com/lusoris/lusoris-cloud-images/pkg/cloudinit"
	"github.com/lusoris/lusoris-cloud-images/pkg/flavors"
	"github.com/lusoris/lusoris-cloud-images/pkg/imageless"
	"github.com/lusoris/lusoris-cloud-images/pkg/manifest"
	"github.com/lusoris/lusoris-cloud-images/pkg/standards"
	"github.com/lusoris/lusoris-cloud-images/pkg/tracker"
)

// Server re-exports the SDK server type.
type Server = sdkmcp.Server

// NewServer builds and registers all Lusoris tools on the MCP server.
func NewServer(logger *slog.Logger) *sdkmcp.Server {
	s := sdkmcp.NewServer(
		&sdkmcp.Implementation{Name: "lusoris-forge", Version: "0.1.0"},
		&sdkmcp.ServerOptions{Logger: logger},
	)

	registerFlavorTools(s)
	registerManifestTools(s)
	registerCloudInitTools(s)
	registerStandardsTools(s)
	registerTrackerTools(s)
	registerComplianceTools(s)
	registerExecutionTools(s)

	return s
}

func registerFlavorTools(s *sdkmcp.Server) {
	s.AddTool(
		&sdkmcp.Tool{
			Name:        "list_flavors",
			Description: "List all 44 available image flavors categorized by workload tier",
			InputSchema: json.RawMessage(`{"type":"object","properties":{"tier":{"type":"string","description":"Optional filter by tier ID (base, containers, kubernetes, k3s, cloudnative, ai-infer, homelab)"}}}`),
		},
		func(ctx context.Context, req *sdkmcp.CallToolRequest) (*sdkmcp.CallToolResult, error) {
			var args struct {
				Tier string `json:"tier"`
			}
			_ = json.Unmarshal(req.Params.Arguments, &args)

			var list []flavors.Flavor
			if args.Tier != "" {
				list = flavors.FilterByTier(args.Tier)
			} else {
				list = flavors.All()
			}
			out, _ := json.MarshalIndent(list, "", "  ")
			return &sdkmcp.CallToolResult{Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: string(out)}}}, nil
		},
	)

	s.AddTool(
		&sdkmcp.Tool{
			Name:        "get_flavor",
			Description: "Get detailed hardware specifications, kernel profiles, and provisioners for a specific flavor",
			InputSchema: json.RawMessage(`{"type":"object","required":["flavor_id"],"properties":{"flavor_id":{"type":"string"}}}`),
		},
		func(ctx context.Context, req *sdkmcp.CallToolRequest) (*sdkmcp.CallToolResult, error) {
			var args struct {
				FlavorID string `json:"flavor_id"`
			}
			if err := json.Unmarshal(req.Params.Arguments, &args); err != nil {
				return nil, err
			}
			fl, err := flavors.Get(args.FlavorID)
			if err != nil {
				return &sdkmcp.CallToolResult{IsError: true, Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: err.Error()}}}, nil
			}
			out, _ := json.MarshalIndent(fl, "", "  ")
			return &sdkmcp.CallToolResult{Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: string(out)}}}, nil
		},
	)
}

func registerManifestTools(s *sdkmcp.Server) {
	s.AddTool(
		&sdkmcp.Tool{
			Name:        "validate_manifest",
			Description: "Validate versions.json Single Source of Truth against semantic schema",
			InputSchema: json.RawMessage(`{"type":"object","properties":{"path":{"type":"string","description":"Path to versions.json"}}}`),
		},
		func(ctx context.Context, req *sdkmcp.CallToolRequest) (*sdkmcp.CallToolResult, error) {
			var args struct {
				Path string `json:"path"`
			}
			_ = json.Unmarshal(req.Params.Arguments, &args)
			p := args.Path
			if p == "" {
				p = "versions.json"
			}
			m, err := manifest.Load(p)
			if err != nil {
				return &sdkmcp.CallToolResult{IsError: true, Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: err.Error()}}}, nil
			}
			msg := fmt.Sprintf("Validation SUCCESS: Distribution %s (%s %s), K8s %s, Containerd %s, Docker CE %s",
				m.Distro.Name, m.Distro.Release, m.Distro.Version, m.Kubernetes.Version, m.Runtimes.Containerd, m.Runtimes.DockerCE)
			return &sdkmcp.CallToolResult{Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: msg}}}, nil
		},
	)
}

func registerCloudInitTools(s *sdkmcp.Server) {
	s.AddTool(
		&sdkmcp.Tool{
			Name:        "generate_cloudinit",
			Description: "Generate hardened cloud-init user-data for Proxmox, Unraid, VMware, macOS, or Windows",
			InputSchema: json.RawMessage(`{"type":"object","required":["flavor"],"properties":{"flavor":{"type":"string"},"hostname":{"type":"string"},"user":{"type":"string"},"platform":{"type":"string"}}}`),
		},
		func(ctx context.Context, req *sdkmcp.CallToolRequest) (*sdkmcp.CallToolResult, error) {
			var args struct {
				Flavor   string `json:"flavor"`
				Hostname string `json:"hostname"`
				User     string `json:"user"`
				Platform string `json:"platform"`
			}
			if err := json.Unmarshal(req.Params.Arguments, &args); err != nil {
				return nil, err
			}
			cfg := cloudinit.DefaultConfig(args.Flavor)
			if args.Hostname != "" {
				cfg.Hostname = args.Hostname
			}
			if args.User != "" {
				cfg.User = args.User
			}
			if args.Platform != "" {
				cfg.Platform = args.Platform
			}
			ud, err := cloudinit.GenerateUserData(cfg)
			if err != nil {
				return &sdkmcp.CallToolResult{IsError: true, Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: err.Error()}}}, nil
			}
			return &sdkmcp.CallToolResult{Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: ud}}}, nil
		},
	)
}

func registerStandardsTools(s *sdkmcp.Server) {
	s.AddTool(
		&sdkmcp.Tool{
			Name:        "get_standards",
			Description: "Get machine-verifiable CIS and BSI hardening requirements for a flavor",
			InputSchema: json.RawMessage(`{"type":"object","required":["flavor_id"],"properties":{"flavor_id":{"type":"string"}}}`),
		},
		func(ctx context.Context, req *sdkmcp.CallToolRequest) (*sdkmcp.CallToolResult, error) {
			var args struct {
				FlavorID string `json:"flavor_id"`
			}
			if err := json.Unmarshal(req.Params.Arguments, &args); err != nil {
				return nil, err
			}
			std, err := standards.Get(args.FlavorID)
			if err != nil {
				return &sdkmcp.CallToolResult{IsError: true, Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: err.Error()}}}, nil
			}
			out, _ := json.MarshalIndent(std, "", "  ")
			return &sdkmcp.CallToolResult{Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: string(out)}}}, nil
		},
	)
}

func registerTrackerTools(s *sdkmcp.Server) {
	s.AddTool(
		&sdkmcp.Tool{
			Name:        "list_epics",
			Description: "List tracked architectural and operational recurring epics",
			InputSchema: json.RawMessage(`{"type":"object"}`),
		},
		func(ctx context.Context, req *sdkmcp.CallToolRequest) (*sdkmcp.CallToolResult, error) {
			epics, err := tracker.LoadEpics(filepath.Join(".github", "epics.json"))
			if err != nil {
				return &sdkmcp.CallToolResult{IsError: true, Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: err.Error()}}}, nil
			}
			out, _ := json.MarshalIndent(epics, "", "  ")
			return &sdkmcp.CallToolResult{Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: string(out)}}}, nil
		},
	)

	s.AddTool(
		&sdkmcp.Tool{
			Name:        "get_milestones",
			Description: "List open release milestones and due dates",
			InputSchema: json.RawMessage(`{"type":"object"}`),
		},
		func(ctx context.Context, req *sdkmcp.CallToolRequest) (*sdkmcp.CallToolResult, error) {
			ms, err := tracker.LoadMilestones(filepath.Join(".github", "milestones.json"))
			if err != nil {
				return &sdkmcp.CallToolResult{IsError: true, Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: err.Error()}}}, nil
			}
			out, _ := json.MarshalIndent(ms, "", "  ")
			return &sdkmcp.CallToolResult{Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: string(out)}}}, nil
		},
	)
}

func registerComplianceTools(s *sdkmcp.Server) {
	s.AddTool(
		&sdkmcp.Tool{
			Name:        "inspect_compliance",
			Description: "Inspect the declarative Goss compliance-as-code specification (CIS Level 2, DISA STIG, NIST SP 800-53)",
			InputSchema: json.RawMessage(`{"type":"object","properties":{"path":{"type":"string","description":"Optional path to goss.yaml"}}}`),
		},
		func(ctx context.Context, req *sdkmcp.CallToolRequest) (*sdkmcp.CallToolResult, error) {
			var args struct {
				Path string `json:"path"`
			}
			_ = json.Unmarshal(req.Params.Arguments, &args)
			p := args.Path
			if p == "" {
				p = filepath.Join("tests", "compliance", "goss.yaml")
			}
			data, err := os.ReadFile(p)
			if err != nil {
				return &sdkmcp.CallToolResult{IsError: true, Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: err.Error()}}}, nil
			}
			return &sdkmcp.CallToolResult{Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: string(data)}}}, nil
		},
	)
}

func registerExecutionTools(s *sdkmcp.Server) {
	s.AddTool(
		&sdkmcp.Tool{
			Name:        "trigger_build",
			Description: "Dispatch an image build to local Packer or remote CI backends (Gitea, Proxmox, GitLab, GitHub)",
			InputSchema: json.RawMessage(`{"type":"object","required":["flavor","backend"],"properties":{"flavor":{"type":"string"},"backend":{"type":"string"},"dry_run":{"type":"boolean"}}}`),
		},
		func(ctx context.Context, req *sdkmcp.CallToolRequest) (*sdkmcp.CallToolResult, error) {
			var args struct {
				Flavor  string `json:"flavor"`
				Backend string `json:"backend"`
				DryRun  bool   `json:"dry_run"`
			}
			if err := json.Unmarshal(req.Params.Arguments, &args); err != nil {
				return nil, err
			}
			res, err := builder.Dispatch(ctx, builder.Request{
				Backend: builder.Backend(args.Backend),
				Flavor:  args.Flavor,
				DryRun:  args.DryRun,
			})
			if err != nil {
				return &sdkmcp.CallToolResult{IsError: true, Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: err.Error()}}}, nil
			}
			out, _ := json.MarshalIndent(res, "", "  ")
			return &sdkmcp.CallToolResult{Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: string(out)}}}, nil
		},
	)

	s.AddTool(
		&sdkmcp.Tool{
			Name:        "apply_flavor",
			Description: "Generate an in-place live host or remote SSH flavor provisioning script (imageless execution)",
			InputSchema: json.RawMessage(`{"type":"object","required":["flavor_id"],"properties":{"flavor_id":{"type":"string"},"dry_run":{"type":"boolean"}}}`),
		},
		func(ctx context.Context, req *sdkmcp.CallToolRequest) (*sdkmcp.CallToolResult, error) {
			var args struct {
				FlavorID string `json:"flavor_id"`
				DryRun   bool   `json:"dry_run"`
			}
			if err := json.Unmarshal(req.Params.Arguments, &args); err != nil {
				return nil, err
			}
			script, err := imageless.GenerateApplyScript(imageless.ApplyOptions{
				FlavorID: args.FlavorID,
				DryRun:   args.DryRun,
			})
			if err != nil {
				return &sdkmcp.CallToolResult{IsError: true, Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: err.Error()}}}, nil
			}
			return &sdkmcp.CallToolResult{Content: []sdkmcp.Content{&sdkmcp.TextContent{Text: script}}}, nil
		},
	)
}

// RunStdio launches the server over stdio with stdoutRedirect protection.
func RunStdio(ctx context.Context, s *sdkmcp.Server, logger *slog.Logger) error {
	redirect, realStdout, err := installStdoutRedirect(nil)
	if err != nil {
		return err
	}
	defer func() { _ = redirect.Close() }()

	transport := newStdioTransport(stdin, realStdout)
	logger.Info("mcp: serving on stdio with stdout framing protection")
	return s.Run(ctx, transport)
}
