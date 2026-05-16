(:name :dirname
 :init
   (defvar my/phony-codex-buffer nil
     "Ghostel buffer spawned by the Codex phony project; killed on :deinit.")
   (my/term-codex)
   (setq my/phony-codex-buffer (current-buffer))
 :deinit
   (when (buffer-live-p my/phony-codex-buffer)
     (let ((kill-buffer-query-functions nil))
       (kill-buffer my/phony-codex-buffer)))
   (setq my/phony-codex-buffer nil))
