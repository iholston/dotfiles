;;; editing.el --- Buffers, Markdown, clipboard, Docker helpers, and context menus -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'seq)
(require 'subr-x)

;;; ─── Kill buffers not shown in any workspace ────────────────────────────
;; Reclaim buffer clutter: kill everything that isn't currently displayed in a
;; window in ANY workspace. Because persp-mode only keeps the CURRENT
;; workspace's windows live, we also read each other workspace's saved layout so
;; their visible buffers are preserved.
(defun +my/displayed-buffer-names ()
  "Return a hash-set (buffer name → t) of buffers shown in a window anywhere.
Covers live windows on all frames (the current perspective and any extra
frames) plus every persp-mode perspective's saved window layout."
  (let ((seen (make-hash-table :test 'equal)))
    ;; live windows across all frames (current perspective + extra frames)
    (walk-windows (lambda (w) (puthash (buffer-name (window-buffer w)) t seen))
                  'no-minibuf t)
    ;; saved layout of every perspective (covers non-current workspaces)
    (when (and (bound-and-true-p persp-mode) (boundp '*persp-hash*))
      (dolist (p (hash-table-values *persp-hash*))
        (when p
          (cl-labels ((walk (x)
                        (when (consp x)
                          (when (and (eq (car x) 'buffer) (stringp (cadr x)))
                            (puthash (cadr x) t seen))
                          (walk (car x))
                          (walk (cdr x)))))
            (walk (persp-window-conf p))))))
    seen))

(defun +my/kill-buffers-not-shown (&optional no-confirm)
  "Kill every buffer not currently displayed in a window in any workspace.
Always preserved: internal/hidden buffers (names starting with a space),
*Messages*, *scratch*, the Doom fallback buffer (`doom-fallback-buffer-name'),
and any modified file-visiting buffer (so unsaved work is never lost).
Note: a live process in a hidden buffer WILL be terminated when its buffer is
killed. With a prefix arg (NO-CONFIRM), skip the confirmation prompt."
  (interactive "P")
  (let* ((shown (+my/displayed-buffer-names))
         (protected (delq nil (list "*Messages*" "*scratch*"
                                    (and (boundp 'doom-fallback-buffer-name)
                                         doom-fallback-buffer-name))))
         (victims
          (seq-filter
           (lambda (b)
             (let ((name (buffer-name b)))
               (and (not (gethash name shown))
                    (not (string-prefix-p " " name))
                    (not (member name protected))
                    (not (and (buffer-file-name b) (buffer-modified-p b))))))
           (buffer-list))))
    (if (null victims)
        (message "Nothing to kill: every buffer is shown or protected.")
      (when (or no-confirm
                (yes-or-no-p
                 (format "Kill %d buffer(s) not shown in any workspace? "
                         (length victims))))
        (let ((kill-buffer-query-functions nil)) ; suppress global query hooks
          (dolist (b victims)
            ;; ghostel/term buffers set a BUFFER-LOCAL query hook that a global
            ;; `let' can't shadow; clear it (and the process exit query) so the
            ;; kill is silent.
            (with-current-buffer b
              (setq-local kill-buffer-query-functions nil)
              (when-let ((p (get-buffer-process b)))
                (set-process-query-on-exit-flag p nil)))
            (kill-buffer b)))
        (message "Killed %d buffer(s); %d remain."
                 (length victims) (length (buffer-list)))))))

(map! :leader :desc "[P] Kill buffers not shown" "b K" #'+my/kill-buffers-not-shown)


;;; ─── Markdown HTML rendering (pandoc) ───────────────────────────────────
;; Enables M-x markdown-live-preview-mode (renders to HTML in a side window).
(after! markdown-mode
  (setq markdown-command
        (list (or (executable-find "pandoc") "pandoc")
              "--from=gfm" "--to=html5" "--standalone"))
  ;; These are automatically buffer-local, so set their defaults for every
  ;; Markdown buffer instead of changing only the buffer loading this config.
  (setq-default markdown-fontify-code-blocks-natively t ; highlight fenced code
                markdown-hide-markup t                  ; hide #, **, fences, etc.
                markdown-hide-urls t)                   ; show link text, hide URLs
  (custom-set-faces!
    '(markdown-header-face-1 :height 1.5 :weight bold)
    '(markdown-header-face-2 :height 1.3 :weight bold)
    '(markdown-header-face-3 :height 1.15 :weight bold))
  (add-hook 'markdown-mode-hook #'visual-line-mode))  ; soft-wrap long lines

;;; ─── M-x: copy a compact `docker ps' command to the clipboard ───────────
;; Any `defun' with an `(interactive)' form shows up in M-x automatically —
;; that's all M-x is (a picker over interactive commands). These put a tidy
;; docker command on your clipboard so you can paste it into an SSH session and
;; run it on the remote host. The `--format' Go-template trims `docker ps' to
;; two columns: container ID + image (which includes the :tag). Add fields to
;; taste, e.g. {{.Names}}, {{.Status}}, {{.Ports}} — see `docker ps --help'.

(defun +clipboard-put (text)
  "Copy TEXT to the macOS clipboard and the Emacs kill-ring."
  (kill-new text)                                   ; Emacs kill-ring / yank
  (when (executable-find "pbcopy")                  ; macOS system clipboard
    (with-temp-buffer
      (insert text)
      (call-process-region (point-min) (point-max) "pbcopy")))
  text)

;;; ─── Image-aware Cmd-V for Org and Markdown ────────────────────────────
(defun +clipboard-image--png-data ()
  "Return PNG bytes from the macOS clipboard, or nil when none are present."
  (when (display-graphic-p)
    (condition-case nil
        (let ((data (gui-get-selection 'CLIPBOARD 'image/png)))
          (when (and (stringp data)
                     (>= (length data) 8)
                     (equal (string-to-list (substring data 0 8))
                            '(137 80 78 71 13 10 26 10)))
            data))
      (error nil))))

(defun +clipboard-image--inside-vault-p ()
  "Return non-nil when the current local file belongs to `+notes-root'."
  (and buffer-file-name
       (not (file-remote-p buffer-file-name))
       (file-in-directory-p (file-name-directory
                             (expand-file-name buffer-file-name))
                            (file-name-as-directory
                             (expand-file-name +notes-root)))))

(defun +clipboard-image--destination-directory ()
  "Return the attachment directory for the current visiting buffer."
  (unless buffer-file-name
    (user-error "Save this Org or Markdown buffer before pasting an image"))
  (when (file-remote-p buffer-file-name)
    (user-error "Clipboard image paste is limited to local files"))
  (if (+clipboard-image--inside-vault-p)
      (file-name-as-directory (expand-file-name +notes-root))
    (file-name-as-directory
     (expand-file-name "images" (file-name-directory buffer-file-name)))))

(defun +clipboard-image--unique-file (directory)
  "Return an unused timestamped PNG filename in DIRECTORY."
  (let* ((stem (format "Pasted image %s" (format-time-string "%Y%m%d%H%M%S")))
         (candidate (expand-file-name (concat stem ".png") directory))
         (index 1))
    (while (file-exists-p candidate)
      (setq candidate
            (expand-file-name (format "%s (%d).png" stem index) directory)
            index (1+ index)))
    candidate))

(defun +clipboard-image--write-png (data target)
  "Write unibyte PNG DATA to local file TARGET."
  (make-directory (file-name-directory target) t)
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert data)
    (write-region (point-min) (point-max) target nil 'silent)))

(defun +clipboard-image--insert-link (target)
  "Insert an Org or Markdown image link to TARGET and return the link."
  (let* ((inside-vault (+clipboard-image--inside-vault-p))
         (relative (file-relative-name target
                                       (file-name-directory buffer-file-name)))
         (begin (point))
         (link
          (cond
           ((derived-mode-p 'org-mode)
            (format "[[file:%s]]" (org-link-escape relative)))
           ((derived-mode-p 'markdown-mode)
            (if inside-vault
                (format "![[%s]]" (file-name-nondirectory target))
              (require 'url-util)
              (format "![%s](%s)"
                      (file-name-base target)
                      (url-encode-url relative))))
           (t (user-error "Image paste supports Org and Markdown buffers")))))
    (insert link)
    (when (and (derived-mode-p 'org-mode) (display-graphic-p))
      (org-display-inline-images nil t begin (point)))
    link))

(defun +clipboard/paste-image-or-text ()
  "Paste a clipboard PNG as an attachment, otherwise perform normal text paste.

Inside the Obsidian vault, save images at the vault root using Obsidian's
`Pasted image TIMESTAMP.png' convention.  Markdown receives an Obsidian image
embed and Org receives a relative file link.  Outside the vault, save beneath
a sibling `images/' directory and insert a relative standard link."
  (interactive)
  (if-let* ((data (+clipboard-image--png-data)))
      (progn
        (barf-if-buffer-read-only)
        (let* ((directory (+clipboard-image--destination-directory))
               (target (+clipboard-image--unique-file directory)))
          (condition-case err
              (progn
                (+clipboard-image--write-png data target)
                (+clipboard-image--insert-link target)
                (message "Saved clipboard image: %s"
                         (abbreviate-file-name target))
                target)
            (error
             (when (file-exists-p target)
               (delete-file target))
             (signal (car err) (cdr err))))))
    (call-interactively
     (if (derived-mode-p 'org-mode) #'org-yank #'yank))))

(after! org
  (define-key org-mode-map (kbd "s-v") #'+clipboard/paste-image-or-text))
(after! markdown-mode
  (define-key markdown-mode-map (kbd "s-v")
              #'+clipboard/paste-image-or-text))

(defvar +docker-ps-format "docker ps --format '{{.ID}}  {{.Image}}'"
  "Compact `docker ps' command: container ID + image:tag, one per line.")

(defun +docker-ps-copy-command ()
  "Copy the compact `docker ps' COMMAND to the clipboard.
Paste it into your SSH session and run it on the remote host."
  (interactive)
  (+clipboard-put +docker-ps-format)
  (message "Copied to clipboard → %s" +docker-ps-format))

(defun +docker-ps-copy-output ()
  "Run the compact `docker ps' LOCALLY and copy its output to the clipboard.
Use this only when Docker is running on THIS machine."
  (interactive)
  (let ((out (string-trim (shell-command-to-string +docker-ps-format))))
    (if (string-empty-p out)
        (message "docker ps: nothing running here (or docker unavailable)")
      (+clipboard-put out)
      (message "Copied %d container(s) to clipboard:\n%s"
               (length (split-string out "\n" t)) out))))

;;; ─── Native right-click context menus ──────────────────────────────────
;; Emacs's built-in `context-menu-mode' is global, so enabling it would shadow
;; Ghostel's down-mouse-3/mouse-3 terminal reporting.  Use the same native menu
;; binding in an editing-only buffer-local mode instead.  Org and Markdown
;; inherit `text-mode'; language modes inherit `prog-mode'.
(defun +editing/context-menu-open (event)
  "Open the native context menu for EVENT without losing an Evil selection."
  (interactive "e")
  ;; Build the keymap now, while Evil's visual region is still active.  Copying
  ;; `context-menu-entry' into another mode map defers this through its :filter,
  ;; which loses the region context before `context-menu-region' runs.
  (popup-menu (context-menu-map event) event))

(defvar +editing-context-menu-mode-map (make-sparse-keymap)
  "Keymap for `+editing-context-menu-mode'.")

;; Keep these outside the `defvar' initializer so config reloads also replace
;; the old filtered binding in an already-running Emacs.
(define-key +editing-context-menu-mode-map [down-mouse-3]
            #'+editing/context-menu-open)
;; Consume the release event instead of falling through to the global
;; `mouse-save-then-kill' binding after the menu closes.
(define-key +editing-context-menu-mode-map [mouse-3] #'ignore)

(define-minor-mode +editing-context-menu-mode
  "Show Emacs's native context menu on right-click in editing buffers."
  :init-value nil
  :lighter nil
  :keymap +editing-context-menu-mode-map)

(dolist (hook '(text-mode-hook prog-mode-hook dired-mode-hook))
  (add-hook hook #'+editing-context-menu-mode))

(provide 'config-editing)
