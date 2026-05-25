(:name :dirname
 :init
   (defvar my/phony-opencode-buffer nil
     "Ghostel buffer spawned by the opencode phony project; killed on :deinit.")
   (my/term-opencode)
   (setq my/phony-opencode-buffer (current-buffer))
 :deinit
   (when (buffer-live-p my/phony-opencode-buffer)
     (let ((kill-buffer-query-functions nil))
       (kill-buffer my/phony-opencode-buffer)))
   (setq my/phony-opencode-buffer nil))
