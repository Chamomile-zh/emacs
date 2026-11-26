;;; init-packages.el --- Package policy and Custom settings -*- lexical-binding: t; -*-

;; Custom 写入独立文件，不覆盖手写配置。
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-readable-p custom-file)
  (load custom-file nil 'nomessage))

(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu"   . "https://elpa.gnu.org/packages/")))

;; 使用 early-init.el 启用的自动激活缓存，不再手动扫描所有包。
(require 'use-package)
(setq use-package-always-ensure t)

(defun chamomile/package-install-with-refresh (install &rest args)
  "Call INSTALL with ARGS, refreshing package indexes once on failure."
  (condition-case nil
      (apply install args)
    (error
     (package-refresh-contents)
     (apply install args))))

;; 本地索引过期时才刷新重试；已安装的包不需要联网。
(advice-add 'package-install :around #'chamomile/package-install-with-refresh)

(provide 'init-packages)
;;; init-packages.el ends here
