;; .emacs --- My dot emacs file

;; Author: Sebastian Monia <smonia@outlook.com>
;; URL: https://github.com/sebasmonia/.emacs
;; Version: 3
;; Keywords: .emacs dotemacs

;; This file is not part of GNU Emacs.

;;; Commentary:

;; My dot Emacs file
;; In theory I should be able to just drop the file in any computer and have
;; the config synced without merging/adapting anything
;; Update 2019-05-06: V3 means I moved to use-package

;;; Code:

(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
(add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/") t)

(when (< emacs-major-version 27)
  (package-initialize))

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Try to refresh package contents,  handle error and
;; print message if it fails (no internet connection?)
;;(condition-case err
;;  (package-refresh-contents)
;;  (error
;;   (message "%s" (error-message-string err))))

(require 'use-package)
(setq use-package-verbose t)
(setq use-package-always-ensure t)

(setq custom-file (concat user-emacs-directory "custom.el"))

(custom-set-faces
 '(default ((t (:family "Consolas" :foundry "MS  " :slant normal :weight normal :height 113 :width normal)))))

;; based on http://www.ergoemacs.org/emacs/emacs_menu_app_keys.html
(defvar hoagie-keymap (define-prefix-command 'hoagie-keymap) "My custom bindings.")
(define-key key-translation-map (kbd "<apps>") (kbd "<menu>")) ;; compat Linux-Windows
(define-key key-translation-map (kbd "<print>") (kbd "<menu>")) ;; curse you, thinkpad keyboard!!!
(global-set-key (kbd "<menu>") 'hoagie-keymap)
(global-set-key (kbd "C-'") 'hoagie-keymap) ;; BT keyboard has an uncomfortable menu key, so...

;; could be replaced by isearch-lazy-count...
(use-package anzu
  :bind
  (("<remap> <isearch-query-replace>" . anzu-isearch-query-replace)
   ("<remap> <isearch-query-replace-regexp>" . anzu-isearch-query-replace-regexp)
   ("<remap> <query-replace>" . anzu-query-replace)
   ("<remap> <query-replace-regexp>" . anzu-query-replace-regexp))
  :init
  (global-anzu-mode 1)
  :custom
  (anzu-cons-mode-line-p nil)
  (anzu-deactivate-region t)
  (anzu-mode-lighter "")
  (anzu-replace-threshold 50)
  (anzu-replace-to-string-separator " => ")
  (anzu-search-threshold 1000))

;; This aims to replace:
;; 1 - My older PUSH AND MARK code
;; 2 - A package idea I had, to  replicate the VS "11 lines away - drop marker" feature from Visual Studio
;; See: https://blogs.msdn.microsoft.com/zainnab/2010/03/01/navigate-backward-and-navigate-forward/
(use-package back-button
  :demand t
  :bind
  ("M-`" . back-button-global-backward)
  ("M-~" . back-button-global-forward)
  ("C-`" . back-button-push-mark-local-and-global)
  :custom
  (mark-ring-max 80)
  (global-mark-ring-max 80)
  (set-mark-command-repeat-pop t)
  (back-button-global-backward-keystrokes nil)
  (back-button-global-forward-keystrokes nil)
  (back-button-global-keystrokes nil)
  (back-button-local-backward-keystrokes nil)
  (back-button-local-forward-keystrokes nil)
  (back-button-local-keystrokes nil)
  (back-button-smartrep-prefix "")
  :config
  (advice-add 'push-mark :override #'back-button-push-mark-local-and-global)
  (defun hoagie-push-mark-if-not-repeat (command &rest args)
    "Push a mark if this is not a repeat invocation of `command'."
    (unless (equal last-command this-command)
      (back-button-push-mark-local-and-global)))

  (let ((advice-push-after '(isearch-forward
                             isearch-backward
                             )))
    (mapc (lambda (f) (advice-add f :after #'back-button-push-mark-local-and-global))
          advice-push-after))

  ;; (let ((advice-push-before '(xref-goto-xref)))
  ;;   (mapc (lambda (f) (advice-add f :before #'hoagie-push-mark))
  ;;         advice-push-before))

  (let ((advice-pushnr-before '(scroll-up-command
                                scroll-down-command
         ;; this one is cheating, as I'm not counting "11 lines". But since
         ;; I rarely use the mouse, this is good enough
                                mouse-set-point)))
    (mapc (lambda (f) (advice-add f :before #'hoagie-push-mark-if-not-repeat))
          advice-pushnr-before))
  (back-button-mode))

(use-package browse-kill-ring
  :config
  (browse-kill-ring-default-keybindings))

(use-package company
  :bind
  ("M-S-<SPC>" . company-complete-common)
  (:map hoagie-keymap
        ("<SPC>" . company-complete-common))
  :hook (after-init . global-company-mode)
  :custom
  (company-idle-delay 0.2)  ;; Makes the Python REPL more responsive
  (company-minimum-prefix-length 3)
  (company-selection-wrap-around t)
  :config
  (define-key company-active-map (kbd "C-<return>") #'company-abort)
  (define-key company-active-map [tab] #'company-complete-selection)
  (define-key company-active-map [tab] #'company-complete-selection)
  (define-key company-active-map (kbd "TAB") #'company-complete-selection)
  (define-key company-active-map (kbd "C-n") #'company-select-next)
  (define-key company-active-map (kbd "C-p") #'company-select-previous))

(use-package awscli-capf
  :ensure t
  :commands (awscli-add-to-capf)
  :hook ((shell-mode . awscli-capf-add)
         (eshell-mode . awscli-capf-add)))

(use-package csharp-mode ;; manual load since I removed omnisharp
  :demand
  :hook
  (csharp-mode . (lambda ()
                        (subword-mode)
                        (setq-local fill-function-arguments-first-argument-same-line t)
                        (setq-local fill-function-arguments-second-argument-same-line nil)
                        (setq-local fill-function-arguments-last-argument-same-line t)
                        (define-key csharp-mode-map [remap c-fill-paragraph] 'fill-function-arguments-dwim))))


(define-key hoagie-keymap (kbd "G") #'project-find-regexp)
(use-package deadgrep
  :config
  (defun deadgrep--format-command-patch (rg-command)
    "Add --hidden to rg-command."
    (replace-regexp-in-string "^rg " "rg --hidden " rg-command))
  (advice-add 'deadgrep--format-command :filter-return #'deadgrep--format-command-patch)
  (defun hoagie-deadgrep-push-before ()
    (interactive)
    (back-button-push-mark)
    (call-interactively #'deadgrep))
  (define-key hoagie-keymap (kbd "g") #'hoagie-deadgrep-push-before))

(use-package dired
  :ensure nil
  :custom
  ;; Can get the same effect manually with M-n. When dwim is _not_
  ;; what I want, it can be super annoying
  (dired-dwim-target nil)
  (dired-listing-switches "-laogGhvD")
  :config
  (setq dired-compress-file-suffixes
        '(("\\.tar\\.gz\\'" #1="" "7z x -aoa -o%o %i")
          ("\\.tgz\\'" #1# "7z x -aoa -o%o %i")
          ("\\.zip\\'" #1# "7z x -aoa -o%o %i")
          ("\\.7z\\'" #1# "7z x -aoa -o%o %i")
          ("\\.tar\\'" ".tgz" nil)
          (":" ".tar.gz" "tar -cf- %i | gzip -c9 > %o")))
  (setq dired-compress-files-alist
        '(("\\.7z\\'" . "7z a -r %o %i")
          ("\\.zip\\'" . "7z a -r %o  %i")))
  (define-key hoagie-keymap (kbd "f") 'project-find-file)
  (define-key hoagie-keymap (kbd "F") 'find-name-dired)
  ;; from Emacs Wiki
  (defun dired-open-file ()
    "Call xdg-open on the file at point."
    (interactive)
    (call-process "xdg-open" nil 0 nil (dired-get-filename nil t)))
  (define-key dired-mode-map (kbd "C-<return>") #'dired-open-file)
  (defun hoagie-dired-jump (&optional arg)
    "Call dired-jump.  With prefix ARG, open in current window."
    (interactive "P")
    (let ((inverted (not arg)))
      (dired-jump inverted)))
  (define-key hoagie-keymap (kbd "j") #'hoagie-dired-jump)
  (define-key hoagie-keymap (kbd "J") (lambda () (interactive) (hoagie-dired-jump 4))))

(use-package dired-narrow
  :after dired
  :bind
  (:map dired-mode-map
        ;; more standard binding for filtering,
        ;; but I'm so used to \, leaving both
        ("\\" . dired-narrow)
        ("/" . dired-narrow)))

(use-package dired-git-info
  :after dired
  :bind
  (:map dired-mode-map
        (")" . dired-git-info-mode)))

(use-package docker
  :bind
  ("C-c d" . docker))

(use-package dockerfile-mode
  :demand t ;; not sure if really needed
  )

(use-package ediff
  :ensure nil
  :custom
  (ediff-forward-word-function 'forward-char) ;; from https://emacs.stackexchange.com/a/9411/17066
  (ediff-highlight-all-diffs t)
  (ediff-keep-variants nil)
  (ediff-window-setup-function 'ediff-setup-windows-plain)
  :config
  ;; from https://stackoverflow.com/a/29757750
  (defun ediff-copy-both-to-C ()
    "In ediff, copy A and then B to C."
    (interactive)
    (ediff-copy-diff ediff-current-difference nil 'C nil
                     (concat
                      (ediff-get-region-contents ediff-current-difference 'A ediff-control-buffer)
                      (ediff-get-region-contents ediff-current-difference 'B ediff-control-buffer))))
  (defun add-d-to-ediff-mode-map ()
    "Add key 'd' for 'copy both to C' functionality in ediff."
    (define-key ediff-mode-map "d" 'ediff-copy-both-to-C))
  (add-hook 'ediff-keymap-setup-hook 'add-d-to-ediff-mode-map)
  ;; One minor annoyance of using ediff with built-in vc was the window config being altered, so:
  (defvar hoagie-pre-ediff-windows nil "Window configuration before starting ediff.")
  (defun hoagie-ediff-store-windows ()
    "Store the pre-ediff window setup"
    (setq hoagie-pre-ediff-windows (current-window-configuration)))
  (defun hoagie-ediff-restore-windows ()
    "Use `hoagie-pre-ediff-windows' to restore the window setup."
    (set-window-configuration hoagie-pre-ediff-windows))
  (add-hook 'ediff-before-setup-hook #'hoagie-ediff-store-windows)
  ;; Welp, don't like using internals but, the regular hook doesn't quite work
  ;; the window config is restore but them _stuff happens_, so:
  (add-hook 'ediff-after-quit-hook-internal #'hoagie-ediff-restore-windows))

;; (use-package elec-pair
;;   :ensure nil
;;   :init (electric-pair-mode))

(use-package eww
  :defer t
  :ensure nil
  :init
  (add-hook 'eww-mode-hook #'toggle-word-wrap)
  (add-hook 'eww-mode-hook #'visual-line-mode)
  :config
  (setq browse-url-browser-function 'eww-browse-url)
  (define-key eww-mode-map "o" 'eww)
  (define-key eww-mode-map "O" 'eww-browse-with-external-browser))

(use-package eww-lnum
  :after eww
  :bind
  (:map eww-mode-map
        ("C-SPC" . eww-lnum-follow)))

;; My own shortcut bindings to LSP, under hoagie-keymap "l", are defined in the :config section
(setq lsp-keymap-prefix "C-c C-l")
(defvar hoagie-lsp-keymap (define-prefix-command 'hoagie-lsp-keymap) "Custom bindings for LSP mode.")
(use-package lsp-mode
  :hook ((csharp-mode . lsp)
         ;; if you want which-key integration
         (lsp-mode . lsp-enable-which-key-integration))
  :commands (lsp lsp-signature-active)
  :config
  (define-key hoagie-lsp-keymap (kbd "o") #'lsp-signature-activate) ;; o for "overloads"
  (define-key hoagie-lsp-keymap (kbd "r") #'lsp-rename)
  (define-key hoagie-keymap (kbd "l") hoagie-lsp-keymap)
  ;; These are general settings but I'm only messing with them because
  ;; https://emacs-lsp.github.io/lsp-mode/page/performance/ so, leaving them here
  ;; (setq gc-cons-threshold (* gc-cons-threshold 4))
  ;; (setq read-process-output-max (* 1024 1024))
  :custom
  (lsp-csharp-server-path "c:/home/omnisharp_64/OmniSharp.exe")
  (lsp-enable-snippet nil)
  (lsp-enable-folding nil)
  (lsp-auto-guess-root t)
  (lsp-file-watch-threshold nil)
  (lsp-eldoc-render-all t)
  (lsp-signature-auto-activate nil)
  (lsp-enable-symbol-highlighting nil)
  (lsp-modeline-code-actions-enable nil))

(use-package lsp-ui
  :commands lsp-ui-mode
  :config
  (define-key hoagie-lsp-keymap (kbd "i") #'lsp-ui-imenu)
  :custom
  (lsp-ui-doc-enable nil)
  (lsp-ui-doc-position 'top)
  (lsp-ui-doc-use-childframe nil)
  (lsp-ui-peek-enable nil)
  (lsp-ui-sideline-enable nil))

(use-package lsp-pyright
  :ensure t
  :hook (python-mode . (lambda ()
                          (require 'lsp-pyright)
                          (lsp))))

(use-package dap-mode
  :commands (dap-debug dap-breakpoints-add)
  :init
  (dap-mode 1)
  (dap-ui-mode 1)
  (dap-auto-configure-mode)
  (require 'dap-python)
  (require 'dap-pwsh)
  (require 'dap-netcore)
  (defvar hoagie-dap-keymap (define-prefix-command 'hoagie-dap-keymap))
  (define-key hoagie-dap-keymap (kbd "d") #'dap-debug)
  (define-key hoagie-dap-keymap (kbd "b") #'dap-breakpoint-toggle)
  (define-key hoagie-dap-keymap (kbd "n") #'dap-next)
  (define-key hoagie-dap-keymap (kbd "c") #'dap-continue)
  (define-key hoagie-dap-keymap (kbd "s") #'dap-disconnect) ;; "Stop"
  (define-key hoagie-keymap (kbd "d") hoagie-dap-keymap)
  :custom
  (dap-netcore-install-dir "/home/hoagie/.emacs.d/.cache/"))

(use-package eldoc-box
  :hook (prog-mode . eldoc-box-hover-mode)
  :config
  (setq eldoc-box-max-pixel-width 1024
        eldoc-box-max-pixel-height 768)
  (setq eldoc-idle-delay 0.1)
  ;; set the child frame face as 1.0 relative to the default font
  (set-face-attribute 'eldoc-box-body nil :inherit 'default :height 1.0))

(use-package expand-region
  :bind
  ("M-<SPC>" . er/expand-region)
  :config
  (er/enable-mode-expansions 'csharp-mode 'er/add-cc-mode-expansions))

(use-package fill-function-arguments
  :demand t
  :commands (fill-function-arguments-dwim)
  :custom
  (fill-function-arguments-indent-after-fill t)
  :config
  ;; taken literally from the project's readme.
  ;; reformat for more use-packageness if this sticks
  (add-hook 'prog-mode-hook (lambda () (local-set-key (kbd "M-q") #'fill-function-arguments-dwim)))
  (add-hook 'sgml-mode-hook (lambda ()
                              (setq-local fill-function-arguments-first-argument-same-line t)
                              (setq-local fill-function-arguments-argument-sep " ")
                              (local-set-key (kbd "M-q") #'fill-function-arguments-dwim)))
  (add-hook 'emacs-lisp-mode-hook (lambda ()
                                    (setq-local fill-function-arguments-first-argument-same-line t)
                                    (setq-local fill-function-arguments-second-argument-same-line t)
                                    (setq-local fill-function-arguments-last-argument-same-line t)
                                    (setq-local fill-function-arguments-argument-separator " ")
                                    (local-set-key (kbd "M-q") #'fill-function-arguments-dwim))))

(use-package format-all
  :bind ("C-c f" . format-all-buffer))

;; (use-package gud-cdb :load-path "~/.emacs.d/lisp/"
;;   :commands (cdb))

(use-package hl-line
  :ensure nil
  :hook
  (after-init . global-hl-line-mode))

(use-package ibuffer
  :ensure nil
  :bind ("C-x C-b" . ibuffer-other-window)
  :custom
  (ibuffer-default-sorting-mode 'major-mode)
  (ibuffer-expert t)
  (ibuffer-show-empty-filter-groups nil))

(use-package ibuffer-vc
  :demand t
  :after ibuffer
  :hook (ibuffer-mode . (lambda ()
                          (ibuffer-vc-set-filter-groups-by-vc-root)
                          (unless (eq ibuffer-sorting-mode 'alphabetic)
                            (ibuffer-do-sort-by-alphabetic))))
  :init
  (setq ibuffer-formats '((mark modified read-only vc-status-mini " "
                                (name 18 18 :left :elide)
                                " "
                                (size 9 -1 :right)
                                " "
                                (mode 16 16 :left :elide)
                                " "
                                (vc-status 16 16 :left)
                                " "
                                vc-relative-file))))

(use-package icomplete-vertical
  :ensure t
  :demand t
  :custom
  (icomplete-show-matches-on-no-input t)
  ;; (icomplete-hide-common-prefix nil)
  (icomplete-prospects-height 10)
  (icomplete-in-buffer t)
  ;; (completion-styles '(flex))
  (completion-styles '(substring partial-completion flex))
  (read-buffer-completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (completion-ignore-case t)
  ;; use TAB to cycle candidates
  (completion-cycle-threshold t)
  :config
  (fido-mode)
  (icomplete-vertical-mode)
  ;; Not the best place for this, but since icomplete displaced amx/smex...
  (define-key hoagie-keymap (kbd "<menu>") #'execute-extended-command)
  (define-key hoagie-keymap (kbd "C-'") #'execute-extended-command)
  :bind (:map icomplete-minibuffer-map
              ("C-<return>" . icomplete-fido-exit) ;; when there's no exact match
              ("C-j" . icomplete-fido-exit) ;; from the IDO days...
              ("<down>" . icomplete-forward-completions)
              ("C-n" . icomplete-forward-completions)
              ("<up>" . icomplete-backward-completions)
              ("C-p" . icomplete-backward-completions)
              ("C-v" . icomplete-vertical-toggle)))

(use-package json-mode
  :mode "\\.json$")

(use-package lyrics
  :commands lyrics
  :custom
  (lyrics-backend 'lyrics-azlyrics))

(with-eval-after-load "vc-hooks"
  (define-key vc-prefix-map "=" 'vc-ediff))
(with-eval-after-load "vc-dir"
  (define-key vc-dir-mode-map "=" 'vc-ediff)
  (define-key vc-dir-mode-map "k" 'vc-revert))
(defun hoagie-try-vc-here-and-there ()
  (interactive)
  (vc-dir (project-root (project-current))))
(global-set-key (kbd "C-x t") #'hoagie-try-vc-here-and-there)
(use-package magit
  :init
  :bind
  ("C-x g" . magit-status)
  :custom
  (magit-display-buffer-function 'display-buffer))

(use-package git-timemachine
  :bind ("C-x M-G" . git-timemachine))

(use-package minions
  :config
  (minions-mode 1)
  :custom
  (minions-mode-line-lighter "^"))

(use-package package-lint
  :commands package-lint-current-buffer)

(use-package project
  :config
  (add-to-list 'project-switch-commands '(?m "Magit status" magit-status))
  (add-to-list 'project-switch-commands '(?s "Shell" project-shell)))

(use-package plantuml-mode
  :commands plantuml-mode
  :mode (("\\.puml$" . plantuml-mode)
	 ("\\.plantuml$" . plantuml-mode))
  :config
  (setq plantuml-jar-path "~/plantuml.jar"))

(use-package powershell
  :bind
  ;; this one shadows the command to go back in
  ;; the mark ring
  (:map powershell-mode-map
        ("M-`" . nil)))

;; from https://karthinks.com/software/batteries-included-with-emacs/
(use-package pulse
  :ensure nil
  :custom
  (pulse-iterations 30)
  :custom-face
  ;; the docs say not to customize this font, yet it is the only way
  ;; to pulse an empty line...
  (pulse-highlight-face ((t (:extend t))))
  (pulse-highlight-start-face ((t (:inherit region :extend t))))
  :config
  (defun pulse-line (&rest _)
    "Pulse the current line."
    (pulse-momentary-highlight-one-line (point)))

  (dolist (command '(scroll-up-command scroll-down-command
                                       recenter-top-bottom other-window))
    (advice-add command :after #'pulse-line)))

(use-package python
  :ensure nil
  :custom
  (python-shell-font-lock-enable nil)
  (python-shell-interpreter "ipython")
  (python-shell-interpreter-args "--pprint --simple-prompt"))

(use-package replace
  :ensure nil
  :config
  ;; I'm surprised this isn't the default behaviour,
  ;; also couldn't find a way to change it from options
  (defun hoagie-occur-dwim ()
    "Run occur, if there's a region selected use that as input."
    (interactive)
    (back-button-push-mark-local-and-global)
    (if (use-region-p)
        (occur (buffer-substring-no-properties (region-beginning) (region-end)))
      (command-execute 'occur)))
  (define-key hoagie-keymap (kbd "o") 'hoagie-occur-dwim))

(use-package sharper :load-path "~/github/sharper"
  :demand t
  :bind
  (:map hoagie-keymap
        ("n" . sharper-main-transient))
  :custom
  (sharper-run-only-one t))

(use-package shell
  :ensure nil
  :hook
  (shell-mode . (lambda ()
                  (toggle-truncate-lines t))))


(use-package better-shell
  :after shell
  :bind (:map hoagie-keymap
              ("`" . better-shell-for-current-dir)))

(use-package sly
  :commands sly
  :config
  (setq inferior-lisp-program "sbcl --dynamic-space-size 2048"))

(use-package sly-quicklisp
  :after sly)

(use-package sql
  :ensure nil
  :custom
  (sql-ms-options '("--driver" "ODBC Driver 17 for SQL Server"))
  (sql-ms-program "/home/hoagie/github/sqlcmdline/sqlcmdline.py")
  :config
  (add-hook 'sql-interactive-mode-hook (lambda () (setq truncate-lines t))))

(use-package speed-type
  :commands (speed-type-text speed-type-region speed-type-buffer))

(use-package terraform-mode
  :mode "\\.tf$"
  :config
  (add-hook 'terraform-mode-hook #'terraform-format-on-save-mode))

(use-package web-mode
  :mode
  (("\\.html$" . web-mode)
   ("\\.phtml\\'" . web-mode)
   ("\\.tpl\\.php\\'" . web-mode)
   ("\\.[agj]sp\\'" . web-mode)
   ("\\.as[cp]x\\'" . web-mode)
   ("\\.cshtml\\'" . web-mode)
   ("\\.erb\\'" . web-mode)
   ("\\.mustache\\'" . web-mode)
   ("\\.djhtml\\'" . web-mode)
   ("\\.html?\\'" . web-mode)
   ("\\.css\\'" . web-mode)
   ("\\.xml?\\'" . web-mode))
  :init
  :custom
  (web-mode-enable-css-colorization t)
  (web-mode-enable-sql-detection t)
  (web-mode-enable-current-element-highlight t)
  (web-mode-markup-indent-offset 2))

(use-package which-key
  :config
  (which-key-mode)
  (which-key-setup-side-window-right-bottom)
  :custom
  (which-key-side-window-max-width 0.4)
  (which-key-sort-order 'which-key-prefix-then-key-order))

(use-package ws-butler
  :hook (prog-mode . ws-butler-mode))

(use-package yaml-mode
  :mode "\\.yml$")

;; MISC STUFF THAT IS NOT IN CUSTOMIZE (or easier to customize here)
;; and stuff that I moved from Custom to here hehehehe

;; this is new! testing it
(setq w32-use-native-image-API t)

(defalias 'yes-or-no-p 'y-or-n-p)
(setq inhibit-compacting-font-caches t)
; see https://emacs.stackexchange.com/a/28746/17066
(setq auto-window-vscroll nil)
;; behaviour for C-l. I prefer one extra line rather than top & bottom
;; and also start with the top position, which I found more useful
(setq recenter-positions '(1 middle -2))
;; Useful in Linux
(setq read-file-name-completion-ignore-case t)
;; helps compilation buffer not slowdown
;; see https://blog.danielgempesaw.com/post/129841682030/fixing-a-laggy-compilation-buffer
(setq compilation-error-regexp-alist
      (delete 'maven compilation-error-regexp-alist))
;; from http://www.jurta.org/en/emacs/dotemacs, set the major mode
;; of buffers that are not visiting a file
(setq-default major-mode (lambda ()
                           (if buffer-file-name
                               (fundamental-mode)
                             (let ((buffer-file-name (buffer-name)))
                               (set-auto-mode)))))
;; Better defaults from https://github.com/jacmoe/emacs.d/blob/master/jacmoe.org
(setq help-window-select t)
;; From https://github.com/wasamasa/dotemacs/blob/master/init.org
(setq line-number-display-limit-width 10000)
(setq comint-prompt-read-only t)
(defun my-shell-turn-echo-off ()
  (setq comint-process-echoes t))
(add-hook 'shell-mode-hook 'my-shell-turn-echo-off)
;; tired of this question. Sorry not sorry:
(setq custom-safe-themes t)
;; Separate from the "~" shortcut
(global-set-key (kbd "<S-f1>") (lambda () (interactive) (find-file user-init-file)))
;; What was in custom that didn't get use-package'd:
(delete-selection-mode)
(blink-cursor-mode -1)
(column-number-mode 1)
(horizontal-scroll-bar-mode -1)
(savehist-mode)
(setq-default indent-tabs-mode nil)
(setq
      dabbrev-case-distinction nil
      dabbrev-case-fold-search t
      dabbrev-case-replace nil
      default-frame-alist '((fullscreen . maximized) (vertical-scroll-bars . nil) (horizontal-scroll-bars . nil))
      delete-by-moving-to-trash t
      disabled-command-function nil
      enable-recursive-minibuffers t
      global-mark-ring-max 60
      grep-command "grep --color=always -nHi -r --include=*.* -e \"pattern\" ."
      inhibit-startup-screen t
      initial-buffer-choice t
      initial-scratch-message
      ";; Il semble que la perfection soit atteinte non quand il n'y a plus rien à ajouter, mais quand il n'y a plus à retrancher. - Antoine de Saint Exupéry\n;; It seems that perfection is attained not when there is nothing more to add, but when there is nothing more to remove.\n\n"
      mark-ring-max 60
      proced-filter 'all
      save-interprogram-paste-before-kill t
      visible-bell t)
(global-so-long-mode 1)

;; ;; from https://stackoverflow.com/a/22176971, move auto saves and
;; ;; back up files to a different folder so git or dotnet core won't
;; ;; pick them up as changes or new files in the project
(make-directory (concat user-emacs-directory "auto-save") t)
(setq auto-save-file-name-transforms
      `((".*" ,(concat user-emacs-directory "auto-save/") t)))

(make-directory (concat user-emacs-directory "backups") t)
(setq backup-directory-alist
      `(("." . ,(expand-file-name
                 (concat user-emacs-directory "backups/")))))

;; from https://gitlab.com/jessieh/dot-emacs
(setq-default
 backup-by-copying t                                    ; Don't delink hardlinks
 version-control t                                      ; Use version numbers on backups
 delete-old-versions t                                  ; Do not keep old backups
 kept-new-versions 5                                    ; Keep 5 new versions
 kept-old-versions 3                                    ; Keep 3 old versions
 )

;; OTHER BINDINGS
; adapted for https://stackoverflow.com/questions/6464738/how-can-i-switch-focus-after-buffer-split-in-emacs
(global-set-key (kbd "C-x 3") (lambda () (interactive)(split-window-right) (other-window 1)))
(global-set-key (kbd "C-x 2") (lambda () (interactive)(split-window-below) (other-window 1)))
(global-set-key (kbd "C-M-}") (lambda () (interactive)(shrink-window-horizontally 5)))
(global-set-key (kbd "C-M-{") (lambda () (interactive)(enlarge-window-horizontally 5)))
(global-set-key (kbd "C-M-_") (lambda () (interactive)(shrink-window 5)))
(global-set-key (kbd "C-M-+") (lambda () (interactive)(shrink-window -5)))
(global-set-key (kbd "M-o") 'other-window)
(global-set-key (kbd "M-O") 'other-frame)
(global-set-key (kbd "M-N") 'next-buffer)
(global-set-key (kbd "M-P") 'previous-buffer)
(global-set-key (kbd "C-d") 'delete-forward-char) ;; replace delete-char
(global-set-key (kbd "M-c") 'capitalize-dwim)
(global-set-key (kbd "M-u") 'upcase-dwim)
(global-set-key (kbd "M-l") 'downcase-dwim)
;; from https://emacsredux.com/blog/2020/06/10/comment-commands-redux/
(global-set-key [remap comment-dwim] #'comment-line)
(global-set-key (kbd "C-c r") 'recompile)
(define-key hoagie-keymap (kbd "b") #'browse-url-at-point)
(define-key hoagie-keymap (kbd "t") #'toggle-truncate-lines)
(define-key hoagie-keymap (kbd "k") (lambda () (interactive) (kill-buffer)))
(global-set-key (kbd "C-c !") 'flymake-show-diagnostics-buffer) ;; like flycheck's C-c ! l
(global-set-key (kbd "C-;") 'dabbrev-expand)
(global-set-key (kbd "<f6>") 'kmacro-start-macro)
(global-set-key (kbd "<f7>") 'kmacro-end-macro)
(global-set-key (kbd "<f8>") 'kmacro-end-and-call-macro)

(defun hoagie-kill-buffer-filename ()
  "Sends the current buffer's filename to the kill ring."
  (interactive)
  (let ((name (buffer-file-name)))
    (when name
      (kill-new name))
    (message (format "Filename: %s" (or name "-No file for this buffer-")))))
(global-set-key (kbd "<C-f1>") 'hoagie-kill-buffer-filename)
(define-key dired-mode-map (kbd "<C-f1>") (lambda () (interactive) (dired-copy-filename-as-kill 0)))

;; from https://www.emacswiki.org/emacs/BackwardDeleteWord
;; because I agree C-backspace shouldn't kill the word!
;; it litters my kill ring
(defun delete-word (arg)
  "Delete characters forward until encountering the end of a word.
With ARG, do this that many times."
  (interactive "p")
  (if (use-region-p)
      (delete-region (region-beginning) (region-end))
    (delete-region (point) (progn
                             (forward-word arg)
                             (point)))))
(defun backward-delete-word (arg)
  "Delete characters backward until encountering the end of a word.
With ARG, do this that many times."
  (interactive "p")
  (delete-word (- arg)))
(global-set-key (kbd "C-<backspace>") 'backward-delete-word)

;; Convenient to work with AWS timestamps
(defun hoagie-convert-timestamp (&optional timestamp)
  "Convert a Unix TIMESTAMP (as string) to date.  If the parameter is not provided use word at point."
  (interactive)
  (setq timestamp (or timestamp (thing-at-point 'word t)))
  (let ((to-convert (if (< 10 (length timestamp)) (substring timestamp 0 10) timestamp))
        (millis (if (< 10 (length timestamp)) (substring timestamp 10 (length timestamp)) "000")))
    (message "%s.%s"
             (format-time-string "%Y-%m-%d %H:%M:%S"
                                 (seconds-to-time
                                  (string-to-number to-convert)))
             millis)))
(define-key hoagie-keymap (kbd "t") 'hoagie-convert-timestamp)

;; from https://stackoverflow.com/a/33456622/91877, just like ediff's |
(defun toggle-window-split ()
  "Swap two windows between vertical and horizontal split."
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
         (next-win-buffer (window-buffer (next-window)))
         (this-win-edges (window-edges (selected-window)))
         (next-win-edges (window-edges (next-window)))
         (this-win-2nd (not (and (<= (car this-win-edges)
                     (car next-win-edges))
                     (<= (cadr this-win-edges)
                     (cadr next-win-edges)))))
         (splitter
          (if (= (car this-win-edges)
             (car (window-edges (next-window))))
          'split-window-horizontally
        'split-window-vertically)))
    (delete-other-windows)
    (let ((first-win (selected-window)))
      (funcall splitter)
      (if this-win-2nd (other-window 1))
      (set-window-buffer (selected-window) this-win-buffer)
      (set-window-buffer (next-window) next-win-buffer)
      (select-window first-win)
      (if this-win-2nd (other-window 1))))))
(global-set-key (kbd "C-M-|") 'toggle-window-split)

;; simplified version that restores stored window config and advices delete-other-windows
;; idea from https://erick.navarro.io/blog/save-and-restore-window-configuration-in-emacs/
(defvar hoagie-window-configuration nil "Last window configuration saved.")
(defun hoagie-restore-window-configuration ()
  "Use `hoagie-window-configuration' to restore the window setup."
  (interactive)
  (when hoagie-window-configuration
    (set-window-configuration hoagie-window-configuration)))
(define-key hoagie-keymap (kbd "1") #'hoagie-restore-window-configuration)
(defun hoagie-store-config (&rest ignored)
  (setq hoagie-window-configuration (current-window-configuration)))
(advice-add 'delete-other-windows :before #'hoagie-store-config)

;; THEMES

(use-package modus-operandi-theme
  :demand t
  :custom
  (modus-operandi-theme-completions 'moderate))

(use-package doom-themes
  :demand t
  :config
  (setq doom-nord-light-brighter-modeline t
        doom-acario-light-brighter-modeline nil
        doom-challenger-deep-brighter-modeline nil))

(defun hoagie-load-theme (new-theme)
  "Pick a theme to load from a harcoded list. Or load NEW-THEME."
  (interactive (list (completing-read "Theme:"
                                      '(doom-acario-dark
                                        doom-acario-light
                                        doom-challenger-deep
                                        doom-nord-light
                                        doom-oceanic-next
                                        doom-one-light
                                        modus-operandi
                                        solo-jazz)
                                      nil
                                      t)))
    (mapc 'disable-theme custom-enabled-themes)
    (load-theme (intern new-theme) t))

(global-set-key (kbd "C-<f11>") #'hoagie-load-theme)
(hoagie-load-theme "modus-operandi")

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-project-detection 'project)
  (doom-modeline-buffer-file-name-style 'buffer-name)
  (doom-modeline-icon t)
  (doom-modeline-major-mode-icon t)
  (doom-modeline-major-mode-color-icon t)
  (doom-modeline-buffer-state-icon t)
  (doom-modeline-buffer-modification-icon t)
  (doom-modeline-unicode-fallback nil)
  (doom-modeline-minor-modes t)
  (doom-modeline-enable-word-count nil)
  (doom-modeline-buffer-encoding nil)
  (doom-modeline-indent-info nil)
  (doom-modeline-checker-simple-format t)
  (doom-modeline-number-limit 99)
  (doom-modeline-vcs-max-length 50)
  (doom-modeline-persp-name nil)
  (doom-modeline-display-default-persp-name nil)
  (doom-modeline-lsp t)
  (doom-modeline-github nil)
  (doom-modeline-modal-icon nil)
  (doom-modeline-mu4e nil)
  (doom-modeline-gnus nil)
  (doom-modeline-irc nil)
  (doom-modeline-env-version nil))

;; Per-OS configuration

(when (string= system-type "windows-nt")
  (load "c:/repos/miscscripts/workonlyconfig.el"))

(when (string= system-type "gnu/linux")
  (defun find-alternative-file-with-sudo ()
    (interactive)
    (let ((fname (or buffer-file-name
		     dired-directory)))
      (when fname
        (if (string-match "^/sudo:root@localhost:" fname)
	    (setq fname (replace-regexp-in-string
		         "^/sudo:root@localhost:" ""
		         fname))
	  (setq fname (concat "/sudo:root@localhost:" fname)))
        (find-alternate-file fname))))
  (global-set-key (kbd "C-x F") 'find-alternative-file-with-sudo)

  ;; Dynamic font size adjustment per monitor
  (require 'cl-lib)
  (defun hoagie-adjust-font-size (frame)
    "Inspired by https://emacs.stackexchange.com/a/44930/17066. FRAME is ignored."
    (let* ((attrs (frame-monitor-attributes)) ;; gets attribs for current frame
           (monitor-name (alist-get 'name attrs))
           (width-mm (cl-first (alist-get 'mm-size attrs)))
           (width-px (cl-third (alist-get 'workarea attrs)))
           (size "14")) ;; default size, go big just in case
      (when (string= monitor-name "0x057d") ;; laptop screen
        (setq size "13"))
      (when (string= monitor-name "S240HL") ;; external monitor at home
        (setq size "11"))
      (when (eq (length (display-monitor-attributes-list)) 1) ;; override everything if no external monitors!
        (setq size "11"))
      (set-frame-font (concat "Consolas " size))
      (set-face-font 'eldoc-box-body
                     (frame-parameter nil 'font))))
    (add-hook 'window-size-change-functions #'hoagie-adjust-font-size))

;; Experimental: use narrowing
;; modified from https://endlessparentheses.com/emacs-narrow-or-widen-dwim.html
(defun narrow-or-widen-dwim (p)
  "Widen if buffer is narrowed, narrow-dwim otherwise.
Dwim means: region, or defun, whichever applies first."
  (interactive "P")
  (declare (interactive-only)) ;; 2020-04-06: TIL about declare, and interactive-only
  (cond ((buffer-narrowed-p)
         (widen)
         (recenter))
        (p
         (narrow-to-page))
        ((region-active-p)
         (narrow-to-region (region-beginning)
                           (region-end)))
        (t (narrow-to-defun))))
;; the whole point is, I never use narrowing, so let's replace the default
;; bindings by this one
(global-set-key (kbd "C-x n") #'narrow-or-widen-dwim)

(defun hoagie-go-home (arg)
  (interactive "P")
  (if arg
      (dired-other-window "~/")
    (dired "~/")))
(global-set-key (kbd "<f1>") #'hoagie-go-home)

(defun hoagie-open-org (arg)
  (interactive "P")
  (let ((opener (if arg
                    #'ido-find-file-other-window
                  #'ido-find-file))
        (default-directory "~/org"))
    (funcall opener)))

(global-set-key [f3] #'hoagie-open-org)


;; Emacs window management

;; Using the code in link below as starting point:
;; https://protesilaos.com/dotemacs/#h:3d8ebbb1-f749-412e-9c72-5d65f48d5957
;; My config is a lot simpler for now. Just display most things below, use
;; 1/3rd or 40% of the screen. On the left shell/xref on the left and on the right
;; compilation/help/messages and a few others
(setq display-buffer-alist
      '(;; right side window
        ("\\(*shell.*\\|*xref.*\\|\\*Occur\\*\\|\\*deadgrep.*\\)"
         (display-buffer-in-side-window)
         (window-height . 0.33)
         (side . bottom)
         (slot . 0))
        ;; bottom side window - no reuse
        ("\\(COMMIT_EDITMSG\\)"
         (display-buffer-in-side-window)
         (window-height . 0.33)
         (side . bottom))
        ;; bottom side window - reuse if in another frame
        ("\\*\\(Backtrace\\|Warnings\\|Environments .*\\|Builds .*\\|compilation\\|[Hh]elp\\|Messages\\|Flymake.*\\|eglot.*\\)\\*"
         (display-buffer-reuse-window
          display-buffer-in-side-window)
         (window-height . 0.33)
         (reusable-frames . visible)
         (side . bottom)
         (slot . 1))
        ;; stuff that splits to the right - non-side window
        ("\\(magit\\|\\*info\\).*"
         (display-buffer-in-direction)
         (window . main)
         (direction . right))))
(setq switch-to-buffer-obey-display-actions nil)

(defun hoagie-quit-side-windows ()
  "Quit side windows of the current frame."
  (interactive)
  (dolist (window (window-at-side-list))
    (quit-window nil window)))
(define-key hoagie-keymap (kbd "0") #'hoagie-quit-side-windows)
