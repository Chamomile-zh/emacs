;;; init.el --- Chamomile Emacs entry point -*- lexical-binding: t; -*-

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; 入口只声明加载顺序；各模块负责注册按键、文件后缀和 hook。
;; 包管理必须先配置，余下模块才能使用 use-package。
(require 'init-packages)
(require 'init-ui)
(require 'init-editor)
(require 'init-navigation)
(require 'init-languages)
(require 'init-lsp)
(require 'init-org)

(provide 'init)
;;; init.el ends here
