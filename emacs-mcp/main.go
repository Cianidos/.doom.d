// emacs-mcp: MCP stdio server exposing Emacs as tools via emacsclient.
// Zero dependencies beyond stdlib.
package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"
)

// --- JSON-RPC types ---

type request struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Method  string          `json:"method"`
	Params  json.RawMessage `json:"params,omitempty"`
}

type response struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id"`
	Result  any             `json:"result,omitempty"`
	Error   *rpcError       `json:"error,omitempty"`
}

type rpcError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

// --- MCP types ---

type tool struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	InputSchema any    `json:"inputSchema"`
}

type toolResult struct {
	Content []contentBlock `json:"content"`
	IsError bool           `json:"isError,omitempty"`
}

type contentBlock struct {
	Type string `json:"type"`
	Text string `json:"text"`
}

// --- tools ---

var tools = []tool{
	{
		Name:        "emacs_eval",
		Description: "Evaluate an Emacs Lisp expression in the running Emacs instance and return the result.",
		InputSchema: map[string]any{
			"type": "object",
			"properties": map[string]any{
				"code": map[string]any{
					"type":        "string",
					"description": "Elisp expression to evaluate",
				},
			},
			"required": []string{"code"},
		},
	},
	{
		Name:        "emacs_context",
		Description: "Get the user's current Emacs context: active buffer, file, line, column, major mode, workspace, and recent files.",
		InputSchema: map[string]any{"type": "object", "properties": map[string]any{}},
	},
	{
		Name:        "emacs_goto",
		Description: "Open a file in Emacs and optionally jump to a specific line.",
		InputSchema: map[string]any{
			"type": "object",
			"properties": map[string]any{
				"file": map[string]any{
					"type":        "string",
					"description": "Absolute path to the file",
				},
				"line": map[string]any{
					"type":        "integer",
					"description": "Line number (optional)",
				},
			},
			"required": []string{"file"},
		},
	},
	{
		Name:        "emacs_buffers",
		Description: "List open file-visiting buffers grouped by workspace.",
		InputSchema: map[string]any{"type": "object", "properties": map[string]any{}},
	},
	{
		Name:        "emacs_messages",
		Description: "Return recent lines from the *Messages* buffer — Emacs log of errors, warnings, and status output.",
		InputSchema: map[string]any{
			"type": "object",
			"properties": map[string]any{
				"lines": map[string]any{
					"type":        "integer",
					"description": "Number of recent lines to return (default 50)",
				},
			},
		},
	},
	{
		Name:        "emacs_find_function",
		Description: "Return the source code of an Emacs Lisp function or variable without opening it in the user's editor.",
		InputSchema: map[string]any{
			"type": "object",
			"properties": map[string]any{
				"symbol": map[string]any{
					"type":        "string",
					"description": "Function or variable name",
				},
			},
			"required": []string{"symbol"},
		},
	},
}

// --- emacsclient ---

func emacsEval(code string) (string, error) {
	cmd := exec.Command("emacsclient", "-e", code)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	timer := time.AfterFunc(10*time.Second, func() { cmd.Process.Kill() })
	out, err := cmd.Output()
	timer.Stop()
	if err != nil {
		if msg := strings.TrimSpace(stderr.String()); msg != "" {
			return "", fmt.Errorf("%s", msg)
		}
		return "", fmt.Errorf("emacsclient: %w", err)
	}
	return strings.TrimSpace(string(out)), nil
}

// unquoteElisp handles emacsclient's outer quoting: if the result is a
// JSON string wrapped in elisp quotes, peel one layer.
func unquoteElisp(raw string) string {
	if len(raw) >= 2 && raw[0] == '"' {
		var s string
		if err := json.Unmarshal([]byte(raw), &s); err == nil {
			return s
		}
	}
	return raw
}

func prettyJSON(s string) string {
	var v any
	if err := json.Unmarshal([]byte(s), &v); err == nil {
		b, _ := json.MarshalIndent(v, "", "  ")
		return string(b)
	}
	return s
}

// --- tool handlers ---

func handleEval(params map[string]any) toolResult {
	code, _ := params["code"].(string)
	if code == "" {
		return toolResult{Content: []contentBlock{{Type: "text", Text: "error: empty code"}}, IsError: true}
	}
	out, err := emacsEval(code)
	if err != nil {
		return toolResult{Content: []contentBlock{{Type: "text", Text: err.Error()}}, IsError: true}
	}
	return toolResult{Content: []contentBlock{{Type: "text", Text: out}}}
}

func handleContext(_ map[string]any) toolResult {
	code := `
(let* ((buf (window-buffer (selected-window)))
       (file (buffer-file-name buf))
       (ws (if (bound-and-true-p persp-mode)
               (safe-persp-name (get-current-persp))
             "N/A"))
       (pt (with-current-buffer buf (point)))
       (line (with-current-buffer buf (line-number-at-pos pt)))
       (col (with-current-buffer buf (current-column)))
       (mode (with-current-buffer buf (symbol-name major-mode)))
       (modified (buffer-modified-p buf))
       (recents (cl-loop for b in (buffer-list)
                         for f = (buffer-file-name b)
                         when f collect f into fs
                         finally return (seq-take fs 10))))
  (json-encode
   ` + "`" + `((buffer . ,(buffer-name buf))
     (file . ,(or file :null))
     (line . ,line)
     (column . ,col)
     (major_mode . ,mode)
     (workspace . ,ws)
     (modified . ,(if modified t :false))
     (recent_files . ,(vconcat recents)))))
`
	raw, err := emacsEval(code)
	if err != nil {
		return toolResult{Content: []contentBlock{{Type: "text", Text: err.Error()}}, IsError: true}
	}
	return toolResult{Content: []contentBlock{{Type: "text", Text: prettyJSON(unquoteElisp(raw))}}}
}

func handleGoto(params map[string]any) toolResult {
	file, _ := params["file"].(string)
	if file == "" {
		return toolResult{Content: []contentBlock{{Type: "text", Text: "error: file required"}}, IsError: true}
	}
	var code string
	if line, ok := params["line"].(float64); ok && line > 0 {
		code = fmt.Sprintf(`(progn (find-file %q) (goto-char (point-min)) (forward-line %d) "ok")`, file, int(line)-1)
	} else {
		code = fmt.Sprintf(`(progn (find-file %q) "ok")`, file)
	}
	out, err := emacsEval(code)
	if err != nil {
		return toolResult{Content: []contentBlock{{Type: "text", Text: err.Error()}}, IsError: true}
	}
	return toolResult{Content: []contentBlock{{Type: "text", Text: out}}}
}

func handleBuffers(_ map[string]any) toolResult {
	code := `
(let ((result '()))
  (if (bound-and-true-p persp-mode)
      (dolist (p (persp-names))
        (let* ((persp (persp-get-by-name p))
               (bufs (when persp
                       (cl-loop for b in (persp-buffers persp)
                                for f = (buffer-file-name b)
                                when f collect f))))
          (push (list p bufs) result)))
    (let ((bufs (cl-loop for b in (buffer-list)
                         for f = (buffer-file-name b)
                         when f collect f)))
      (push (list "all" bufs) result)))
  (json-encode (nreverse result)))
`
	raw, err := emacsEval(code)
	if err != nil {
		return toolResult{Content: []contentBlock{{Type: "text", Text: err.Error()}}, IsError: true}
	}
	return toolResult{Content: []contentBlock{{Type: "text", Text: prettyJSON(unquoteElisp(raw))}}}
}

func handleMessages(params map[string]any) toolResult {
	n := 50
	if v, ok := params["lines"].(float64); ok && v > 0 {
		n = int(v)
	}
	code := fmt.Sprintf(`
(with-current-buffer "*Messages*"
  (let* ((lines (split-string (buffer-string) "\n" t))
         (tail (last lines %d)))
    (string-join tail "\n")))
`, n)
	out, err := emacsEval(code)
	if err != nil {
		return toolResult{Content: []contentBlock{{Type: "text", Text: err.Error()}}, IsError: true}
	}
	return toolResult{Content: []contentBlock{{Type: "text", Text: unquoteElisp(out)}}}
}

func handleFindFunction(params map[string]any) toolResult {
	sym, _ := params["symbol"].(string)
	if sym == "" {
		return toolResult{Content: []contentBlock{{Type: "text", Text: "error: symbol required"}}, IsError: true}
	}
	// Try function first, then variable. Track whether we opened a new buffer
	// and kill it afterwards so the user's buffer list stays clean.
	code := fmt.Sprintf(`
(let* ((sym (intern %q))
       (prior (buffer-list))
       (loc (or (condition-case nil (find-function-noselect sym) (error nil))
                (condition-case nil (find-variable-noselect sym) (error nil)))))
  (if (null loc)
      (format "Symbol not found: %%s" sym)
    (let* ((buf (car loc))
           (pos (cdr loc))
           (new-buf (not (memq buf prior)))
           (src (condition-case err
                    (with-current-buffer buf
                      (goto-char pos)
                      (buffer-substring-no-properties
                       pos (save-excursion (end-of-defun) (point))))
                  (error (format "Error reading source: %%s" err)))))
      (when new-buf (kill-buffer buf))
      src)))
`, sym)
	out, err := emacsEval(code)
	if err != nil {
		return toolResult{Content: []contentBlock{{Type: "text", Text: err.Error()}}, IsError: true}
	}
	return toolResult{Content: []contentBlock{{Type: "text", Text: unquoteElisp(out)}}}
}

var handlers = map[string]func(map[string]any) toolResult{
	"emacs_eval":          handleEval,
	"emacs_context":       handleContext,
	"emacs_goto":          handleGoto,
	"emacs_buffers":       handleBuffers,
	"emacs_messages":      handleMessages,
	"emacs_find_function": handleFindFunction,
}

// --- main loop ---

func send(msg response) {
	b, _ := json.Marshal(msg)
	fmt.Println(string(b))
}

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Buffer(make([]byte, 0, 1024*1024), 1024*1024)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		var req request
		if err := json.Unmarshal([]byte(line), &req); err != nil {
			continue
		}

		switch req.Method {
		case "initialize":
			send(response{JSONRPC: "2.0", ID: req.ID, Result: map[string]any{
				"protocolVersion": "2024-11-05",
				"capabilities":    map[string]any{"tools": map[string]any{}},
				"serverInfo":      map[string]any{"name": "emacs-mcp", "version": "0.2.0"},
			}})

		case "notifications/initialized":
			// no response

		case "tools/list":
			send(response{JSONRPC: "2.0", ID: req.ID, Result: map[string]any{"tools": tools}})

		case "tools/call":
			var p struct {
				Name      string         `json:"name"`
				Arguments map[string]any `json:"arguments"`
			}
			json.Unmarshal(req.Params, &p)

			h, ok := handlers[p.Name]
			if !ok {
				send(response{JSONRPC: "2.0", ID: req.ID, Error: &rpcError{Code: -32601, Message: "unknown tool: " + p.Name}})
				continue
			}
			result := h(p.Arguments)
			send(response{JSONRPC: "2.0", ID: req.ID, Result: result})

		case "ping":
			send(response{JSONRPC: "2.0", ID: req.ID, Result: map[string]any{}})

		default:
			if req.ID != nil {
				send(response{JSONRPC: "2.0", ID: req.ID, Error: &rpcError{Code: -32601, Message: "method not found: " + req.Method}})
			}
		}
	}
}
