;;; init-ui.el --- Theme, fonts and display defaults -*- lexical-binding: t; -*-

;; 首帧直接使用目标主题，避免延迟加载时闪过默认配色。
(use-package gruvbox-theme
  :config
  (load-theme 'gruvbox-dark-medium t))

(defun chamomile/setup-fonts ()
  "Configure the GUI font for both ASCII and CJK."
  (when (display-graphic-p)
    (set-face-attribute 'default nil
                        :family "Maple Mono NF CN"
                        :height 130
                        :weight 'regular)
    (dolist (charset '(kana han symbol cjk-misc bopomofo))
      (set-fontset-font t charset (font-spec :family "Maple Mono NF CN")))))

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
