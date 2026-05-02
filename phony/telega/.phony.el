(:name :dirname
 :init
   ;; Install routing hooks first so the root buffer created by (telega) is caught too.
   (defun my/phony-telega-route-buffer-h ()
     (when-let (ws (+workspace-get phony-name t))
       (persp-add-buffer (current-buffer) ws nil nil)))
   (dolist (hook '(telega-root-mode-hook telega-chat-mode-hook))
     (add-hook hook #'my/phony-telega-route-buffer-h))
   (telega)
 :deinit
   (dolist (hook '(telega-root-mode-hook telega-chat-mode-hook))
     (remove-hook hook #'my/phony-telega-route-buffer-h))
   (telega-kill))
