;;; init-navigation.el --- Navigation, windows, search and Git -*- lexical-binding: t; -*-

;; Ido 必须尽早接管文件和缓冲区选择（包括其他命令发起的文件提示）。
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
  :init
  (setq ido-vertical-define-keys 'C-n-and-C-p-only)
  :config
  (ido-vertical-mode 1))

(use-package smex
  :bind (("M-x" . smex)
         ("M-X" . smex-major-mode-commands)))

(use-package magit
  :bind ("C-x g" . magit-status))

;; 按方向切换窗口：只注册 autoload 按键，首次使用才加载 Windmove。
(use-package windmove
  :ensure nil
  :bind (("S-<left>" . windmove-left)
         ("S-<right>" . windmove-right)
         ("S-<up>" . windmove-up)
         ("S-<down>" . windmove-down)))

;; 不延迟 Winner，否则首次撤销前的窗口布局不会被记录。
(use-package winner
  :ensure nil
  :config
  (winner-mode 1))

(use-package dired
  :ensure nil
  :init
  (setq dired-dwim-target t
        dired-listing-switches "-alh --group-directories-first"
        dired-recursive-copies 'always
        dired-recursive-deletes 'top)
  :hook (dired-mode . dired-hide-details-mode)
  :bind (:map dired-mode-map
              ("C-c C-e" . wdired-change-to-wdired-mode)))

(defun chamomile/rgrep-selected (beg end)
  "Search for the active region with rgrep, or prompt when there is no region."
  (interactive (if (use-region-p)
                   (list (region-beginning) (region-end))
                 (list (point) (point))))
  (if (= beg end)
      (call-interactively #'rgrep)
    (rgrep (buffer-substring-no-properties beg end) "*" default-directory)))

(keymap-global-set "C-c s" #'chamomile/rgrep-selected)
(keymap-global-set "C-c i m" #'imenu)

(defun chamomile/get-gcc-cpp-include-dirs ()
  "Return the include paths of the newest GCC C++ headers on this system."
  (let ((base-dir "/usr/include/c++"))
    (when (file-directory-p base-dir)
      (when-let* ((version (car (sort (directory-files base-dir nil "^[0-9]+\\(\\.[0-9]+\\)*$")
                                      #'version>))))
        (let ((directory (expand-file-name version base-dir)))
          (seq-filter #'file-directory-p
                      (list directory
                            (expand-file-name "x86_64-pc-linux-gnu" directory)
                            (expand-file-name "backward" directory))))))))

;; FFAP 首次被 Ido 或文件跳转命令用到时，才扫描系统头文件目录。
(use-package ffap
  :ensure nil
  :defer t
  :config
  (setq ffap-c-path
        (append '("/usr/include" "/usr/local/include")
                (chamomile/get-gcc-cpp-include-dirs))))

(defun chamomile/find-file-at-point ()
  "Open a C/C++ header or the file at point in another window."
  (interactive)
  (require 'ffap)
  (let ((header (save-excursion
                  (beginning-of-line)
                  (when (looking-at "[ \t]*#[ \t]*include[ \t]*[<\"]\\([^>\"\n]+\\)[>\"]")
                    (match-string-no-properties 1)))))
    (if header
        (if-let* ((file (locate-file header (cons default-directory ffap-c-path))))
            (find-file-other-window file)
          (message "Header not found in ffap-c-path: %s" header))
      ;; 非 #include 行必须从实际光标位置猜测，不要从行首猜。
      (let ((file (ffap-guesser)))
        (if (and file (file-exists-p file))
            (find-file-other-window file)
          (call-interactively #'find-file-other-window))))))

(keymap-global-set "C-x C-g" #'chamomile/find-file-at-point)

(provide 'init-navigation)
;;; init-navigation.el ends here
