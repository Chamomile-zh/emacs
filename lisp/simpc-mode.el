;;; simpc-mode.el --- Simple C/C++ major mode -*- lexical-binding: t; -*-

(defvar simpc-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?_ "w" table)
    table))

(defconst simpc-keywords
  '("auto" "break" "case" "char" "const" "continue" "default" "do"
    "double" "else" "enum" "extern" "float" "for" "goto" "if"
    "inline" "int" "long" "register" "restrict" "return" "short"
    "signed" "sizeof" "static" "struct" "switch" "typedef" "union"
    "unsigned" "void" "volatile" "while" "alignas" "alignof" "bool"
    "constexpr" "false" "true" "nullptr" "static_assert" "thread_local"
    "class" "namespace" "template" "typename" "using" "virtual" "override"
    "concept" "requires" "co_await" "co_return" "co_yield"))

(defconst simpc-font-lock-keywords
  `((,(regexp-opt simpc-keywords 'words) . font-lock-keyword-face)
    ("#[a-zA-Z_]+" . font-lock-preprocessor-face)
    ("\\<[0-9]+\\(\\.[0-9]+\\)?[fFuUlL]*\\>" . font-lock-constant-face)))

(defun simpc-indent-line ()
  "Deterministic brace-based indentation."
  (interactive)
  (let ((indent-level 0)
        (pos (- (point-max) (point))))
    (save-excursion
      (beginning-of-line)
      (setq indent-level (car (syntax-ppss)))
      (when (looking-at "^[ \t]*}")
        (setq indent-level (max 0 (1- indent-level)))))
    (indent-line-to (* indent-level tab-width))
    (when (> (- (point-max) pos) (point))
      (goto-char (- (point-max) pos)))))

;;;###autoload
(define-derived-mode simpc-mode prog-mode "SimpC"
  "Minimalist C/C++ major mode."
  :syntax-table simpc-mode-syntax-table
  (setq-local font-lock-defaults '(simpc-font-lock-keywords))
  (setq-local indent-line-function #'simpc-indent-line)
  (setq-local comment-start "// ")
  (setq-local comment-end ""))

;; 默认接管 .c / .cpp / .h / .hpp 文件
(add-to-list 'auto-mode-alist '("\\.[ch]\\(pp\\)?\\'" . simpc-mode))

(provide 'simpc-mode)
;;; simpc-mode.el ends here
