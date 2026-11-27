;;; init-editor.el --- Editing defaults and text commands -*- lexical-binding: t; -*-

(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil
      ring-bell-function 'ignore
      use-short-answers t
      select-enable-clipboard t
      select-enable-primary t)

;; 退出时用 Emacs 底部的文字提示代替系统弹窗，仍然确认未保存的修改。
(defun chamomile/exit-with-text-prompts (exit &rest args)
  "Run EXIT with ARGS, using text prompts instead of GUI dialogs."
  (let ((use-dialog-box nil)
        (use-dialog-box-override nil))
    (apply exit args)))

(advice-add 'save-buffers-kill-emacs :around #'chamomile/exit-with-text-prompts)

(setq-default indent-tabs-mode nil
              tab-width 4
              show-trailing-whitespace t)

(electric-pair-mode 1)
(delete-selection-mode 1)

;; 按嵌套深度给括号上色，首次进入编程缓冲区时才加载。
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; 在命令行传入文件或首次打开 Dired 时，也要能恢复光标、监测外部改动。
(global-auto-revert-mode 1)
(save-place-mode 1)

;; 不再绑定旧的文本补全键；代码候选由 init-lsp.el 中的 Corfu 自动弹出。
(keymap-global-unset "M-/")

(use-package multiple-cursors
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)
         ("C-c C-s" . mc/skip-to-next-like-this)
         ("C-c C-d" . mc/unmark-next-like-this)))

(defun chamomile/duplicate-line ()
  "Duplicate the current line and keep point at the same position on it."
  (interactive)
  (let ((offset (- (point) (line-beginning-position)))
        (line (buffer-substring (line-beginning-position) (line-end-position))))
    (end-of-line)
    (insert "\n" line)
    (forward-char (- offset (length line)))))

(keymap-global-set "C-," #'chamomile/duplicate-line)
(keymap-global-set "C-c w" #'delete-trailing-whitespace)

(defun chamomile/hide-trailing-whitespace ()
  "Hide trailing whitespace in the current non-editing buffer."
  (setq-local show-trailing-whitespace nil))

(dolist (hook '(term-mode-hook vterm-mode-hook compilation-mode-hook
                dired-mode-hook minibuffer-setup-hook))
  (add-hook hook #'chamomile/hide-trailing-whitespace))

(defun chamomile/auto-clean-whitespace-on-save ()
  "Delete trailing whitespace when saving the current buffer."
  (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

(dolist (hook '(c-mode-hook c++-mode-hook c-ts-mode-hook c++-ts-mode-hook
                rust-mode-hook zig-mode-hook))
  (add-hook hook #'chamomile/auto-clean-whitespace-on-save))

;; 键位只在 Emacs Lisp 缓冲区生效，不提前加载额外库。
(with-eval-after-load 'elisp-mode
  (keymap-set emacs-lisp-mode-map "C-c C-j" #'eval-print-last-sexp))

(provide 'init-editor)
;;; init-editor.el ends here
