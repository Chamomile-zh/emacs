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

(defvar-local chamomile/git-line-stat nil
  "Cached Git line counts displayed in the mode line.")

;; 状态栏只读取缓存，不在重绘时启动 Git。
(add-to-list 'mode-line-misc-info 'chamomile/git-line-stat 'append)

(defun chamomile/update-git-line-stat ()
  "Cache the current file's saved insertions and deletions relative to HEAD."
  (let ((stat
         (when (and buffer-file-name
                    (not (file-remote-p buffer-file-name))
                    (eq (vc-backend buffer-file-name) 'Git))
           (let ((default-directory (file-name-directory buffer-file-name))
                 (file (file-name-nondirectory buffer-file-name)))
             (with-temp-buffer
               ;; 直接调用 Git，路径按字面值处理；二进制文件没有行数。
               (when (eq 0 (process-file "git" nil '(t nil) nil "--literal-pathspecs"
                                         "diff" "--no-ext-diff" "--no-textconv"
                                         "--numstat" "HEAD" "--" file))
                 (goto-char (point-min))
                 (when (looking-at "\\([0-9]+\\)\t\\([0-9]+\\)\t")
                   (let ((added (string-to-number (match-string 1)))
                         (removed (string-to-number (match-string 2))))
                     (unless (and (zerop added) (zerop removed))
                       (format "  +%d -%d" added removed))))))))))
    (unless (equal stat chamomile/git-line-stat)
      (setq chamomile/git-line-stat stat)
      (force-mode-line-update))))

(defun chamomile/update-git-line-stat-after-magit ()
  "Refresh cached counts for open files in the current Magit repository."
  (when-let* ((root (magit-toplevel))
              ((not (file-remote-p root))))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (and (bound-and-true-p diff-hl-mode)
                   buffer-file-name
                   (string-prefix-p root buffer-file-name))
          (chamomile/update-git-line-stat))))))

(defun chamomile/enable-git-gutter ()
  "Show Git change indicators and line counts for the current tracked file."
  (when (and buffer-file-name
             (not (file-remote-p buffer-file-name))
             (eq (vc-backend buffer-file-name) 'Git))
    (diff-hl-mode 1)
    (add-hook 'after-save-hook #'chamomile/update-git-line-stat nil t)
    (add-hook 'after-revert-hook #'chamomile/update-git-line-stat nil t)
    (chamomile/update-git-line-stat)))

(use-package diff-hl
  :commands diff-hl-mode
  :init
  ;; 等 VC 刷新状态后再启用，确保首次打开就会安排绘制标记。
  ;; 只处理 Git 已跟踪的本地文件，Markdown 也适用。
  (add-hook 'find-file-hook #'chamomile/enable-git-gutter 20)
  :config
  ;; Magit 刷新时同步更新行边标记和状态栏统计。
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)
  (add-hook 'magit-post-refresh-hook #'chamomile/update-git-line-stat-after-magit))

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
