(:name :dirname
 :init
   (defvar my/phony-btop-buffer nil
     "Ghostel buffer spawned by the btop phony project; killed on :deinit.")
   (my/term-btop)
   (setq my/phony-btop-buffer (current-buffer))
 :deinit
   (when (buffer-live-p my/phony-btop-buffer)
     (let ((kill-buffer-query-functions nil))
       (kill-buffer my/phony-btop-buffer)))
   (setq my/phony-btop-buffer nil))
