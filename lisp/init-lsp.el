;;; init-lsp.el --- On-demand language servers and completion -*- lexical-binding: t; -*-

(defconst rc/eglot-local-servers
  '(("clangd" c-mode c++-mode c-ts-mode c++-ts-mode)
    ("zls" zig-mode zig-ts-mode)
    ("typescript-language-server" js-mode js-ts-mode typescript-mode
     typescript-ts-mode tsx-ts-mode)
    ("lua-language-server" lua-mode lua-ts-mode)
    ("bash-language-server" sh-mode bash-ts-mode))
  "Installed servers to start automatically for local files.")

(defun rc/eglot-ensure-local ()
  "Start Eglot for a supported local file if its server is in `exec-path'."
  (when (and buffer-file-name
             (not (file-remote-p buffer-file-name))
             (or (not (eq major-mode 'sh-mode))
                 (memq (bound-and-true-p sh-shell) '(sh bash dash ash))))
    ;; The TSX derivative already runs `typescript-mode-hook'.
    (let* ((mode (if (eq major-mode 'rc/typescript-tsx-mode)
                     'typescript-mode
                   major-mode))
           (entry (seq-find (lambda (entry) (memq mode (cdr entry)))
                            rc/eglot-local-servers)))
      (when (and entry (executable-find (car entry)))
        (eglot-ensure)))))

(use-package eglot
  :ensure nil
  :commands eglot-ensure
  :init
  (dolist (entry rc/eglot-local-servers)
    (dolist (mode (cdr entry))
      (add-hook (intern (format "%s-hook" mode)) #'rc/eglot-ensure-local)))
  :config
  ;; Keep TS, TSX and JS buffers in the same server session.
  (add-to-list 'eglot-server-programs
               '(((rc/typescript-tsx-mode :language-id "typescriptreact")
                  (tsx-ts-mode :language-id "typescriptreact")
                  (typescript-mode :language-id "typescript")
                  (typescript-ts-mode :language-id "typescript")
                  (js-mode :language-id "javascript")
                  (js-ts-mode :language-id "javascript"))
                 . ("typescript-language-server" "--stdio"))))

(defun rc/corfu-for-eglot ()
  "Enable automatic completion while Eglot manages the buffer."
  (if (eglot-managed-p)
      (progn
        (setq-local corfu-auto t)
        (corfu-mode 1))
    (when (bound-and-true-p corfu-mode)
      (corfu-mode -1))))

(use-package corfu
  :commands corfu-mode
  :hook (eglot-managed-mode . rc/corfu-for-eglot)
  :custom
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-auto-trigger "."))

(provide 'init-lsp)
;;; init-lsp.el ends here
