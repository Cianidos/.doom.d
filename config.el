;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; TODO: determine curretnt resolution and adopt to current dpi or something like this
(setq doom-font (font-spec :family "Iosevka" :weight 'light :size 40))

;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:

;; Semantic dimming theme — structural noise dimmed, definitions/constants highlighted
(setq! doom-theme 'doom-solarized-semantic)



;; Regex punctuation dimming for non-tree-sitter modes only
;; (tree-sitter modes use my/add-punctuation-for-lang instead)
(add-hook 'prog-mode-hook
          (lambda ()
            (unless (and (fboundp 'treesit-parser-list) (treesit-parser-list))
              (font-lock-add-keywords
               nil
               '(("[()\\[\\]{}]" 0 'font-lock-bracket-face)
                 ("[,;:.]" 0 'font-lock-punctuation-face))))))

(defun my/add-punctuation-for-lang (lang)
  "Add punctuation highlighting for LANG tree-sitter mode."
  (setq-local treesit-font-lock-settings
              (append treesit-font-lock-settings
                      (treesit-font-lock-rules
                       :language lang
                       :feature 'punctuation  
                       :override t
                       '([","  "." ";" ":"] @font-lock-punctuation-face))))
  (when (listp treesit-font-lock-feature-list)
    (setq-local treesit-font-lock-feature-list
                (mapcar (lambda (level)
                          (if (equal level (car (last treesit-font-lock-feature-list)))
                              (append level '(punctuation))
                            level))
                        treesit-font-lock-feature-list)))
  (treesit-major-mode-setup))

;; Apply to modes
(add-hook! 'go-ts-mode-hook (lambda () (my/add-punctuation-for-lang 'go)))
(add-hook! 'typescript-ts-mode-hook (lambda () (my/add-punctuation-for-lang 'typescript)))

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq! display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default locatio below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(after! server
  (unless (server-running-p)
    (server-start)))

;; no dired polution
(setf dired-kill-when-opening-new-dired-buffer t)

(after! tramp
  (setq! remote-file-name-inhibit-locks t
         tramp-use-scp-direct-remote-copying t
         remote-file-name-inhibit-auto-save-visited t
         tramp-copy-size-limit (* 1024 1024))) ;; 1MB

(setq-default
 tab-width 2
 standard-indent 2
 evil-shift-width 2
 go-ts-mode-indent-offset 2
 c-ts-common-indent-offset 2
 typescript-ts-mode-indent-offset 2
 )



(global-set-key (kbd "<XF86Copy>")  #'kill-ring-save)
(global-set-key (kbd "<XF86Cut>")   #'kill-region)
(global-set-key (kbd "<XF86Paste>") #'yank)

(map!
 :nv "] e" #'flycheck-next-error
 :nv "[ e" #'flycheck-previous-error

 ;; :nv "] e" #'flymake-goto-next-error
 ;; :nv "[ e" #'flymake-goto-prev-error
 :nv "g t" #'+lookup/type-definition
 ;; :nv "g D" nil
 :mn "g D" #'+lookup/references

 :nvi "S-<left>" #'evil-window-left
 :nvi "S-<right>" #'evil-window-right
 :nvi "S-<up>" #'evil-window-up
 :nvi "S-<down>" #'evil-window-down

 :m "C-w <left>" #'+evil/window-move-left
 :m "C-w <right>" #'+evil/window-move-right
 :m "C-w <up>" #'+evil/window-move-up
 :m "C-w <down>" #'+evil/window-move-down

 "s-<left>" #'back-to-indentation
 "s-<right>" #'end-of-line

 "M-ъ" (lambda () (interactive) (insert "="))
 "M-Ъ" (lambda () (interactive) (insert "+"))
 "M-ь" (lambda () (interactive) (insert "-"))
 "M-Ь" (lambda () (interactive) (insert "_"))

 :mnv "g C-c" #'evilnc-copy-and-comment-lines

 :map dired-mode-map
 :mn "M-p" #'dirvish-move
 )

(defun my/smart-lookup ()
  "Smart lookup function that both finding definitions and references.

If point is on a definition, show references.
If point is on a reference, jump to definition."
  (interactive)
  (let* ((identifier (xref-backend-identifier-at-point (xref-find-backend)))
         (defs (xref-backend-definitions (xref-find-backend) identifier))
         (current-pos (point))
         (is-definition nil))
    (when defs
      (dolist (def defs)
        (let ((def-loc (xref-item-location def)))
          (when (and def-loc
                     (= current-pos
                        (save-excursion
                          (goto-char (xref-location-marker def-loc))
                          (point))))
            (setq is-definition t)))))
    (if is-definition
        (xref-find-references identifier)
      (xref-find-definitions identifier))))

;; Bind the function to a key combination (e.g., `C-]`).
(map! :n "C-]" #'my/smart-lookup)




;; ;; commented due to experements with keyboard
;; (defvar-local my/im (shell-command-to-string "im-select")
;;   "Stored imput method for evil state swithing.")

;; (defun my/exchange-im ()
;;   "Swaps initial value of \"my/im\" with current input method."
;;   (let ((tmp my/im)                     ;; keep old layaut
;;         (inhibit-message t))            ;; comands no print to minibuffer
;;     (setq-local my/im (shell-command-to-string "im-select")) ;; get curretn layout
;;     (if (not (equal tmp my/im))         ;; if different ; perfomance in some way
;;         (shell-command (concat "im-select " tmp))))) ;; change to old

;; (add-hook 'evil-insert-state-entry-hook #'my/exchange-im) ;; what we do when enter insert mode
;; (add-hook 'evil-insert-state-exit-hook #'my/exchange-im)  ;; what we do when enter normal mode



(after! which-key
  (setq!
   which-key-show-remaining-keys t
   which-key-add-column-padding 0
   which-key-dont-use-unicode nil
   ;; bugus in some reason
   ;; which-key-show-operator-state-maps t
   ;; adds keys borowser in which-key
   which-key-use-C-h-commands t
   which-key-compute-remaps t
   which-key-idle-delay 0.250
   which-key-separator " "
   ;; which-key-replacement-alist '(
   ;;                               (("SPC" . nil) . ("␠" . nil)) ;; Space icon
   ;;                               (("RET" . nil) . ("␍" . nil)) ;; Return icon
   ;;                               (("TAB" . nil) . ("￫" . nil)) ;; Tab icon
   ;;                               (("ESC" . nil) . ("␛" . nil)) ;; Escape icon
   ;;                               (("DEL" . nil) . ("␡" . nil))
   ;;                               )
   )
  )

(after! lispy
  ;; illuminate annoying screen/buffer movement
  ;; when editing in lispy-mode
  (setq lispy-recenter nil))

;; set emacs ask for .gpg files passphrase
(setq epg-pinentry-mode 'loopback)



(defun my/go-toggle-exported ()
  "Toggle the export status (public/private) of a Go symbol at point.

If the symbol starts with an uppercase letter (exported), it is made private by
changing its first letter to lowercase. Otherwise, it is made public by
capitalizing the first letter. The function then calls \"eglot-rename\" to
refactor the change across the project."
  (interactive)
  (let* ((symbol (thing-at-point 'symbol t)))
    (if (not symbol)
        (message "No symbol at point")
      (let* ((first-char (substring symbol 0 1))
             (new-first (if (string= first-char (upcase first-char))
                            (downcase first-char)
                          (upcase first-char)))
             (new-name (concat new-first (substring symbol 1))))
        (message "Renaming %s to %s" symbol new-name)
        (eglot-rename new-name)))))

(map! :n "M-p" nil
      :n :desc "Toggle Go Exported Symbol" "M-p" #'my/go-toggle-exported)

(use-package! vterm
  :config
  ;; Use emacs state so all keys pass through to the terminal naturally.
  ;; ESC reaches the shell. C-g still works as Emacs abort.
  (evil-set-initial-state 'vterm-mode 'emacs)

  (setq vterm-max-scrollback 10000
        vterm-copy-mode-remove-fake-newlines nil
        ;; Buffer names track the shell title (set by vterm_prompt_end in bash)
        vterm-buffer-name-string "vterm %s")

  ;; Register commands callable from shell via vterm_cmd
  (dolist (cmd '(("find-file"              find-file)
                 ("find-file-other-window" find-file-other-window)
                 ("magit-status"           magit-status)
                 ("dired"                  dired)
                 ("message"               message)))
    (add-to-list 'vterm-eval-cmds cmd))

  (map! :map vterm-mode-map
        ;; Unset number/bracket keys that were being swallowed by Doom/iflipb
        "M-]" nil "M-[" nil
        "M-1" nil "M-2" nil "M-3" nil "M-4" nil "M-5" nil
        "M-6" nil "M-7" nil "M-8" nil "M-9" nil "M-0" nil

        ;; Window navigation (must be explicit since we're in emacs state)
        "S-<left>"  #'evil-window-left
        "S-<right>" #'evil-window-right
        "S-<up>"    #'evil-window-up
        "S-<down>"  #'evil-window-down

        ;; Shift+Return → backslash + CR. Specifically to give Claude Code's
        ;; TUI a multi-line-input shortcut on the key you'd expect. Claude
        ;; reads `\\' + Enter as line-continuation; neither S-<return> nor
        ;; M-<return> work because vterm has no keyboard protocol to pass
        ;; modifiers, and Claude's input layer doesn't honor ESC+CR.
        "S-<return>" (cmd! (vterm-send-string "\\\r"))

        ;; Copy-mode: buffer becomes read-only, evil normal state activates,
        ;; you get vim motions, / search, y yank, etc.
        "C-c C-t" #'vterm-copy-mode
        "C-c C-z" (lambda () (interactive) (vterm-send "C-z"))
        )

  (map! :map vterm-copy-mode-map
        :n "q" #'vterm-copy-mode
        :n "i" #'vterm-copy-mode)

  (add-hook 'vterm-copy-mode-hook
            (lambda ()
              (if vterm-copy-mode
                  (evil-normal-state)
                (evil-emacs-state))))

  ;; Strip trailing whitespace from every line when yanking text out of
  ;; vterm-copy-mode. vterm pads lines to terminal width with spaces, which
  ;; TUIs like Claude Code exaggerate. Hooking `filter-buffer-substring-function'
  ;; catches every standard extraction path (kill-ring-save, evil yank,
  ;; copy-region-as-kill).
  (defun my/vterm-copy-trim-substring (beg end &optional delete)
    (let ((text (buffer-substring beg end)))
      (when delete (delete-region beg end))
      (replace-regexp-in-string "[ \t]+$" "" text)))

  (add-hook 'vterm-copy-mode-hook
            (defun my/vterm-copy-install-trim-h ()
              (when vterm-copy-mode
                (setq-local filter-buffer-substring-function
                            #'my/vterm-copy-trim-substring))))

  ;; Pin vterm buffer names to the workspace where they were created.
  ;; Sets vterm-buffer-name-string buffer-locally so every shell title update
  ;; (OSC rename) keeps the workspace prefix — not just the initial name.
  (add-hook 'vterm-mode-hook
            (lambda ()
              (when (and (bound-and-true-p persp-mode)
                         (modulep! :ui workspaces))
                (setq-local vterm-buffer-name-string
                            (format "vterm<%s> %%s" (+workspace-current-name)))))))

(use-package! iflipb
  :config

  ;; TODO: try to adopt this approach later.
  ;; or reseach default iflipb-buffer-list-function variants.
  ;; ido - variant looks ambicious, but probubly i need adopt vertico or "spc ," shortcut approach
  ;; NOTE: this buffer list don't fit this usecase properly.
  ;; Default buffer-list do reordering on swithing, but this not.
  ;; (setf iflipb-buffer-list-function #'doom-real-buffer-list)

  ;; (setf iflipb-buffer-list-function (lambda () (doom-buffer-list (selected-frame))))
  ;; (setf iflipb-ignore-buffers
  ;;       (lambda (buf)
  ;;         (and-let*
  ;;             (;; (workspace (+workspace-current))
  ;;              ;; ((not (+workspace-contains-buffer-p buf workspace)))
  ;;              ((not (+popup-buffer-p buf)))
  ;;              ;; ((not (help buffer p)))
  ;;              ;; ((not (doom-unreal-buffer-p buf)))
  ;;              )))
  ;;       )

  ;; Workspace-aware buffer cycling (requires workspaces module)
  ;; revert to nil to use global buffer list if workspaces cause issues
  ;; (setf iflipb-buffer-list-function #'+workspace-buffer-list)
  (defun my/workspace-buffer-list-live ()
    "Workspace buffers in MRU order (buffer-list is MRU, filter to workspace)."
    (let ((ws-bufs (+workspace-buffer-list)))
      (seq-filter (lambda (buf)
                    (and (buffer-live-p buf)
                         (memq buf ws-bufs)))
                  (buffer-list))))
  (setf iflipb-buffer-list-function #'my/workspace-buffer-list-live)

  (setf iflipb-wrap-around t)

  ;; Replace default regex "^[*]" with Doom's unreal-buffer test so that
  ;; help/compilation/process/popup buffers stay out of cycling even if
  ;; they're members of the current workspace.
  (defun my/iflipb-ignore-buffer-p (name)
    (let ((buf (get-buffer name)))
      (and buf (doom-unreal-buffer-p buf))))
  (setf iflipb-ignore-buffers #'my/iflipb-ignore-buffer-p)

  (map! "M-]" 'iflipb-next-buffer
        "M-[" 'iflipb-previous-buffer)
  )

(load! "lisp/phony-projects")

;; Telega root buffer without *...* so iflipb and buffer lists treat it as real.
(after! telega
  (setq telega-root-buffer-name "Telega"))

;; Shell-command wrappers: open a fresh vterm and run CMD in it.
(defun my/vterm-run (cmd)
  "Open a new vterm buffer and run CMD."
  (+vterm/here nil)
  (vterm-send-string cmd)
  (vterm-send-return))

(defun my/term-claude ()
  "Open a terminal running Claude Code."
  (interactive)
  (my/vterm-run "claude --dangerously-skip-permissions"))

(defun my/term-btop ()
  "Open a terminal running btop."
  (interactive)
  (my/vterm-run "btop"))

;; Project switch action: completing-read between common entry points.
(defun my/project-switch-action (&optional project-root)
  (pcase (completing-read
          "Open: "
          '("find-file" "vterm" "claude" "btop" "magit" "dired") nil t)
    ("find-file" (doom-project-find-file project-root))
    ("vterm"     (let ((default-directory (or project-root default-directory)))
                   (+vterm/here nil)))
    ("claude"    (let ((default-directory (or project-root default-directory)))
                   (my/term-claude)))
    ("btop"      (let ((default-directory (or project-root default-directory)))
                   (my/term-btop)))
    ("magit"     (magit-status-setup-buffer project-root))
    ("dired"     (dired project-root))))

(after! projectile
  (projectile-cleanup-known-projects)
  (setq +workspaces-switch-project-function #'my/project-switch-action))

;; FUTURE: consider migrating off persp-mode to `tab-bar-mode' + `bufferlo'.
;; persp-mode keeps membership in two parallel data structures (`persp-buffers'
;; slot on each persp AND `persp--buffer-in-persps' set on each buffer) with
;; independent write guards — every customization has to patch both sides or
;; they drift. tab-bar-mode is a single-source-of-truth window-config store;
;; bufferlo adds per-frame/tab buffer isolation in one clean data structure.
;; Minimal recipe:
;;   (setq tab-bar-show nil tab-bar-new-tab-choice 'clone)
;;   (tab-bar-mode 1)
;;   (use-package! bufferlo :config (bufferlo-mode 1))
;; Cost: rewrite +workspaces-switch-project-function, buffer-name advices,
;; iflipb filter, and disable Doom's :ui workspaces module.

(after! persp-mode
  ;; Prevent unreal buffers (popups, magit internals, etc.) from leaking into workspaces
  (add-hook 'persp-add-buffer-on-after-change-major-mode-filter-functions
            #'doom-unreal-buffer-p)

  ;; Always create a new workspace when switching projects.
  ;; Default 'non-empty renames main → project when main has no buffers.
  (setq +workspaces-on-switch-project-behavior t)

  ;; Pin vterm/magit buffers to the workspace they were first added to.
  ;; File-visiting and other buffers are exempt.
  ;;
  ;; Two layers are needed because persp-mode leaks in two ways:
  ;;
  ;; (A) Membership: `persp-add-buffer' pushes to two independent data
  ;;     structures (`persp-buffers' slot + `persp--buffer-in-persps' set).
  ;;     Advice at the entry blocks both.
  ;;
  ;; (B) Display: per-persp window-configurations (saved on switch) and
  ;;     winner-ring history may reference foreign buffers from older buggy
  ;;     state. Restoring those configs shows the foreign buffer in a window
  ;;     without adding it to the perspective. A post-switch sweep replaces
  ;;     such windows with a fallback buffer.
  (defun my/persp-pinned-mode-p (buf)
    "Non-nil if BUF is a vterm/magit buffer that should be workspace-pinned."
    (and (buffer-live-p buf)
         (with-current-buffer buf
           (derived-mode-p 'vterm-mode 'magit-mode))))

  (defun my/persp-pin-p (buf persp)
    "Non-nil if BUF should be blocked from being added to PERSP."
    (and (my/persp-pinned-mode-p buf)
         (let ((dominated (persp--buffer-in-persps buf)))
           (and dominated (not (memq persp dominated))))))

  ;; Layer A: block cross-workspace membership additions.
  (defadvice! my/persp-add-buffer-pin-a (fn &rest args)
    :around #'persp-add-buffer
    (let* ((bon (car args))
           (persp (or (nth 1 args) (get-current-persp)))
           (bufs (if (listp bon) bon (list bon)))
           (filtered (cl-remove-if
                      (lambda (b)
                        (let ((buf (persp-get-buffer-or-null b)))
                          (and buf (my/persp-pin-p buf persp))))
                      bufs)))
      (when filtered
        (apply fn filtered (cdr args)))))

  ;; Layer B: after switching to a workspace, replace any window displaying
  ;; a pinned buffer that does not belong to this perspective.
  (defun my/persp-sweep-foreign-windows (&rest _)
    (let ((persp (get-current-persp)))
      (when persp
        (dolist (win (window-list nil 'no-mini))
          (let ((buf (window-buffer win)))
            (when (and (my/persp-pinned-mode-p buf)
                       (not (memq persp (persp--buffer-in-persps buf))))
              (switch-to-prev-buffer win 'bury)))))))
  (add-hook 'persp-activated-functions #'my/persp-sweep-foreign-windows))


(use-package! drag-stuff
  :config
  (drag-stuff-global-mode 1)

  ;; good for evil + qwerty, but not colemack
  ;; (map! :v "J" 'drag-stuff-down :v "K" 'drag-stuff-up)

  (map! :nvi "s-<up>" #'drag-stuff-up
        :nvi "s-<down>" #'drag-stuff-down))



(defun my/+popup/toggle-focus ()
  "Toggle any visible popups.

If no popups are available, display the *Messages* buffer in a popup window.
Also moves cursor to the popup window when opened.
Modification of +popup/toggle"
  (interactive)
  (let ((+popup--inhibit-transient t))
    (cond ((+popup-windows) (+popup/close-all t))
          ((ignore-errors
             (prog1 (+popup/restore)
               (when-let ((popup-windows (+popup-windows)))
                 (select-window (car popup-windows))))))
          ((progn
             (display-buffer (get-buffer "*Messages*"))
             (when-let ((win (get-buffer-window "*Messages*")))
               (select-window win)))))))
(map! "C-`" #'my/+popup/toggle-focus)



(map!
 :n "C-w D" #'kill-buffer-and-window
 :n "C-w C" #'kill-buffer-and-window)




;; Input method focus tracking (disabled — uncomment the add-function to enable)
;; (defvar my/im-focus (shell-command-to-string "im-select"))
;; (defun my/save-keyboard-layout-on-focus ()
;;   (let ((tmp my/im-focus)
;;         (inhibit-message t))
;;     (setq! my/im-focus (shell-command-to-string "im-select"))
;;     (if (not (equal tmp my/im-focus))
;;         (shell-command (concat "im-select " tmp)))))
;; (add-function :after after-focus-change-function
;;               #'my/save-keyboard-layout-on-focus)




(use-package! dape
  :config
  (setq! dape-request-timeout 300)
  (setf (alist-get 'dlv-test dape-configs)
        '(modes (go-mode go-ts-mode)
          ensure dape-ensure-command
          command "dlv"
          command-args ("dap" "--listen" "127.0.0.1::autoport")
          command-cwd (or (and (buffer-file-name) (file-name-directory (buffer-file-name))) default-directory)
          command-insert-stderr t
          port :autoport
          :request "launch"
          :mode "test"
          :type "go"
          :program "."
          :args ["-test.v" (format "-test.run=%s" (which-function))
                 ]))

  (setf (alist-get 'dlv-attach-wait dape-configs)
        '(modes (go-mode go-ts-mode)
          ensure dape-ensure-command
          command "dlv"
          command-args ("dap" "--listen" "127.0.0.1::autoport")
          command-insert-stderr t
          port :autoport
          :request "attach"
          :mode "local"
          :type "go"
          :waitFor "process")
        )
  (setf (alist-get 'dlv-attach-pid dape-configs)
        '(modes (go-mode go-ts-mode)
          ensure dape-ensure-command
          command "dlv"
          command-args ("dap" "--listen" "127.0.0.1::autoport")
          command-insert-stderr t
          port :autoport
          :request "attach"
          :mode "local"
          :type "go"
          :pid "")
        )

  ;; Emacs configuration to connect to external dlv
  (setf (alist-get 'dlv-connect-remote dape-configs)
        '(modes (go-mode go-ts-mode)
          host "127.0.0.1"
          port 62345
          :request "attach"
          :type "go"
          :mode "remote"))

  )



(defun my/go-test-coverage-auto ()
  "Run go tests with coverage, display results, and clean up profile file."
  (interactive)
  (let* ((coverage-file (concat (file-name-base (buffer-file-name)) "-coverage.out"))
         (result (shell-command (format "go test -coverprofile=%s" coverage-file)))
         (gocov-buffer (concat (file-name-nondirectory (buffer-file-name)) "<gocov>"))
         )

    (if (= result 0)
        (progn (go-coverage coverage-file) ;; Display coverage in Emacs
               (when (get-buffer gocov-buffer) ;; Switch to coverage buffer
                 (if-let ((window (get-buffer-window gocov-buffer)))
                     (select-window window)
                   (switch-to-buffer-other-window gocov-buffer)))
               (when (file-exists-p coverage-file) ;; Delete the coverage profile file
                 (delete-file coverage-file))
               (message "Coverage analysis complete and profile cleaned up"))
      (message (format "go test exited with code %d" result)))))
(map! :after go-mode
      :map go-mode-map
      :localleader
      (:prefix ("t" . "test")
       :desc "Test with coverage" "c" #'my/go-test-coverage-auto))

;; Harper language server configuration for the famous text modes
(with-eval-after-load 'eglot

  ;; Git and version control
  (add-to-list 'eglot-server-programs '(git-commit-mode . ("harper-ls" "--stdio")) t)
  (add-to-list 'eglot-server-programs '(forge-post-mode . ("harper-ls" "--stdio")) t)
  (add-to-list 'eglot-server-programs '(magit-edit-mode . ("harper-ls" "--stdio")) t)

  ;; Core text modes
  (add-to-list 'eglot-server-programs '(markdown-mode . ("harper-ls" "--stdio")) t)
  (add-to-list 'eglot-server-programs '(markdown-ts-mode . ("harper-ls" "--stdio")) t)
  (add-to-list 'eglot-server-programs '(org-mode . ("harper-ls" "--stdio")) t)

  ;; Documentation modes
  (add-to-list 'eglot-server-programs '(rst-mode . ("harper-ls" "--stdio")) t)
  (add-to-list 'eglot-server-programs '(plantuml-mode . ("harper-ls" "--stdio")) t)
  (add-to-list 'eglot-server-programs '(texinfo-mode . ("harper-ls" "--stdio")) t)
  (add-to-list 'eglot-server-programs '(adoc-mode . ("harper-ls" "--stdio")) t)

  (add-to-list 'eglot-server-programs '(text-mode . ("harper-ls" "--stdio")) t)
  (add-to-list 'eglot-server-programs '(fundamental-mode . ("harper-ls" "--stdio")) t)

  ;; Auto-start harper in text-derived modes (covers org, markdown, git-commit, etc.)
  (add-hook 'text-mode-hook #'eglot-ensure)
  ;; forge-post-mode derives from markdown-mode, not text-mode in some versions
  (add-hook 'forge-post-mode-hook #'eglot-ensure)
  )


(use-package! eglot
  :config
  (setq-default eglot-workspace-configuration
                '(:gopls (:staticcheck t
                          :semanticTokens t
                          :analyses (:unusedparams t
                                     :unusedwrite t))
                  :harper-ls (:linters (:SpellCheck :json-false
                                        :SentenceCapitalization :json-false))))

  (setq! eglot-sync-connect nil
         eglot-extend-to-xref t
         eglot-autoshutdown t)

  ;; When semantic tokens are available, disable the overlapping tree-sitter
  ;; features so the two systems don't fight over the same faces.
  ;; Tree-sitter keeps: comment, string, keyword, bracket, delimiter, punctuation, operator
  ;; Semantic tokens own: variable, function, type, definition, constant, property, number
  (add-hook 'eglot-managed-mode-hook
            (defun my/treesit-semtok-handoff ()
              (when (and (fboundp 'treesit-parser-list) (treesit-parser-list))
                (if (and (bound-and-true-p eglot--managed-mode)
                         (ignore-errors (eglot-server-capable :semanticTokensProvider)))
                    (treesit-font-lock-recompute-features
                     nil '(definition variable function property type constant number))
                  (treesit-font-lock-recompute-features
                   '(definition variable function property type constant number) nil)))))

  ;; Remove hover from eldoc — it shows stale colored type info that
  ;; obscures the useful signature help (white text showing current argument).
  ;; Hover docs are still available on demand via K (+lookup/documentation).
  (add-hook 'eglot-managed-mode-hook
            (defun my/eglot-eldoc-cleanup ()
              (setq-local eldoc-documentation-functions
                          (remove #'eglot-hover-eldoc-function
                                  eldoc-documentation-functions))))

  ;; Clean up hover docs (K): strip invisible markdown markup so yy copies
  ;; clean text, thin out separators, and wrap prose to fill-column.
  (defadvice! my/eglot-clean-markup-a (result)
    :filter-return #'eglot--format-markup
    (when (and result (stringp result))
      (with-temp-buffer
        (insert result)
        (let ((inhibit-read-only t))
          ;; Delete invisible text (code fence markers, bold/link syntax, etc.)
          (goto-char (point-min))
          (while (< (point) (point-max))
            (if (get-text-property (point) 'invisible)
                (delete-region (point)
                               (or (next-single-property-change (point) 'invisible)
                                   (point-max)))
              (goto-char (or (next-single-property-change (point) 'invisible)
                             (point-max)))))
          ;; Strip leftover horizontal rules
          (goto-char (point-min))
          (while (re-search-forward "^-\\{3,\\}$" nil t)
            (replace-match ""))
          ;; Collapse 3+ blank lines to one
          (goto-char (point-min))
          (while (re-search-forward "\n\\{3,\\}" nil t)
            (replace-match "\n\n"))
          ;; Wrap prose to fill-column
          (fill-region (point-min) (point-max)))
        (string-trim (buffer-string))))))


(defun my/inspect-semtok ()
  "Show semantic token type and modifiers at point with applied faces."
  (interactive)
  (let* ((pos (point))
         (symbol (thing-at-point 'symbol t))
         (semtok-info (get-text-property pos 'eglot-semantic-token)))

    (if (not semtok-info)
        (message "No semantic token at point")
      (let* ((type-idx (car semtok-info))
             (modifier-bits (cdr semtok-info))
             (semtok-cap (eglot-server-capable :semanticTokensProvider))
             (legend (plist-get semtok-cap :legend))
             (token-types (plist-get legend :tokenTypes))
             (token-modifiers (plist-get legend :tokenModifiers)))

        (if (or (null token-types) (null token-modifiers)) (message "Error: Legend structure - types: %S, mods: %S" token-types token-modifiers)
          (let* ((token-type (when (vectorp token-types) (aref token-types type-idx)))
                 (modifiers (cl-loop for i from 0 below (length token-modifiers)
                                     when (> (logand modifier-bits (ash 1 i)) 0)
                                     collect (aref token-modifiers i)))
                 ;; Look up faces
                 (type-face (and (boundp 'eglot-semantic-tokens-faces)
                                 (cdr (assoc token-type eglot-semantic-tokens-faces))))
                 (modifier-faces (mapcar
                                  (lambda (mod) (and (boundp 'eglot-semantic-tokens-modifier-faces)
                                                     (cdr (assoc mod eglot-semantic-tokens-modifier-faces))))
                                  modifiers)))

            ;; Format type with face
            (let ((type-str (if type-face (format "%s [%s]" token-type type-face)
                              (format "%s" token-type)))
                  ;; Format modifiers with faces
                  (mods-str (if modifiers (format "(%s)"
                                                  (mapconcat (lambda (i)
                                                               (let ((mod (nth i modifiers))
                                                                     (face (nth i modifier-faces)))
                                                                 (if face (format "%s [%s]" mod face)
                                                                   mod)))
                                                             (number-sequence 0 (1- (length modifiers)))
                                                             " "))
                              "()")))
              (message "Symbol: %s | Type: %s | Modifiers: %s" symbol type-str mods-str))))))))

(use-package! apheleia
  :config
  (setf (alist-get 'golines apheleia-formatters)
        '("golines"))

  (setf (alist-get 'go-mode apheleia-mode-alist)
        '(golines))

  (setf (alist-get 'go-ts-mode apheleia-mode-alist)
        '(golines))

  (setq-hook! 'go-mode-hook +format-with 'golines)
  (setq-hook! 'go-ts-mode-hook +format-with 'golines)
  )


(setq org-latex-create-formula-image-program 'imagemagick)


(defun my/round-csv-floats-to-2-decimals ()
  "Round all floating point numbers in CSV to 2 decimal places."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (forward-line 1) ; Skip header
    (while (not (eobp))
      (let ((line-start (point)))
        (end-of-line)
        (let ((line-end (point)))
          (goto-char line-start)
          (while (re-search-forward "\\([0-9]+\\.[0-9]\\{3,\\}\\)" line-end t)
            (let ((num (string-to-number (match-string 1))))
              (replace-match (format "%.2f" num) t t)))
          (forward-line 1))))))



(use-package! plantuml-mode
  :mode ("\\.puml\\'" . plantuml-mode)
  :config

  (setq! plantuml-indent-level 2)

  ;; Set PNG as default output format
  (setq! plantuml-default-exec-mode 'executable
         plantuml-output-type "png"
         plantuml-server-url "")
  
  )

(after! flycheck
  (setq! flycheck-checker-error-threshold 1000
         ;; Disable automatic error display — it fights with eldoc for the echo area.
         ;; Errors are still marked inline; use s-e to see the message on demand.
         flycheck-display-errors-function #'ignore)

  ;; Kill the floating popup that hides under split windows
  (after! flycheck-popup-tip
    (flycheck-popup-tip-mode -1))

  ;; s-e: show error at point on demand in echo area
  (defun my/flycheck-show-error-at-point ()
    "Show flycheck error at point in the echo area."
    (interactive)
    (let ((errors (flycheck-overlay-errors-at (point))))
      (if errors
          (message "%s"
                   (mapconcat
                    (lambda (err)
                      (format "[%s] %s"
                              (flycheck-error-level err)
                              (flycheck-error-message err)))
                    errors "\n"))
        (message "No errors at point"))))

  (map! :n "s-e" #'my/flycheck-show-error-at-point))

(use-package! treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  ;; (global-treesit-auto-mode)
  (setq! major-mode-remap-alist
         '((yaml-mode . yaml-ts-mode)
           (typescript-mode . typescript-ts-mode)
           (json-mode . json-ts-mode)
           (css-mode . css-ts-mode)
           (python-mode . python-ts-mode)
           (go-mode . go-ts-mode)
           (javascript-mode . javascript-ts-mode)
           ))
  )

(after! smartparens
  (setq! sp-autoskip-closing-pair nil)
  (dolist (brace '("(" "{" "["))        ;; {|} <RET> not expands without Shift
    (sp-pair brace nil
             :post-handlers '(("||\\n[i]" "S-RET") ("| " "SPC"))))
  )

(use-package! ellama
  :config
  (require 'llm-ollama)
  (require 'llm-openai)
  (setq ellama-provider
        (make-llm-ollama
         :host "192.168.31.185"
         :port 11434
         :chat-model "deepseek-coder"
         :embedding-model "deepseek-coder")))

(after! dirvish
  (setq! dirvish-use-header-line nil
         dirvish-use-mode-line nil))


(after! image-mode
  (setq! image-auto-resize 'fit-window))

(after! org
  (global-org-modern-mode -1)
  (remove-hook 'org-mode-hook #'org-modern-mode))

(map! :leader
      :desc "Make"       "o m" #'+make/run
      :desc "Make last"  "o M" #'+make/run-last
      :desc "Claude"     "o c" #'my/term-claude
      :desc "btop"       "o B" #'my/term-btop)

(after! corfu
  (setq corfu-cycle t
        corfu-preselect 'directory
        corfu-auto t
        corfu-auto-delay 0.1
        corfu-auto-prefix 1)

  (map! :map corfu-map
        ;; TAB: complete common prefix (still useful for partial completion)
        :i "TAB"   #'corfu-complete
        :i [tab]   #'corfu-complete
        ;; C-M-y: accept the selected candidate fully and insert it
        :i "C-M-y" #'corfu-insert
        ;; C-M-g: dismiss the completion popup
        :i "C-M-g" #'corfu-quit))

;; Vertico: C-M-y accepts candidate text without exiting the minibuffer.
;; For directory paths this means "enter this directory and keep completing".
(after! vertico
  (map! :map vertico-map
        "C-M-y" #'vertico-insert
        "C-M-g" #'minibuffer-keyboard-quit))

;; Smart TAB: yasnippet field navigation takes priority over corfu
(after! (:and yasnippet corfu)
  (defadvice! my/yas-before-corfu-a (&rest _)
    :before-while #'corfu-insert
    (not (yas-active-snippets)))
  (map! :map yas-keymap
        [tab]  #'yas-next-field-or-maybe-expand
        "TAB"  #'yas-next-field-or-maybe-expand))



(defun my/treesit-expand-region ()
  "Expand selection to parent node"
  (interactive)
  (when (region-active-p)
    (let* ((node (treesit-node-on (region-beginning) (region-end)))
           (parent (treesit-node-parent node)))
      (when parent
        (goto-char (treesit-node-start parent))
        (set-mark (treesit-node-end parent))
        (activate-mark)))))

(defun my/treesit-contract-region ()
  "Contract selection to smallest child containing point"
  (interactive)
  (when (region-active-p)
    (let* ((node (treesit-node-on (region-beginning) (region-end)))
           (target-pos (point))
           (smallest-child nil))
      ;; Find smallest child that contains cursor
      (dolist (child (treesit-node-children node t)) ; t = named nodes only
        (when (and (>= target-pos (treesit-node-start child))
                   (<= target-pos (treesit-node-end child)))
          (setq smallest-child child)))
      ;; If no child contains cursor, try first child
      (unless smallest-child
        (setq smallest-child (treesit-node-child node 0 t)))
      (when smallest-child
        (goto-char (treesit-node-start smallest-child))
        (set-mark (treesit-node-end smallest-child))
        (activate-mark)))))

;; Bind in visual mode
(map! :v "C-a" #'my/treesit-expand-region
      :v "C-i" #'my/treesit-contract-region)

(use-package! evil-textobj-tree-sitter
  :after evil
  :config
  ;; For individual expressions/arguments in return statements
  (define-key evil-outer-text-objects-map "e"
              (evil-textobj-tree-sitter-get-textobj "expr_list"
                '((go-ts-mode . ([(expression_list)] @expr_list))
                  )))

  (define-key evil-inner-text-objects-map "e"
              (evil-textobj-tree-sitter-get-textobj "expr"
                '((go-ts-mode . ([(unary_expression) 
                                  (composite_literal)
                                  (call_expression) 
                                  (identifier)
                                  (nil)] @expr)))))

  ;; Outer: entire call including function name and parens
  (define-key evil-outer-text-objects-map "c"
              (evil-textobj-tree-sitter-get-textobj "call"
                '((go-ts-mode . ([(call_expression) @call])))))
  
  ;; Inner: just the arguments (without parens)
  (define-key evil-inner-text-objects-map "c"
              (evil-textobj-tree-sitter-get-textobj "call.inner"
                '((go-ts-mode . ((argument_list
                                  (_) @call.inner))))))
  )

(defalias 'my/unwrap
  (kmacro "d i ( d a c P C-p"))

(map! :leader "l u" 'my/unwrap)


(setq-default compilation-max-output-line-length nil)

(use-package! magit
  :config
  (setq! magit-status-margin '(t age-abbreviated magit-log-margin-width t 20)
         magit-uniquify-buffer-names t)

  ;; Give magit buffers workspace-unique names so each workspace gets its own
  (defadvice! my/magit-workspace-buffer-name-a (fn mode &optional value)
    :around #'magit-generate-buffer-name-default-function
    (let ((name (funcall fn mode value)))
      (if (and (bound-and-true-p persp-mode)
               (modulep! :ui workspaces))
          (format "%s<%s>" name (+workspace-current-name))
        name))))



(setq! treesit-max-buffer-size 100000000)

(use-package! telega
  :commands telega
  :config
  (setq telega-server-libs-prefix (expand-file-name "~/opt/thirdparty/installation/tdlib"))
  ;; disabled since there is no proxies any more, vpn over tun used
  ;; (setq telega-proxies
  ;;       '((:server "127.0.0.1" :port 10808 :enable t
  ;;          :type (:@type "proxyTypeHttp"))))

  (setq telega-chat-show-reactions t)
  (setq telega-chat-button-width '(0.25 15 30))
  (global-telega-squash-message-mode 1)

  ;; telega--addProxy ignores :enable from the plist (passes nil to enable-p),
  ;; so proxies get added but disabled. Fix: pass :enable explicitly.
  (defadvice! my/telega-addProxy-respect-enable-a (fn tl-proxy &optional enable-p callback)
    :around #'telega--addProxy
    (funcall fn tl-proxy (or enable-p (plist-get tl-proxy :enable)) callback)))
