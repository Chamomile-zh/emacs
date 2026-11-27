;;; init-ui.el --- Theme, fonts and display defaults -*- lexical-binding: t; -*-

;; 首帧直接使用目标主题，避免延迟加载时闪过默认配色。
(use-package gruvbox-theme
  :config
  (load-theme 'gruvbox-dark-medium t))

(defun chamomile/setup-fonts ()
  "Use installed monospace and CJK fonts in the selected GUI frame."
  (when (display-graphic-p)
    ;; Maple Mono 用于代码；没有安装时保留 Emacs 的默认字族。
    (when (member "Maple Mono" (font-family-list))
      (set-face-attribute 'default (selected-frame)
                          :family "Maple Mono"
                          :height 130
                          :weight 'regular))
    ;; 普通 Maple Mono 不含中文。只为 CJK 文字指定字体，其他符号照常回退。
    (when (member "Noto Sans CJK SC" (font-family-list))
      (dolist (script '(han kana cjk-misc bopomofo))
        (set-fontset-font t script (font-spec :family "Noto Sans CJK SC")
                          (selected-frame) 'prepend)))))

;; 普通 GUI 和 daemon 后续新建的 GUI frame 都需要字体；终端跳过。
(add-hook 'after-init-hook #'chamomile/setup-fonts)
(add-hook 'server-after-make-frame-hook #'chamomile/setup-fonts)

(setq scroll-step 1
      scroll-conservatively 10000)
(setq display-line-numbers-type 'relative)
(column-number-mode 1)
(global-display-line-numbers-mode 1)

(provide 'init-ui)
;;; init-ui.el ends here
