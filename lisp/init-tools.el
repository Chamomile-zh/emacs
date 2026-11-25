;;; init-tools.el --- Tsoding workflow tools & custom functions -*- lexical-binding: t; -*-

;; 1. 文本补全：拒绝自动弹窗，用 M-/ 手动触发全局动态补全
(setq hippie-expand-try-functions-list
      '(try-expand-dabbrev
        try-expand-dabbrev-all-buffers
        try-expand-dabbrev-from-kill
        try-complete-file-name-partially
        try-complete-file-name
        try-expand-all-abbrevs
        try-expand-line))
(global-set-key (kbd "M-/") 'hippie-expand)

;; 2. 多光标重构（Tsoding 核心编辑利器）
(use-package multiple-cursors
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->"         . mc/mark-next-like-this)
         ("C-<"         . mc/mark-previous-like-this)
         ("C-c C-<"     . mc/mark-all-like-this)))

;; 3. Git 集成
(use-package magit
  :bind ("C-x g" . magit-status))

;; 4. 编译工作流：一键编译 + ANSI 颜色支持 + 自动滚动至首错
(setq compilation-scroll-output 'first-error)
(global-set-key (kbd "<f5>") 'compile)
(global-set-key (kbd "<f6>") 'recompile)

(use-package ansi-color
  :ensure nil
  :hook (compilation-filter . ansi-color-compilation-filter))

;; 5. Dired 文件管理器极简双栏化
(use-package dired
  :ensure nil
  :init
  ;; 双窗口并排时，按 C (复制) 或 R (移动) 默认目标为另一侧窗口路径
  (setq dired-dwim-target t
        dired-listing-switches "-alh --group-directories-first"
        dired-recursive-copies 'always
        dired-recursive-deletes 'top)
  :hook
  ;; 默认隐藏权限、硬链接、属主等冗余信息，按 ( 键可随时切换显示详情
  (dired-mode . dired-hide-details-mode)
  :bind (:map dired-mode-map
              ;; 在 Dired 中按 C-c C-e 进入 wdired 模式，像改文本一样批量重命名文件
              ("C-c C-e" . wdired-change-to-wdired-mode)))

;; 6. Tsoding 自写复制当前行函数（保留列光标位置）
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

;; 7. 行尾多余空格治理
(setq-default show-trailing-whitespace t)
(dolist (hook '(term-mode-hook
                vterm-mode-hook
                compilation-mode-hook
                dired-mode-hook
                minibuffer-setup-hook))
  (add-hook hook (lambda () (setq show-trailing-whitespace nil))))

(global-set-key (kbd "C-c w") 'delete-trailing-whitespace)

(provide 'init-tools)
;;; init-tools.el ends here
