;;; platform.el --- Executable paths and graphical/TTY platform behavior -*- lexical-binding: t; -*-

(require 'seq)

;;; ─── Portable executable paths and window navigation ───────────────────
(let ((local-bin (expand-file-name "~/.local/bin")))
  (when (file-directory-p local-bin)
    (add-to-list 'exec-path local-bin)
    (setenv "PATH" (concat local-bin path-separator (getenv "PATH")))))

(when (eq system-type 'gnu/linux)
  (let ((linuxbrew-bin "/home/linuxbrew/.linuxbrew/bin"))
    (when (file-directory-p linuxbrew-bin)
      (add-to-list 'exec-path linuxbrew-bin t)
      (unless (member linuxbrew-bin
                      (split-string (or (getenv "PATH") "") path-separator t))
        (setenv "PATH"
                (concat (getenv "PATH") path-separator linuxbrew-bin))))))

(after! evil
  (map! :map (evil-insert-state-map evil-normal-state-map)
        "S-<left>"  #'evil-window-left
        "S-<right>" #'evil-window-right
        "S-<up>"    #'evil-window-up
        "S-<down>"  #'evil-window-down))

;;; ─── Remote TTY pane background ────────────────────────────────────────
;; Terminal Emacs intentionally leaves the bottom-right safety cell untouched
;; to avoid auto-margin wrapping and scrolling the screen.  Match WezTerm's
;; underlying pane background to Doom while a remote client frame is open, so
;; that cell is invisible; restore the configured terminal scheme on exit.
(defun +remote-tty--frame-p (frame)
  "Return non-nil when FRAME is a remote Linux daemon TTY client."
  (and (frame-live-p frame)
       (eq system-type 'gnu/linux)
       (daemonp)
       (frame-parameter frame 'client)
       (not (display-graphic-p frame))))

(defun +remote-tty-set-wezterm-user-var (frame name value)
  "Set WezTerm user variable NAME to VALUE through remote TTY FRAME."
  (when (+remote-tty--frame-p frame)
    (send-string-to-terminal
     (format "\e]1337;SetUserVar=%s=%s\a"
             name (base64-encode-string value t))
     frame)))

(defun +remote-tty-install-command-arrow-decoding-h (&optional frame)
  "Decode WezTerm's Super-arrow CSI sequences in remote TTY FRAME."
  (let ((frame (or frame (selected-frame))))
    (when (+remote-tty--frame-p frame)
      (with-selected-frame frame
        (define-key input-decode-map "\e[1;9A" [s-up])
        (define-key input-decode-map "\e[1;9B" [s-down])))))

(defun +remote-tty--background-color (frame)
  "Return FRAME's default face background as an RGB hex string."
  (let ((color (face-attribute 'default :background frame t)))
    (when (and (stringp color)
               (not (string-prefix-p "unspecified" color)))
      (if (string-match-p "\\`#[[:xdigit:]]\\{6\\}\\'" color)
          color
        (when-let ((rgb (color-values color frame)))
          (format "#%02x%02x%02x"
                  (/ (nth 0 rgb) 257)
                  (/ (nth 1 rgb) 257)
                  (/ (nth 2 rgb) 257)))))))

(defun +remote-tty-sync-pane-background (&optional frame)
  "Set FRAME's terminal pane background to its Doom default face."
  (let ((frame (or frame (selected-frame))))
    (when (+remote-tty--frame-p frame)
      (+remote-tty-set-wezterm-user-var frame "REMOTE_EMACS" "1")
      (when-let ((color (+remote-tty--background-color frame)))
        ;; OSC 11 changes the terminal's dynamic default background color.
        (send-string-to-terminal (format "\e]11;%s\e\\" color) frame)
        (set-frame-parameter frame '+remote-tty-pane-background color)))))

(defun +remote-tty-sync-all-pane-backgrounds-h (&rest _)
  "Resynchronize remote TTY pane backgrounds after a theme change."
  (dolist (frame (frame-list))
    (+remote-tty-sync-pane-background frame)))

(defun +remote-tty-reset-pane-background-h (frame)
  "Restore FRAME's terminal-scheme background before deleting it."
  (when (+remote-tty--frame-p frame)
    (+remote-tty-set-wezterm-user-var frame "REMOTE_EMACS" "0")
    (when (frame-parameter frame '+remote-tty-pane-background)
      ;; OSC 111 resets the dynamic default background to WezTerm's scheme.
      (send-string-to-terminal "\e]111\e\\" frame)
      (set-frame-parameter frame '+remote-tty-pane-background nil))))

(when (and (eq system-type 'gnu/linux) (daemonp))
  (add-hook 'after-make-frame-functions #'+remote-tty-sync-pane-background)
  (add-hook 'after-make-frame-functions #'+remote-tty-install-command-arrow-decoding-h)
  (add-hook 'doom-load-theme-hook #'+remote-tty-sync-all-pane-backgrounds-h)
  (add-hook 'delete-frame-functions #'+remote-tty-reset-pane-background-h))


;;; ─── TTY side padding ──────────────────────────────────────────────────
;; GUI Emacs gets subtle breathing room from its pixel fringes.  TTY frames
;; have no fringes, so reserve one character cell on each side instead.  Keep
;; larger margins installed by Org pretty-view, zen/writeroom, or other modes.
(defconst +tty-side-padding-width 1
  "Minimum side margin, in columns, for Linux terminal frames.")

(defun +tty--apply-window-padding (window)
  "Apply minimum TTY side padding to WINDOW without shrinking larger margins."
  (when (and (eq system-type 'gnu/linux)
             (window-live-p window)
             (not (window-minibuffer-p window))
             (not (display-graphic-p (window-frame window))))
    (pcase-let ((`(,left . ,right) (window-margins window)))
      (let ((target-left (max +tty-side-padding-width (or left 0)))
            (target-right (max +tty-side-padding-width (or right 0))))
        ;; Avoid triggering another redisplay cycle when nothing changed.
        (unless (and (= target-left (or left 0))
                     (= target-right (or right 0)))
          (set-window-margins window target-left target-right))))))

(defun +tty-apply-side-padding (&optional frame-or-window)
  "Apply TTY padding after frame, window, or displayed-buffer changes."
  (cond
   ((windowp frame-or-window)
    (+tty--apply-window-padding frame-or-window))
   ((framep frame-or-window)
    (dolist (window (window-list frame-or-window 'no-minibuf))
      (+tty--apply-window-padding window)))
   (t
    (dolist (window (window-list nil 'no-minibuf))
      (+tty--apply-window-padding window)))))

(add-hook 'after-make-frame-functions #'+tty-apply-side-padding)
(add-hook 'window-buffer-change-functions #'+tty-apply-side-padding)
(add-hook 'window-configuration-change-hook #'+tty-apply-side-padding)

(provide 'config-platform)
