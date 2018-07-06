;; Initialize `package'
(require 'package)

(package-initialize nil)

;; Add MELPA to `package-archives'
(unless (assoc "melpa" package-archives)
  (add-to-list 'package-archives
               '("melpa" . "https://melpa.org/packages/") t))

(unless package-archive-contents
  (package-refresh-contents))

;; Set up `use-package'
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(setq use-package-always-ensure t
      use-package-verbose t)

(setq load-prefer-newer t)

;; Backups & custom file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror 'nomessage)

(setq create-lockfiles nil
      backup-directory-alist `((".*" . ,temporary-file-directory))
      auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))

;; `PATH' configuration
(setq shell-file-name "zsh")

(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

;; Niceities
(defalias 'yes-or-no-p 'y-or-n-p)

(delete-selection-mode)
(setq delete-active-region t)

;; Disable tab indentation
(setq-default indent-tabs-mode nil)

;; Smoother scrolling
;; (setq mouse-wheel-scroll-amount '(1 ((shift) . 3)))
;; (setq mouse-wheel-progressive-speed nil)
;; (setq mouse-wheel-follow-mouse t)

;; Set up paredit
(use-package paredit
  :config
  (progn
    (add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode)
    (add-hook 'eval-expression-minibuffer-setup-hook 'enable-paredit-mode)
    (add-hook 'inferior-lisp-mode-hook 'enable-paredit-mode)

    (define-key paredit-mode-map (kbd "C-<backspace>") 'paredit-backward-kill-word)

    (use-package rainbow-delimiters
      :config
      (add-hook 'paredit-mode-hook 'rainbow-delimiters-mode))))

;; Appearance
(setq default-frame-alist '((width . 80) (height . 25)))

(use-package monokai-theme
  :init
  (setq monokai-use-variable-pitch nil)
  :config
  (load-theme 'monokai t))

;; Font settings
(defun font-available-p (font)
  "Check if FONT is available on the system"
  (member font (font-family-list)))

;; NOTE: Starting Emacs as a daemon doesn't load up a GUI frame, so functions
;; in `init.el' relying on that won't work. In the future, this can be circum-
;; vented using `after-make-frame-functions' to register a callback that gets
;; called on all new frames.

;; (when (font-available-p "Input")
;;   (set-face-attribute 'default nil :font "Input-13"))

(add-to-list 'default-frame-alist '(font . "Input-14"))

;; Disable GUI cruft
(when (fboundp 'tool-bar-mode) (tool-bar-mode 0))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode 0))

(setq frame-title-format nil)
(setq ring-bell-function 'ignore)

;; Disable startup screen
(setq inhibit-startup-message t)
(setq inhibit-startup-echo-area-message "hanziq")

;; Modify file I/O
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; Always follow symlinks into Git
(setq vc-follow-symlinks t)

;; Always show the most actual version of a file
(global-auto-revert-mode)

;; Always automatically fill in text modes
(setq-default fill-column 70)
(add-hook 'text-mode-hook 'auto-fill-mode)

(add-hook 'prog-mode-hook 'subword-mode)

(add-hook 'after-save-hook
          'executable-make-buffer-file-executable-if-script-p)

(setq sentence-end-double-space nil)

(setq require-final-newline t)

(setq-default dired-listing-switches "-alh")

(setq mouse-yank-at-point t)

;; Keyboard bindings
(defun sindriava/beginning-of-line ()
  "Move to first non-whitespace character on `C-a' first."
  (interactive)
  (let ((old-point (point)))
    (back-to-indentation)
    (when (= (point) old-point)
      (beginning-of-line))))

(global-set-key (kbd "C-a") 'sindriava/beginning-of-line)

(defun sindriava/kill-buffer ()
  "Kill buffer (except for `*scratch*') and return to `*scratch*'."
  (interactive)
  (let ((buffer (buffer-name)))
    (if (equal buffer "*scratch*")
        (message "Cannot kill scratch buffer.")
      (progn
        (kill-buffer buffer)
        (switch-to-buffer "*scratch*")))))

(global-set-key (kbd "C-x k") 'sindriava/kill-buffer)

;; Swap `open-line' and `other-window'
(global-set-key (kbd "C-x o") 'open-line)
(global-set-key (kbd "C-o") 'other-window)

;; Set up Swiper
(use-package swiper
  :init
  (setq ivy-use-virtual-buffers t)
  :config
  (progn
    ;; (use-package counsel
    ;;   :config
    ;;   (progn
    ;;     (global-set-key (kbd "M-y") 'counsel-yank-pop)))

    (setq ivy-re-builders-alist
          '((t . ivy--regex-ignore-order)))

    (setq ivy-extra-directories nil)

    (global-set-key (kbd "C-s") 'swiper)

    (ivy-mode 1)))

;; Prettier cursor
(setq-default cursor-type 'bar)
;;(set-cursor-color "#F92672")
(add-to-list 'default-frame-alist '(cursor-color . "#F92672"))

;; Multiple cursors
;; (use-package multiple-cursors
;;   :config
;;   (progn
;;     (global-set-key (kbd "C->") (lambda (&rest args)
;;                                   (interactive "p")
;;                                   (setq cursor-type 'box)
;;                                   (apply 'mc/mark-next-like-this args)))
;;     (global-set-key (kbd "C-<") 'mc/unmark-next-like-this)
;;
;;     (add-hook 'multiple-cursors-mode-disabled-hook (lambda ()
;;                                                      (setq cursor-type 'bar)))))

;; Set up Avy
(use-package avy
  :config
  (global-set-key (kbd "C-:") 'avy-goto-char))


(defun sensible-defaults/comment-or-uncomment-region-or-line ()
  "Comments or uncomments the region or the current line if
there's no active region."
  (interactive)
  (let (beg end)
    (if (region-active-p)
        (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (comment-or-uncomment-region beg end)))

(global-set-key (kbd "M-;")
                'sensible-defaults/comment-or-uncomment-region-or-line)

(when (string= system-type "darwin")
  (setq dired-use-ls-dired nil))
