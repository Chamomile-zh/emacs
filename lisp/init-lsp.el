;;; init-lsp.el --- On-demand language servers and completion -*- lexical-binding: t; -*-

;;;; Eglot：连接语言服务器

;; 为支持的本地源码按需连接 LSP，提供语义补全、跳转和诊断。
;; 打开文件时才检查服务器是否仍在 PATH，不在启动时运行服务器。
(defconst chamomile/eglot-local-servers
  '(("clangd" c-mode c++-mode c-ts-mode c++-ts-mode)
    ("rust-analyzer" rust-mode rust-ts-mode)
    ("zls" zig-mode zig-ts-mode)
    ("typescript-language-server" js-mode js-ts-mode typescript-mode
     typescript-ts-mode tsx-ts-mode)
    ("lua-language-server" lua-mode lua-ts-mode)
    ("bash-language-server" sh-mode bash-ts-mode))
  "Installed servers to start automatically for local files.")

(defun chamomile/eglot-ensure-local ()
  "Start Eglot for a supported local file if its server is in `exec-path'."
  (when (and buffer-file-name
             (not (file-remote-p buffer-file-name))
             (or (not (eq major-mode 'sh-mode))
                 (memq (bound-and-true-p sh-shell) '(sh bash dash ash))))
    ;; TSX 继承 typescript-mode-hook，无需再注册一次连接 hook。
    (let* ((mode (if (eq major-mode 'chamomile/typescript-tsx-mode)
                     'typescript-mode
                   major-mode))
           (entry (seq-find (lambda (entry) (memq mode (cdr entry)))
                            chamomile/eglot-local-servers)))
      (when (and entry (executable-find (car entry)))
        (eglot-ensure)))))

(use-package eglot
  :ensure nil
  :commands eglot-ensure
  :init
  (dolist (entry chamomile/eglot-local-servers)
    (dolist (mode (cdr entry))
      (add-hook (intern (format "%s-hook" mode)) #'chamomile/eglot-ensure-local)))
  :config
  ;; 同一项目的 TS、TSX 和 JS 共用一个服务器，但保留各自的语言 ID。
  (add-to-list 'eglot-server-programs
               '(((chamomile/typescript-tsx-mode :language-id "typescriptreact")
                  (tsx-ts-mode :language-id "typescriptreact")
                  (typescript-mode :language-id "typescript")
                  (typescript-ts-mode :language-id "typescript")
                  (js-mode :language-id "javascript")
                  (js-ts-mode :language-id "javascript"))
                 . ("typescript-language-server" "--stdio"))))

;;;; Flymake：显示诊断

;; Eglot 接管后会启用 Flymake；行尾显示最严重的诊断，不修改源码。
;; M-x flymake-show-buffer-diagnostics 查看完整列表；这里不提前加载 Flymake。
(setq flymake-show-diagnostics-at-end-of-line 'short)

;;;; Corfu：自动补全弹窗

;; 在 Eglot 管理的文件和 *scratch* 中自动弹窗，不需要手动触发。
;; 弹窗中用 M-n / M-p 或上下键选候选，RET 确认，C-g 关闭。
(defun chamomile/corfu-start-in-scratch ()
  "Enable automatic Elisp completion on the first edit in *scratch*."
  (remove-hook 'post-self-insert-hook #'chamomile/corfu-start-in-scratch t)
  (setq-local corfu-auto t)
  (corfu-mode 1))

(defun chamomile/prepare-scratch-completion ()
  "Defer loading Corfu until the user types in the Lisp scratch buffer."
  ;; *scratch* 自带 Elisp 补全来源；启动时创建缓冲区不等于开始编辑。
  (when (and (equal (buffer-name) "*scratch*") (not buffer-file-name))
    (add-hook 'post-self-insert-hook #'chamomile/corfu-start-in-scratch nil t)))

;; LSP 缓冲区在 Eglot 接管后才启用弹窗；停止接管时关闭。
(defun chamomile/corfu-for-eglot ()
  "Enable automatic completion while Eglot manages the buffer."
  (if (eglot-managed-p)
      (progn
        (setq-local corfu-auto t)
        (corfu-mode 1))
    (when (bound-and-true-p corfu-mode)
      (corfu-mode -1))))

(use-package corfu
  :commands corfu-mode
  :hook ((eglot-managed-mode . chamomile/corfu-for-eglot)
         (lisp-interaction-mode . chamomile/prepare-scratch-completion))
  :custom
  ;; 输入一个字符后立即请求候选，不额外等待；点号仍是成员补全触发键。
  (corfu-auto-delay 0.0)
  (corfu-auto-prefix 1)
  (corfu-auto-trigger "."))

(provide 'init-lsp)
;;; init-lsp.el ends here
