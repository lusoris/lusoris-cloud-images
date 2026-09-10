// Copyright 2026 Lusoris
package mcp

import (
	"fmt"
	"io"
	"os"

	sdkmcp "github.com/modelcontextprotocol/go-sdk/mcp"
)

var stdin io.ReadCloser = os.Stdin

var newStdioTransport = func(r io.ReadCloser, w io.WriteCloser) sdkmcp.Transport {
	return &sdkmcp.IOTransport{Reader: r, Writer: w}
}

// stdoutRedirect pins the real stdout for the MCP stdio transport and replaces
// the process-global os.Stdout with a pipe whose contents are copied to stderr.
// This guarantees JSON-RPC framing on the genuine stdout while any stray
// fmt.Println / library write in app code lands on stderr instead of corrupting
// the protocol.
type stdoutRedirect struct {
	real     *os.File
	writeEnd *os.File
	done     chan struct{}
	sink     io.Writer
}

// installStdoutRedirect captures os.Stdout, swaps in a pipe that drains to
// sink, and returns the redirect handle plus the pinned real stdout writer.
func installStdoutRedirect(sink io.Writer) (*stdoutRedirect, *os.File, error) {
	if sink == nil {
		sink = os.Stderr
	}
	readEnd, writeEnd, err := os.Pipe()
	if err != nil {
		return nil, nil, fmt.Errorf("mcp: stdout redirect pipe: %w", err)
	}
	realOut := os.Stdout
	os.Stdout = writeEnd

	r := &stdoutRedirect{
		real:     realOut,
		writeEnd: writeEnd,
		done:     make(chan struct{}),
		sink:     sink,
	}
	go r.drain(readEnd)
	return r, realOut, nil
}

func (r *stdoutRedirect) drain(readEnd *os.File) {
	defer close(r.done)
	_, _ = io.Copy(r.sink, readEnd)
	_ = readEnd.Close()
}

// Close restores the original os.Stdout, closes the pipe write end, and waits
// for the drain goroutine to finish.
func (r *stdoutRedirect) Close() error {
	if r == nil {
		return nil
	}
	os.Stdout = r.real
	if err := r.writeEnd.Close(); err != nil {
		return fmt.Errorf("mcp: close stdout redirect: %w", err)
	}
	<-r.done
	return nil
}

// InstallStdoutRedirectForTest exposes redirect installation for internal testing.
func InstallStdoutRedirectForTest() (io.Closer, *os.File, error) {
	return installStdoutRedirect(nil)
}
