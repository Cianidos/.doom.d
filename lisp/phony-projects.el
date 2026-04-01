;;; lisp/phony-projects.el -*- lexical-binding: t; -*-
;;; Virtual/phony Projectile projects with init+deinit hooks.
;;
;; Each phony project is a directory containing a .phony.el file:
;;
;;   (:name "My Workspace"   ; optional — string or :dirname (default)
;;    :init
;;      (some-mode)
;;      (other-setup)
;;    :deinit
;;      (some-mode-kill))
;;
;; :name     — workspace name. String = literal. :dirname or absent = directory name.
;; :init     — zero or more forms run as progn after the workspace is created.
;;             `phony-name' is bound to the resolved workspace name.
;; :deinit   — same, run before the workspace is killed (SPC TAB d).
;;
;; `my/phony-dir' is scanned at startup; projects outside it are loaded lazily
;; when projectile first switches to them.

;;; Config

(defvar my/phony-dir (expand-file-name "phony/" doom-user-dir)
  "Base directory scanned by `my/phony-discover' for virtual projects.
Defaults to ~/.doom.d/phony/. Projects outside this dir work too — they
are loaded lazily when projectile first switches to them.")

(defvar my/phony-projects (make-hash-table :test 'equal)
  "Runtime cache: file-truename root → (:name STR :init FN :deinit FN).
Populated lazily by `my/phony--load' on first project switch.")

;;; Parsing

(defconst my/phony--body-keys '(:init :deinit)
  "Keys whose values in .phony.el are multi-form progn bodies.")

(defun my/phony--parse (forms)
  "Parse the top-level list read from a .phony.el file.
FORMS is a flat plist where :init/:deinit consume all following
forms until the next keyword (implicit progn), while other keys
like :name consume a single value.
Returns a plist: (:name SPEC :init FORM-LIST :deinit FORM-LIST)."
  (let (result current-key body single-next)
    (dolist (item forms)
      (cond
        ;; Single-value key: grab next item regardless of its type (keywords allowed as values).
        (single-next
         (setq result      (plist-put result current-key item)
               single-next nil))
        ((keywordp item)
         (when (and current-key (memq current-key my/phony--body-keys))
           (setq result (plist-put result current-key (nreverse body))))
         (setq current-key  item
               body         nil
               single-next  (not (memq item my/phony--body-keys))))
        (t
         (push item body))))
    ;; flush trailing body key
    (when (and current-key (memq current-key my/phony--body-keys))
      (setq result (plist-put result current-key (nreverse body))))
    result))

(defun my/phony--make-fn (forms)
  "Compile FORMS into (lambda (phony-name) FORMS...) with lexical binding.
`phony-name' is available inside forms as the resolved workspace name."
  (when forms
    (eval `(lambda (phony-name) ,@forms) t)))

(defun my/phony--resolve-name (root name-spec)
  "Resolve workspace name for project at ROOT from NAME-SPEC.
String → used as-is.  nil, :dirname, or anything else → directory name."
  (if (stringp name-spec)
      name-spec
    (file-name-nondirectory (directory-file-name root))))

;;; Loading

(defun my/phony--load (root)
  "Read and cache .phony.el from ROOT.  Returns the cache entry or nil."
  (let ((file (expand-file-name ".phony.el" root)))
    (when (file-exists-p file)
      (condition-case err
          (let* ((forms  (with-temp-buffer
                           (insert-file-contents file)
                           (read (current-buffer))))
                 (parsed (my/phony--parse forms))
                 (name   (my/phony--resolve-name root (plist-get parsed :name)))
                 (entry  (list :name   name
                               :init   (my/phony--make-fn (plist-get parsed :init))
                               :deinit (my/phony--make-fn (plist-get parsed :deinit)))))
            (puthash root entry my/phony-projects)
            entry)
        (error
         (message "phony-projects: failed to load %s: %s" file err)
         nil)))))

;;; Hooks

(defun my/phony--deinit-h (persp)
  "Run :deinit when the workspace for a phony project is killed (SPC TAB d)."
  (when-let* ((root  (persp-parameter '+workspace-project persp))
              (entry (gethash root my/phony-projects))
              (fn    (plist-get entry :deinit)))
    (funcall fn (plist-get entry :name))))

(defun my/phony--switch-project-a (orig &optional dir)
  "Around advice for `+workspaces-switch-to-project-h'.
For phony projects: suppress the file-find prompt and run :init after the
workspace is set up.  Init runs here rather than in projectile-after-switch-
project-hook because that hook fires outside the `default-directory' binding,
making projectile-project-root unreliable."
  (let* ((root    (file-truename (or dir default-directory)))
         (phony-p (or (gethash root my/phony-projects)
                      (file-exists-p (expand-file-name ".phony.el" root)))))
    (if (not phony-p)
        (funcall orig dir)
      (let ((+workspaces-switch-project-function #'ignore))
        (funcall orig dir))
      (when-let* ((entry (or (gethash root my/phony-projects)
                             (my/phony--load root)))
                  (fn    (plist-get entry :init)))
        (funcall fn (plist-get entry :name))))))

;;; Discovery

(defun my/phony-discover ()
  "Scan `my/phony-dir' and register subdirs containing .phony.el with projectile.
Safe to call interactively to pick up newly created phony projects."
  (interactive)
  (when (file-directory-p my/phony-dir)
    (let ((added 0))
      (dolist (entry (directory-files my/phony-dir t "^[^.]"))
        (when (and (file-directory-p entry)
                   (file-exists-p (expand-file-name ".phony.el" entry)))
          (let ((abbrev (abbreviate-file-name (file-truename entry))))
            (unless (member abbrev projectile-known-projects)
              (cl-pushnew abbrev projectile-known-projects :test #'string=)
              (cl-incf added)))))
      (when (> added 0)
        (projectile-save-known-projects)))))

;;; Wire up

(after! projectile
  (advice-add '+workspaces-switch-to-project-h :around #'my/phony--switch-project-a)
  (my/phony-discover))

(after! persp-mode
  (add-hook 'persp-before-kill-functions #'my/phony--deinit-h))
