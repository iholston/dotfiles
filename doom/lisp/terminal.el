;;; terminal.el --- Ghostel, Yazi, Treemacs, and project opening -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'seq)
(require 'subr-x)

;;; ─── ghostel — libghostty terminal (nice TUI rendering) ─────────────────
(use-package! ghostel
  :defer t
  :init
  ;; Ghostel's native PTY can deadlock when Zellij's startup queries create
  ;; reply backpressure.  Keep Ghostel's renderer but let Emacs own the PTY.
  (setq ghostel-use-native-pty nil)
  ;; Keep the required Linux renderer/parser module outside Doom's package
  ;; build tree, which `doom sync' may rebuild or purge.
  (when (eq system-type 'gnu/linux)
    (setq ghostel-module-directory
          (expand-file-name "~/.local/lib/ghostel/")))
  :config
  ;; Plain SPC must type a space in a terminal, so the SPC leader isn't
  ;; available in ghostel. Let Option+Space (M-SPC, Doom's alternate leader)
  ;; pass through to Emacs so you still get the leader menu here.
  (setopt ghostel-keymap-exceptions
          (cons "M-SPC" (remove "M-SPC" ghostel-keymap-exceptions))))
(use-package! evil-ghostel
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode))

;; Terminals manage their own grid width, so Emacs's horizontal auto-scroll
;; just fights ghostel: when a line fills the window the cursor runs past the
;; edge, the window scrolls right, and you get text shifted off the left plus
;; right-arrow truncation glyphs. Disable auto-hscroll in ghostel buffers so
;; the content stays pinned to the left.
;; Ghostel buffers also come up with `mode-line-format' = nil (no status bar);
;; restore Doom's default modeline so ghostel windows look like every other one.
;; Doom also classifies `*ghostel: …*' as an "unreal" buffer, and its workspace
;; auto-add (`+workspaces-add-current-buffer-h') filters unreal buffers out via
;; `doom-unreal-buffer-p'. So the terminal never joins the workspace and is
;; missing from `SPC b b' — regardless of whether it's shown in a popup or takes
;; over the window. Mark ghostel buffers "real" (like Doom does for vterm) so
;; Doom's own auto-add registers them and they behave as first-class buffers.
(defun +ghostel-configure-buffer-h ()
  "Apply personal display and workspace behavior to a Ghostel buffer."
  (setq-local auto-hscroll-mode nil)
  ;; Command-Up/Down and wheel-translated insert-state arrows use the shared
  ;; viewport helpers.  Keep them at a controlled two-line step remotely.
  (when (eq system-type 'gnu/linux)
    (setq-local +scroll-lines 2))
  (setq mode-line-format (default-value 'mode-line-format))
  (doom-mark-buffer-as-real-h)
  ;; `centaur-tabs-local-mode' has inverted-looking behavior when no competing
  ;; local header exists: enabling it hides the global tab strip in this buffer.
  ;; Some restored local Ghostel sessions retained that stale buffer-local mode,
  ;; even though they were correctly owned by and eligible in their workspace.
  (when (and (bound-and-true-p centaur-tabs-mode)
             (bound-and-true-p centaur-tabs-local-mode))
    (centaur-tabs-local-mode -1)))

(add-hook 'ghostel-mode-hook #'+ghostel-configure-buffer-h)

;; In evil normal state, Ghostel deliberately stops following when point leaves
;; the live terminal cursor so scrollback remains readable.  `evil-ghostel's G
;; returns point to the cursor, but does not explicitly anchor the window.  That
;; distinction matters when persp-mode restores a saved window-start or a split
;; resizes the terminal: the next redraw can preserve the stale viewport.
(defun +ghostel/follow-output ()
  "Move to Ghostel's live cursor and keep this window following output."
  (interactive)
  (when ghostel--pending-redraw
    (ghostel--redraw-now (current-buffer)))
  (ghostel--anchor-window (selected-window) t))

(after! evil-ghostel
  (evil-define-key* 'normal evil-ghostel-mode-map
    (kbd "G") #'+ghostel/follow-output))

(defun +ghostel--window-was-following-p (window)
  "Return non-nil when WINDOW's point is parked on its Ghostel cursor."
  (with-current-buffer (window-buffer window)
    (and (derived-mode-p 'ghostel-mode)
         ghostel--cursor-char-pos
         (= (window-point window) ghostel--cursor-char-pos))))

(defun +ghostel--restore-follow-windows (entries)
  "Redraw and re-anchor the live (WINDOW . BUFFER) pairs in ENTRIES."
  (dolist (entry entries)
    (let ((window (car entry))
          (buffer (cdr entry)))
      (when (and (window-live-p window)
                 (eq (window-buffer window) buffer))
        (with-current-buffer buffer
          (when (and ghostel--process (process-live-p ghostel--process))
            (ghostel--redraw-now buffer)
            (ghostel--anchor-window window t)))))))

(defun +ghostel--restore-follow-after-workspace-switch (_scope)
  "Restore Ghostel follow state after persp-mode rebuilds the window tree."
  ;; Capture intent before redisplay consumes a pending hidden-buffer redraw.
  ;; A zero-delay timer then runs after the restored layout has settled.
  (let ((entries
         (delq nil
               (mapcar (lambda (window)
                         (when (+ghostel--window-was-following-p window)
                           (cons window (window-buffer window))))
                       (window-list nil 'no-minibuf)))))
    (when entries
      (run-at-time 0 nil #'+ghostel--restore-follow-windows entries))))

(defun +remote-workspaces--restore-client-frame-layout (frame attempts)
  "Restore FRAME's current workspace layout once its terminal size is known."
  (when (and (frame-live-p frame) (frame-parameter frame 'client))
    (if (and (> (frame-width frame) 2) (> (frame-height frame) 2))
        (when-let ((persp (get-current-persp frame)))
          ;; emacsclient can initialize persp-mode while a TTY frame is still
          ;; 2x2.  Reapply the saved layout after the real dimensions arrive.
          (persp-restore-window-conf frame persp t)
          (when (fboundp '+tty-apply-side-padding)
            (+tty-apply-side-padding frame)))
      (when (> attempts 0)
        (run-at-time 0.05 nil
                     #'+remote-workspaces--restore-client-frame-layout
                     frame (1- attempts))))))

(defun +remote-workspaces-restore-client-frame-layout-h (frame)
  "Schedule workspace layout restoration for a new remote client FRAME."
  (when (and (eq system-type 'gnu/linux)
             (daemonp)
             (frame-parameter frame 'client))
    (run-at-time 0.05 nil
                 #'+remote-workspaces--restore-client-frame-layout frame 20)))

(after! persp-mode
  ;; Doom normally assigns every emacsclient frame a disposable workspace.  On
  ;; the remote Linux daemon that makes reconnecting select/create `main'
  ;; instead of returning to the workspace used before disconnect.  Use
  ;; persp-mode's stock new-frame behavior there: it selects
  ;; `persp-last-persp-name' and does not mark the reused workspace for deletion
  ;; with the frame.
  (when (and (eq system-type 'gnu/linux) (daemonp))
    (setq persp-emacsclient-init-frame-behaviour-override nil)
    (add-hook 'after-make-frame-functions
              #'+remote-workspaces-restore-client-frame-layout-h))
  (add-hook 'persp-activated-functions
            #'+ghostel--restore-follow-after-workspace-switch))

;; Local terminal helpers; only `SPC o t' is bound in the public config.
(defvar +ghostel--popup-buffer nil
  "The bottom-popup ghostel terminal most recently opened by `+ghostel/toggle'.
Tracked so the toggle hides EXACTLY that terminal (never a regular window/buffer
or a terminal you opened yourself), and spawns a fresh one on the next open.")

(defun +ghostel/toggle ()
  "Toggle a quick scratch terminal popup, FRESH on every open.
If the popup this command last opened is currently visible, hide its window —
the buffer is kept alive, so you can return to it later via `SPC b b'.
Otherwise spawn a BRAND-NEW ghostel session (no old history) docked at the
bottom. It only ever hides the terminal it opened itself, so terminals you open
for long-running work (and any regular window/buffer) are never touched."
  (interactive)
  (let ((buf +ghostel--popup-buffer))
    (if (and (buffer-live-p buf) (get-buffer-window buf))
        ;; the tracked popup is visible → hide it (keep the buffer alive)
        (if (> (length (window-list)) 1)
            (delete-window (get-buffer-window buf))
          (previous-buffer))         ; sole window → bury it, keep the window
      ;; nothing of ours visible → spawn a NEW fresh terminal as the popup
      (setq +ghostel--popup-buffer (save-window-excursion (ghostel '(4))))
      (pop-to-buffer +ghostel--popup-buffer))))

(defun +ghostel/here ()
  "Open a ghostel terminal in the CURRENT window."
  (interactive)
  ;; `switch-to-buffer' bypasses `display-buffer'/popup rules, so it takes over
  ;; the current window instead of popping up.
  (switch-to-buffer (save-window-excursion (ghostel))))

;; The two commands above REUSE one terminal per project (that's why every open
;; lands you in the same `*ghostel: …*' buffer). These two SPAWN a fresh session
;; each time — handy for a workspace with several panes (chat + file + terminal).
;; Explicit new-terminal helpers give stable workspace-scoped names; popups keep
;; Ghostel's normal automatic naming.
(defun +ghostel--next-workspace-terminal-name ()
  "Return an available terminal name: `WORKSPACE', then `WORKSPACE N' from 2."
  (let ((workspace (or (+workspace-current-name) "Workspace")))
    (if (not (get-buffer workspace))
        workspace
      (let ((number 2))
        (while (get-buffer (format "%s %d" workspace number))
          (setq number (1+ number)))
        (format "%s %d" workspace number)))))

(defun +ghostel/new ()
  "Open a fresh Ghostel terminal with a stable workspace-scoped name."
  (interactive)
  (let ((name (+ghostel--next-workspace-terminal-name))
        (buffer (save-window-excursion (ghostel '(4)))))
    (with-current-buffer buffer
      ;; OSC title/directory reports normally rename Ghostel buffers.  These are
      ;; explicit workspace names, so keep them stable for the buffer's lifetime.
      (setq-local ghostel-buffer-name-function nil)
      (rename-buffer name))
    ;; Do not rely on Doom's delayed switch-buffer hook for ownership: Centaur
    ;; needs the buffer in the perspective before its first normal-window draw.
    (when (bound-and-true-p persp-mode)
      (persp-add-buffer buffer (get-current-persp) nil nil))
    (switch-to-buffer buffer)
    ;; Fresh creation temporarily displays through Doom's popup path, whose
    ;; hook hides Centaur locally.  Reconfigure only after the final normal
    ;; switch so the terminal immediately shows its workspace tab strip.
    (+ghostel-configure-buffer-h)
    (when (bound-and-true-p centaur-tabs-mode)
      (centaur-tabs-buffer-update-groups)
      (centaur-tabs-display-update))))

(defun +ghostel/new-local ()
  "Open a fresh Ghostel in the Mac home directory, even from a TRAMP buffer."
  (interactive)
  (let ((default-directory (file-name-as-directory (getenv "HOME"))))
    (+ghostel/new)))

(defun +ghostel/new-popup ()
  "Open a BRAND-NEW ghostel terminal (fresh session) as a bottom popup."
  (interactive)
  (pop-to-buffer (save-window-excursion (ghostel '(4)))))

;; ─── Yazi chooser in Ghostel ────────────────────────────────────────────
;; Run the real Yazi TUI at the current buffer's `default-directory'.  Yazi's
;; chooser mode intercepts its normal open action, writes the selected paths to
;; a temporary file, and exits.  The exit hook then visits those files in Emacs,
;; replacing the transient terminal in the same window.  This is intentionally
;; scoped to this command, so normal Yazi sessions keep their configured opener.
(defvar-local +ghostel-yazi--chooser-file nil
  "Chooser output file for this Ghostel/Yazi buffer.")

(defvar-local +ghostel-yazi--launch-directory nil
  "Local or TRAMP directory where this Ghostel/Yazi session started.")

(defvar-local +ghostel-yazi--open-folder-p nil
  "Non-nil when Yazi should root Treemacs from its selected path.")

(defcustom +ghostel-yazi-remote-program "yazi"
  "Yazi executable used on remote SSH hosts."
  :type 'string)

(defun +ghostel-yazi--cleanup ()
  "Remove the chooser output associated with the current Yazi buffer."
  (when-let ((chooser +ghostel-yazi--chooser-file))
    (setq +ghostel-yazi--chooser-file nil)
    ;; A failed SSH session can make the TRAMP chooser unreachable.  Buffer
    ;; cleanup should still succeed in that case.
    (ignore-errors
      (when (file-exists-p chooser)
        (delete-file chooser)))))

(defun +ghostel-yazi--selected-path (path directory)
  "Resolve chooser PATH relative to local or TRAMP DIRECTORY."
  (let ((path (string-remove-suffix "\r" path)))
    (if-let ((remote-prefix (file-remote-p directory)))
        ;; Yazi writes ordinary remote paths such as /home/user/file.  An
        ;; absolute path passed directly to `expand-file-name' would discard
        ;; DIRECTORY's TRAMP prefix, so resolve the remote-local portion first.
        (concat remote-prefix
                (expand-file-name path
                                  (file-remote-p directory 'localname)))
      (expand-file-name path directory))))

(defun +open-folder--project-name (directory)
  "Return a readable Treemacs project name for DIRECTORY."
  (let* ((local (directory-file-name (file-local-name directory)))
         (name (file-name-nondirectory local)))
    (if (string-empty-p name)
        (or (file-remote-p directory 'host) directory)
      name)))

(defun +open-folder--show-treemacs-root (directory &optional file)
  "Show only DIRECTORY in Treemacs and optionally reveal FILE."
  (require 'treemacs)
  ;; Doom installs Perspective scope lazily with Treemacs.  Select/create the
  ;; matching workspace synchronously: treemacs-persp otherwise does this on a
  ;; timer after perspective switches, which can overwrite a just-selected root.
  (when (require 'treemacs-persp nil t)
    (treemacs-persp--ensure-workspace-exists))
  (let* ((root (treemacs-canonical-path directory))
         (target (and file (treemacs-canonical-path file)))
         (name (+open-folder--project-name root)))
    (save-selected-window
      ;; This is the implementation used by public `treemacs-select-directory'.
      (treemacs--show-single-project root name)
      (when target
        (when-let ((project (treemacs--find-project-for-path target)))
          (treemacs-goto-file-node target project))))
    root))

(defun +open-folder/path (path &optional window)
  "Open existing PATH with a VS Code-style Treemacs root.

For a directory, create a fresh dashboard tab whose `default-directory' is
PATH.  For a file, visit it in WINDOW (or the selected window).  Show only the
directory, or the file's parent, in the current Perspective-scoped Treemacs
workspace and reveal the file when applicable."
  (setq path (expand-file-name path))
  (unless (file-exists-p path)
    (user-error "No such file or directory: %s" path))
  (let* ((directory-p (file-directory-p path))
         (root (file-name-as-directory
                (if directory-p path (file-name-directory path))))
         (editor-window (if (window-live-p window) window (selected-window)))
         opened-buffer)
    (with-selected-window editor-window
      (if directory-p
          (progn
            (+tabs--open-dashboard)
            (setq-local default-directory root)
            (setq opened-buffer (current-buffer)))
        (setq opened-buffer (find-file-noselect path))
        (when (bound-and-true-p persp-mode)
          (persp-add-buffer opened-buffer (get-current-persp) nil nil))
        (switch-to-buffer opened-buffer))
      (+open-folder--show-treemacs-root root
                                       (unless directory-p path)))
    (list :path path :root root :buffer opened-buffer)))

(defun +ghostel-yazi--read-paths (output directory)
  "Read paths from Yazi OUTPUT and resolve them against DIRECTORY."
  (when (and output (file-readable-p output))
    (with-temp-buffer
      (insert-file-contents output)
      (mapcar (lambda (path)
                (+ghostel-yazi--selected-path path directory))
              (split-string (buffer-string) "\n" t)))))

(defun +ghostel-yazi--open-selection (buffer _event)
  "Open Yazi's selected files or use its final directory in BUFFER."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (let ((chooser +ghostel-yazi--chooser-file))
        (unwind-protect
            (let* ((directory (or +ghostel-yazi--launch-directory
                                  default-directory))
                   (paths (+ghostel-yazi--read-paths chooser directory))
                   (window (get-buffer-window buffer t)))
              (if +ghostel-yazi--open-folder-p
                  ;; In chooser mode Enter writes the hovered file or directory
                  ;; and exits before Yazi's normal type-specific open logic.
                  (when-let ((primary (car paths)))
                    (+open-folder/path primary window)
                    ;; Preserve marked extra files as workspace buffers.
                    (dolist (extra (cdr paths))
                      (let ((extra-buffer (find-file-noselect extra)))
                        (when (bound-and-true-p persp-mode)
                          (persp-add-buffer extra-buffer
                                            (get-current-persp) nil nil)))))
                (let ((buffers (mapcar #'find-file-noselect paths)))
                  ;; Preserve the original Yazi command: show the first chosen
                  ;; file where Yazi was and keep all marked files as buffers.
                  (when-let ((selected (car buffers)))
                    (if (window-live-p window)
                        (set-window-buffer window selected)
                      (pop-to-buffer selected)))))
          (+ghostel-yazi--cleanup)))))))

(defun +ghostel-yazi--remote-command (directory chooser)
  "Build the remote Yazi chooser command for TRAMP DIRECTORY and CHOOSER."
  (format "exec %s --chooser-file %s %s"
          (shell-quote-argument +ghostel-yazi-remote-program)
          (shell-quote-argument chooser)
          (shell-quote-argument (file-remote-p directory 'localname))))

(defun +ghostel-yazi--start (requested-directory &optional open-folder)
  "Run chooser-mode Yazi at REQUESTED-DIRECTORY in the current window.
When OPEN-FOLDER is non-nil open the chosen file/directory as a project."
  (require 'ghostel)
  (let ((directory (file-name-as-directory
                    (expand-file-name requested-directory))))
    ;; Terminal buffers can retain a stale working directory after it is moved
    ;; or deleted.  Use its nearest existing parent instead.
    (while (not (file-directory-p directory))
      (let ((parent (file-name-directory (directory-file-name directory))))
        (when (or (null parent) (equal parent directory))
          (user-error "No existing parent directory for %s"
                      requested-directory))
        (setq directory parent)))
    (unless (equal directory requested-directory)
      (message "Yazi: %s no longer exists; opening %s"
               (abbreviate-file-name requested-directory)
               (abbreviate-file-name directory)))
    (let* ((remote-prefix (file-remote-p directory))
           (remote-host (and remote-prefix
                             (file-remote-p directory 'host)))
           (remote-user (and remote-prefix
                             (file-remote-p directory 'user)))
           (remote-target (and remote-prefix
                               (if remote-user
                                   (format "%s@%s" remote-user remote-host)
                                 remote-host)))
           (output-token
            (substring
             (md5 (format "%s%s%s" (float-time) (random) directory))
             0 12))
           (remote-chooser
            (and remote-prefix
                 (format "/tmp/emacs-yazi-chooser-%d-%s"
                         (emacs-pid) output-token)))
           (chooser (if remote-prefix
                        (concat remote-prefix remote-chooser)
                      (make-temp-file "emacs-yazi-chooser-")))
           (program (if remote-prefix
                        (executable-find "ssh")
                      (executable-find "yazi")))
           (arguments
            (if remote-prefix
                (list "-tt" remote-target
                      (+ghostel-yazi--remote-command
                       directory remote-chooser))
              (list "--chooser-file" chooser ".")))
           (buffer (generate-new-buffer
                    (if remote-prefix
                        "*ghostel: yazi remote*"
                      "*ghostel: yazi*"))))
      (unless program
        (ignore-errors
          (when (file-exists-p chooser)
            (delete-file chooser)))
        (when (buffer-live-p buffer)
          (kill-buffer buffer))
        (user-error "Cannot find %s in exec-path"
                    (if remote-prefix "ssh" "yazi")))
      (when (and remote-prefix
                 (not (equal (file-remote-p directory 'method) "ssh")))
        (ignore-errors
          (when (file-exists-p chooser)
            (delete-file chooser)))
        (when (buffer-live-p buffer)
          (kill-buffer buffer))
        (user-error "Remote Yazi currently supports only TRAMP ssh paths"))
      ;; The remote terminal itself is a local SSH process.  Keep its Ghostel
      ;; buffer local while retaining the TRAMP launch directory separately.
      (with-current-buffer buffer
        (setq default-directory
              (if remote-prefix user-emacs-directory directory))
        (ghostel-mode)
        (setq-local +ghostel-yazi--chooser-file chooser)
        (setq-local +ghostel-yazi--launch-directory directory)
        (setq-local +ghostel-yazi--open-folder-p open-folder)
        (setq-local ghostel-kill-buffer-on-exit t)
        (add-hook 'ghostel-exit-functions
                  #'+ghostel-yazi--open-selection nil t)
        (add-hook 'kill-buffer-hook #'+ghostel-yazi--cleanup nil t))
      ;; Display first so `ghostel-exec' sizes the TUI to this exact window.
      (switch-to-buffer buffer)
      (condition-case err
          (ghostel-exec buffer program arguments)
        (error
         (ignore-errors
           (when (file-exists-p chooser)
             (delete-file chooser)))
         (when (buffer-live-p buffer)
           (kill-buffer buffer))
         (signal (car err) (cdr err)))))))

(defun +ghostel/yazi-here ()
  "Run local or remote Yazi here and open its selection in Emacs.

For a TRAMP directory, Yazi runs on that host over SSH and the selected remote
file opens in this local Emacs through TRAMP.  Opening a file exits Yazi and
replaces its terminal window.  Marked multi-selections all become buffers."
  (interactive)
  (+ghostel-yazi--start default-directory))

(defun +open-project/yazi ()
  "Open a project file/folder with Yazi and root Treemacs there."
  (interactive)
  (+ghostel-yazi--start default-directory t))

;; Any *ghostel* buffer shown via `display-buffer'/`pop-to-buffer' docks as a
;; 30%-tall bottom popup. :quit nil so ESC/C-g go to the terminal (not close it);
;; :ttl nil so the session persists across toggles.
;; :modeline t because Doom popups hide the modeline by default, and we want
;; the status bar (doom-modeline) here.
(after! ghostel
  (set-popup-rule! "^\\*ghostel" :size 0.3 :vslot -4 :select t :quit nil :ttl nil :modeline t))

;; Keep Treemacs's remembered width aligned with mouse and keyboard resizing so
;; toggling the sidebar does not snap it back to its original size.
(defun +treemacs-sync-width-after-resize (frame)
  "Remember the visible Treemacs width in FRAME."
  (when (frame-live-p frame)
    (when-let ((window
                (seq-find
                 (lambda (candidate)
                   (with-current-buffer (window-buffer candidate)
                     (derived-mode-p 'treemacs-mode)))
                 (window-list frame 'no-minibuf))))
      (setq treemacs-width (window-body-width window)))))

;; VS Code-style project explorer: a resizable sidebar on the left while
;; ordinary editing windows keep the remaining center/right area.
(defun +treemacs-disable-wrapping-h ()
  "Keep Treemacs rows on one line without changing global wrapping defaults."
  (when (bound-and-true-p visual-line-mode)
    (visual-line-mode -1))
  (setq-local truncate-lines t
              word-wrap nil
              auto-hscroll-mode nil))

(add-hook 'treemacs-mode-hook #'+treemacs-disable-wrapping-h)

(defvar-local +treemacs--hand-pointer-overlay nil
  "Overlay giving clickable Treemacs rows a consistent hand pointer.")

(defun +treemacs-apply-hand-pointer-h (&rest _)
  "Cover the current Treemacs buffer with a persistent hand pointer overlay."
  (when (derived-mode-p 'treemacs-mode)
    (unless (overlayp +treemacs--hand-pointer-overlay)
      ;; Rear advance keeps nodes inserted during expansion inside the overlay.
      (setq +treemacs--hand-pointer-overlay
            (make-overlay (point-min) (point-max) nil nil t))
      (overlay-put +treemacs--hand-pointer-overlay 'pointer 'hand))
    (move-overlay +treemacs--hand-pointer-overlay (point-min) (point-max))))

(add-hook 'treemacs-mode-hook #'+treemacs-apply-hand-pointer-h)
(add-hook 'treemacs-post-buffer-init-hook #'+treemacs-apply-hand-pointer-h)
(add-hook 'treemacs-post-refresh-hook #'+treemacs-apply-hand-pointer-h)

(defun +treemacs/single-click-node (event)
  "Activate the Treemacs node clicked by primary mouse EVENT.

A directory disclosure image or label toggles the directory.  A file image or
label opens the file using Treemacs's normal RET action.  Tag rows are left to
their existing bindings."
  (interactive "e")
  (when (eq (car-safe event) 'mouse-1)
    (let* ((position (event-end event))
           (window (posn-window position))
           (point (posn-point position)))
      (when (and (window-live-p window)
                 (integer-or-marker-p point))
        (select-window window)
        (when (derived-mode-p 'treemacs-mode)
          (when-let ((button (treemacs--button-in-line point)))
            (unwind-protect
                (pcase (treemacs-button-get button :state)
                  ((or 'root-node-open 'root-node-closed
                       'dir-node-open 'dir-node-closed)
                   (goto-char button)
                   (treemacs-toggle-node)
                   (treemacs--evade-image)
                   (+treemacs-apply-hand-pointer-h))
                  ((or 'file-node-open 'file-node-closed)
                   (goto-char button)
                   (treemacs-RET-action)))
              (set-marker button nil))))))))

(after! treemacs
  (define-key treemacs-mode-map [mouse-1]
              #'+treemacs/single-click-node)
  ;; A double/triple click sends a follow-up event after the first mouse-1.
  ;; Ignore it so nodes are activated exactly once.
  (define-key treemacs-mode-map [double-mouse-1] #'ignore)
  (define-key treemacs-mode-map [triple-mouse-1] #'ignore))
(after! treemacs-evil
  (evil-define-key 'treemacs treemacs-mode-map [mouse-1]
    #'+treemacs/single-click-node)
  (evil-define-key 'treemacs treemacs-mode-map [double-mouse-1] #'ignore)
  (evil-define-key 'treemacs treemacs-mode-map [triple-mouse-1] #'ignore))

(after! treemacs
  (setq treemacs-position 'left
        treemacs-width 35
        treemacs-width-is-initially-locked nil
        ;; Let `SPC w h/l' focus the tree like any other window.
        treemacs-is-never-other-window nil)
  (add-hook 'window-size-change-functions
            #'+treemacs-sync-width-after-resize)
  ;; Config reloads can occur while another perspective/frame is selected.
  ;; Normalize every existing Treemacs buffer, including currently hidden ones.
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (derived-mode-p 'treemacs-mode)
        (setq treemacs--width-is-locked nil
              window-size-fixed nil)
        (dolist (window (get-buffer-window-list buffer nil t))
          (set-window-parameter window 'no-other-window nil)
          (setq treemacs-width (window-body-width window)))))))

(defun +ghostel/local-terminal (&optional directory)
  "Open a fresh local terminal in this window.

Use DIRECTORY when provided.  Otherwise start in the current local directory,
or the Mac home directory when invoked from a remote buffer."
  (interactive)
  (let ((default-directory
         (file-name-as-directory
          (expand-file-name
           (or directory
               (if (file-remote-p default-directory)
                   (getenv "HOME")
                 default-directory))))))
    (+ghostel/new)
    (current-buffer)))

(map! :leader
      :desc "[P] Local terminal (current window)" "o t" #'+ghostel/local-terminal
      :desc "[P] Yazi here (open in Emacs)"       "o y" #'+ghostel/yazi-here
      :desc "[P] Open project with Yazi"          "o p" #'+open-project/yazi)

(provide 'config-terminal)
