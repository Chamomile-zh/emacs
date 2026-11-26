;;; init-tools.el --- Tsoding workflow tools & custom functions -*- lexical-binding: t; -*-

;; 1. 手动触发文本补全（M-/）
(setq hippie-expand-try-functions-list
      '(try-expand-dabbrev
        try-expand-dabbrev-all-buffers
        try-expand-dabbrev-from-kill
        try-complete-file-name-partially
        try-complete-file-name
        try-expand-all-abbrevs
        try-expand-line))
(global-set-key (kbd "M-/") 'hippie-expand)

;; 2. 多光标批量编辑
(use-package multiple-cursors
  :config
  (global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
  (global-set-key (kbd "C->")         'mc/mark-next-like-this)
  (global-set-key (kbd "C-<")         'mc/mark-previous-like-this)
  (global-set-key (kbd "C-c C-<")     'mc/mark-all-like-this)
  (global-set-key (kbd "C-c C-s")     'mc/skip-to-next-like-this)
  (global-set-key (kbd "C-c C-d")     'mc/unmark-next-like-this))

;; 3. Git 集成
(use-package magit
  :bind ("C-x g" . magit-status))

;; 4. Rust 与 Zig 轻量主模式支持
(use-package rust-mode
  :mode "\\.rs\\'")

(use-package zig-mode
  :mode "\\.zig\\'"
  :config
  (setq zig-format-on-save nil))

;; 5. 一键编译与 ANSI 色彩渲染
(setq compilation-scroll-output 'first-error)
(global-set-key (kbd "<f5>") 'compile)
(global-set-key (kbd "<f6>") 'recompile)

(use-package ansi-color
  :ensure nil
  :hook (compilation-filter . ansi-color-compilation-filter))

;; 6. 分屏窗口快速切换（Shift + 方向键直接移动焦点）
(windmove-default-keybindings)

;; 7. 误关分屏撤销与恢复（C-c <left> 撤销布局，C-c <right> 重做布局）
(use-package winner
  :ensure nil
  :config
  (winner-mode 1))

;; 8. Dired 双栏极简文件管理
(use-package dired
  :ensure nil
  :init
  (setq dired-dwim-target t
        dired-listing-switches "-alh --group-directories-first"
        dired-recursive-copies 'always
        dired-recursive-deletes 'top)
  :hook
  (dired-mode . dired-hide-details-mode)
  :bind (:map dired-mode-map
              ("C-c C-e" . wdired-change-to-wdired-mode)))

;; 9. Tsoding 自写复制当前行函数（保留列光标位置）
(defun rc/duplicate-line ()
  "Duplicate current line and keep column position."
  (interactive)
  (let ((column (- (point) (line-beginning-position)))
        (line (let ((s (thing-at-point 'line t)))
                (if s (string-remove-suffix "\n" s) ""))))
    (move-end-of-line 1)
    (newline)
    (insert line)
    (move-beginning-of-line 1)
    (forward-char column)))

(global-set-key (kbd "C-,") 'rc/duplicate-line)

;; 10. Tsoding 选中文本项目全局搜索（C-c s）
(defun rc/rgrep-selected (beg end)
  "Search for selected region across the project using rgrep."
  (interactive (if (use-region-p)
                   (list (region-beginning) (region-end))
                 (list (point) (point))))
  (let ((selection (buffer-substring-no-properties beg end)))
    (if (string-empty-p selection)
        (call-interactively 'rgrep)
      (rgrep selection "*" default-directory))))

(global-set-key (kbd "C-c s") 'rc/rgrep-selected)

;; 11. 行尾多余空格治理：高亮显示 + C/C++/Rust/Zig 保存时自动清理
(setq-default show-trailing-whitespace t)
(dolist (hook '(term-mode-hook
                vterm-mode-hook
                compilation-mode-hook
                dired-mode-hook
                minibuffer-setup-hook))
  (add-hook hook (lambda () (setq show-trailing-whitespace nil))))

(defun rc/auto-clean-whitespace-on-save ()
  "Automatically delete trailing whitespace before saving in code buffers."
  (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

(dolist (mode-hook '(simpc-mode-hook
                     c-mode-hook
                     c++-mode-hook
                     rust-mode-hook
                     zig-mode-hook))
  (add-hook mode-hook #'rc/auto-clean-whitespace-on-save))

(global-set-key (kbd "C-c w") 'delete-trailing-whitespace)

;; 12. 路径跳转、代码大纲与防误退出保护
(global-set-key (kbd "C-x C-g") 'find-file-at-point)
(global-set-key (kbd "C-c i m") 'imenu)
(setq confirm-kill-emacs 'y-or-n-p)

(provide 'init-tools)
;;; init-tools.el ends here
