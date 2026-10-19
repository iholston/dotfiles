;;; workspaces.el --- Workspace selection, ordering, and navigation -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'seq)
(require 'subr-x)

;;; ─── Workspace TAB TAB / TAB . mapping ──────────────────────────────────
;; `SPC TAB TAB' just *displays* the workspace list in the echo area (a quick
;; peek), while `SPC TAB .' and `SPC SPC' open this numbered picker. Pressing a
;; displayed digit switches immediately; typing any non-digit keeps normal
;; completion-by-name behavior. Vertico sorting stays disabled here so the
;; numbers always match Doom's order in `persp-names-cache'.
(defvar +workspace--quick-selection nil
  "One-based workspace number selected from the active completion picker.")

(defun +workspace--numbered-candidates (names)
  "Return an alist displaying NAMES with stable one-based number labels."
  (cl-loop for name in names
           for index from 1
           collect (cons (format "[%d] %s" index name) name)))

(defun +workspace--quick-select (index)
  "Select one-based workspace INDEX and close the active minibuffer."
  (setq +workspace--quick-selection index)
  (exit-minibuffer))

(defun +workspace--quick-select-or-insert (index)
  "Select workspace INDEX on empty input; otherwise insert the typed digit."
  (if (string-empty-p (minibuffer-contents-no-properties))
      (+workspace--quick-select index)
    ;; Preserve `last-command-event' from the digit key that invoked the private
    ;; minibuffer binding, so names such as `Temp 2' type normally.
    (self-insert-command 1)))

(defun +workspace--install-quick-keys (count)
  "Temporarily bind digits for immediate selection among COUNT workspaces."
  ;; Vertico installs its shared `vertico-map' as the minibuffer's local map.
  ;; Never mutate it directly: leaked digit bindings would affect every later
  ;; completion command (including `SPC n f').  This private map is discarded
  ;; when the workspace-picker minibuffer exits.
  (use-local-map (copy-keymap (current-local-map)))
  (dotimes (offset (min count 9))
    (let ((index (1+ offset)))
      ;; Insert INDEX into the function form: config.el uses dynamic binding,
      ;; so a closure over the loop variable would not survive minibuffer input.
      (local-set-key (kbd (number-to-string index))
                     `(lambda ()
                        (interactive)
                        (+workspace--quick-select-or-insert ,index)))))
  (when (>= count 10)
    (local-set-key (kbd "0")
                   (lambda ()
                     (interactive)
                     (+workspace--quick-select-or-insert 10)))))

(defun +workspace--preselect-candidate (index)
  "Preselect zero-based workspace candidate INDEX in the active Vertico UI."
  (when (and index
             (boundp 'vertico--index)
             (fboundp 'vertico--update)
             (fboundp 'vertico--goto))
    ;; Populate the stable, unsorted candidate list before moving.  `--goto'
    ;; locks the candidate by value so Vertico's next update preserves it.
    (vertico--update)
    (vertico--goto index)))

;;; Allow Vertico candidates to be clicked and scrolled.
(after! vertico
  (require 'vertico-mouse)
  (vertico-mouse-mode 1))

(defun +workspace/switch-to-ordered (workspace)
  "Switch to WORKSPACE through an ordered, numbered completion picker.
The current workspace starts highlighted.  With empty input, digits 1–9 select
immediately (0 selects workspace 10 when present); once name input has started,
digits insert normally.  Other input filters by name, and an unmatched
non-empty name creates and enters a new workspace."
  (interactive
   (list
    (let* ((names (+workspace-list-names))
           ;; Prevent nerd-icons-completion's nil-category arrow from being
           ;; prepended to these already-numbered workspace labels.
           (completion-extra-properties '(:category workspace))
           (current-index
            (cl-position (+workspace-current-name) names :test #'string=))
           (candidates (+workspace--numbered-candidates names))
           (+workspace--quick-selection nil)
           (vertico-sort-function nil)
           (choice
            (minibuffer-with-setup-hook
                (lambda ()
                  (+workspace--install-quick-keys (length names))
                  (+workspace--preselect-candidate current-index))
              (completing-read
               "Workspace (number, name, or new name): " candidates nil nil)))
           (workspace
            (or (and +workspace--quick-selection
                     (nth (1- +workspace--quick-selection) names))
                (cdr (assoc choice candidates))
                (string-trim choice))))
      (when (string-empty-p workspace)
        (user-error "Workspace name cannot be empty"))
      workspace)))
  (+workspace/switch-to workspace))

(defun +workspace--set-visible-order (ordered)
  "Apply ORDERED names while preserving hidden entries in the perspective cache."
  (let ((visible (+workspace-list-names)))
    (unless (= (length ordered) (length visible))
      (error "Workspace order length mismatch"))
    (unless (equal (sort (copy-sequence ordered) #'string<)
                   (sort (copy-sequence visible) #'string<))
      (error "Workspace order must contain the same visible names"))
    (let ((queue (copy-sequence ordered)))
      (setq persp-names-cache
            (mapcar (lambda (name)
                      (if (member name visible)
                          (pop queue)
                        name))
                    persp-names-cache))
      ;; Normally every visible workspace already has a cache slot.  Append any
      ;; remainder defensively in case persp-mode's cache was incomplete.
      (when queue
        (setq persp-names-cache (append persp-names-cache queue))))
    persp-names-cache))

(defun +workspace--move-name-to-position (name position)
  "Move workspace NAME to one-based POSITION and return the new visible order."
  (let* ((names (+workspace-list-names))
         (count (length names)))
    (unless (member name names)
      (user-error "No workspace named %s" name))
    (unless (and (integerp position) (<= 1 position count))
      (user-error "Position must be between 1 and %d" count))
    (let* ((without (delete name (copy-sequence names)))
           (index (1- position))
           (ordered (append (seq-take without index)
                            (list name)
                            (seq-drop without index))))
      (+workspace--set-visible-order ordered)
      ordered)))

(defun +workspace/rename-plain (new-name)
  "Rename the current workspace to NEW-NAME using a plain text prompt."
  (interactive
   (list (read-string
          (format "Rename workspace '%s' to: " (+workspace-current-name)))))
  (setq new-name (string-trim new-name))
  (when (string-empty-p new-name)
    (user-error "Workspace name cannot be empty"))
  (let* ((old-name (+workspace-current-name))
         (old-position
          (1+ (or (cl-position old-name (+workspace-list-names) :test #'string=)
                  (user-error "Current workspace is missing from the order")))))
    (+workspace/rename new-name)
    ;; `persp-rename' removes the old cache entry and appends the new one.  Only
    ;; restore the position after a successful rename, not after a caught error.
    (when (and (not (+workspace-exists-p old-name))
               (+workspace-exists-p new-name)
               (equal (+workspace-current-name) new-name))
      (+workspace--move-name-to-position new-name old-position))))

(defun +workspace/move-to-position (position)
  "Move the current workspace directly to one-based POSITION."
  (interactive
   (let* ((names (+workspace-list-names))
          (current (+workspace-current-name))
          (current-position
           (1+ (or (cl-position current names :test #'string=) 0))))
     (list (read-number
            (format "Move workspace '%s' to position (1-%d): "
                    current (length names))
            current-position))))
  (let ((name (+workspace-current-name)))
    (+workspace--move-name-to-position name position)
    (+workspace-message (format "Moved '%s' to position %d" name position)
                        'success)))

(defun +workspace--remember-renamed-h (_persp old-name new-name)
  "Update remembered and frame-associated workspace names after a rename."
  (when (equal persp-last-persp-name old-name)
    (setq persp-last-persp-name new-name))
  (when (equal +workspace--last old-name)
    (setq +workspace--last new-name))
  (dolist (frame (frame-list))
    (when (equal (frame-parameter frame 'workspace) old-name)
      (set-frame-parameter frame 'workspace new-name))))

(after! persp-mode
  (add-hook 'persp-renamed-functions #'+workspace--remember-renamed-h))

(map! :leader
      :desc "[P] Display workspaces"      "TAB TAB" #'+workspace/display
      :desc "[P] Switch to workspace..." "TAB ."   #'+workspace/switch-to-ordered
      :desc "[P] Rename workspace"       "TAB r"   #'+workspace/rename-plain
      :desc "[P] Move to position"       "TAB m"   #'+workspace/move-to-position
      ;; Mirror `SPC TAB .' onto `SPC SPC' (default projectile-find-file, unused).
      :desc "[P] Switch to workspace..." "SPC"     #'+workspace/switch-to-ordered)


;;; ─── Workspace nav + reordering: SPC TAB h/l/H/L ────────────────────────
;; h/l switch left/right (aliases for [ and ]); H/L MOVE the current workspace
;; left/right by swapping it with its neighbor (e.g. workspace 4 ⇄ 3). Doom keeps
;; workspace order in `persp-names-cache' (numbering/cycling read from it), so we
;; reorder that list in place.
(defun +workspace--swap (direction)
  "Move the current workspace one neighbor in DIRECTION (-1 left, +1 right)."
  (let* ((names (+workspace-list-names))
         (current (+workspace-current-name))
         (index (cl-position current names :test #'string=)))
    (unless index
      (user-error "Not in a workspace"))
    (let ((target (+ index direction)))
      (unless (and (>= target 0) (< target (length names)))
        (user-error "No workspace to the %s" (if (< direction 0) "left" "right")))
      (+workspace--move-name-to-position current (1+ target))
      (+workspace/display))))

(defun +workspace/swap-left ()
  "Move the current workspace one position to the left."
  (interactive) (+workspace--swap -1))

(defun +workspace/swap-right ()
  "Move the current workspace one position to the right."
  (interactive) (+workspace--swap +1))

(defun +workspace/mouse-menu (event)
  "Pop up a menu of workspaces at the mouse and switch to the chosen one.
Bound to a click on the workspace name in the modeline."
  (interactive "e")
  (let* ((names   (+workspace-list-names))
         (current (+workspace-current-name))
         (menu    (list "Workspaces"
                        (cons "Switch to workspace"
                              (mapcar (lambda (n)
                                        (cons (concat (if (string= n current) "● " "  ") n)
                                              n))
                                      names))))
         (choice  (x-popup-menu event menu)))
    (when (and choice (not (string= choice current)))
      (+workspace-switch choice)
      (+workspace/display))))

(map! :leader
      :desc "[P] Switch workspace left"   "TAB h" #'+workspace/switch-left
      :desc "[P] Switch workspace right"  "TAB l" #'+workspace/switch-right
      :desc "[P] Move workspace left"     "TAB H" #'+workspace/swap-left
      :desc "[P] Move workspace right"    "TAB L" #'+workspace/swap-right)

(provide 'config-workspaces)
