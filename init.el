;;; init.el --- Tsoding-style Minimalist Emacs Config -*- lexical-binding: t; -*-

;; 1. 启动后恢复合理 GC 阈值 (16MB)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024))))

;; 2. 加载路径与 custom.el 隔离
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;; 3. 包管理初始化
(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu"   . "https://elpa.gnu.org/packages/")))
(package-initialize)

(require 'use-package)
;; 当本地索引过期导致安装失败时，自动刷新一次软件源并重试
(defun my/package-install-with-refresh (orig-fun &rest args)
  (condition-case nil
      (apply orig-fun args)
    (error
     (package-refresh-contents)
     (apply orig-fun args))))

(advice-add 'package-install :around #'my/package-install-with-refresh)
(setq use-package-always-ensure t)

(use-package gruvbox-theme
  :config
  (load-theme 'gruvbox-dark-medium t)) ; 暖灰棕底色，黑色指针极其清晰
(defun my/setup-fonts ()
  "Configure Maple Mono NF CN font for both ASCII and CJK."
  (when (display-graphic-p)
    (set-face-attribute 'default nil
                        :family "Maple Mono NF CN"
                        :height 130
                        :weight 'regular)
    (dolist (charset '(kana han symbol cjk-misc bopomofo))
      (set-fontset-font t charset (font-spec :family "Maple Mono NF CN")))))

(add-hook 'after-init-hook #'my/setup-fonts)
(add-hook 'server-after-make-frame-hook #'my/setup-fonts)

;; 5. 原生手感：无备份文件、纯空格缩进、相对行号、双向剪贴板
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil
      ring-bell-function 'ignore
      use-short-answers t
      select-enable-clipboard t
      select-enable-primary t
      scroll-step 1
      scroll-conservatively 10000)

(setq-default indent-tabs-mode nil
              tab-width 4
              c-basic-offset 4)

(column-number-mode 1)
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)
(electric-pair-mode 1)
(global-auto-revert-mode 1)
(delete-selection-mode 1)
(save-place-mode 1)

;; 6. Ido + Smex 导航体系（零延迟文件/Buffer/命令切换）
(use-package ido
  :ensure nil
  :init
  (setq ido-enable-flex-matching t
        ido-everywhere t
        ido-use-filename-at-point 'guess
        ido-create-new-buffer 'always)
  :config
  (ido-mode 1))

(use-package ido-vertical-mode
  :config
  (ido-vertical-mode 1)
  (setq ido-vertical-define-keys 'C-n-and-C-p-only))

(use-package smex
  :bind (("M-x" . smex)
         ("M-X" . smex-major-mode-commands)))

;; 7. 加载模块
(require 'simpc-mode)
(require 'init-tools)
(require 'init-org)

(provide 'init)
;;; init.el ends here
