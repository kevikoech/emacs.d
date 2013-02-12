;; turn off viz bell that starter-kit turns on.
(setq visible-bell nil)

;; from http://blog.tuxicity.se/elisp/emacs/2010/03/26/rename-file-and-buffer-in-emacs.html
(defun rename-file-and-buffer ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (message "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: " filename)))
        (cond ((get-buffer new-name)
               (message "A buffer named '%s' already exists!" new-name))
              (t
               (rename-file name new-name 1)
               (rename-buffer new-name)
               (set-visited-file-name new-name)
               (set-buffer-modified-p nil)))))))

(global-set-key (kbd "C-c r") 'rename-file-and-buffer)


;; Get rid of annoying warning about needing to make directory
(add-hook 'before-save-hook
          '(lambda ()
             (or (file-exists-p (file-name-directory buffer-file-name))
                 (make-directory (file-name-directory buffer-file-name) t))))


;; From http://trey-jackson.blogspot.com/2009/06/emacs-tip-31-kill-other-buffers-of-this.html
(global-set-key (kbd "C-x K") 'kill-other-buffers-of-this-file-name)
(defun kill-other-buffers-of-this-file-name (&optional buffer)
  "Kill all other buffers visiting files of the same base name."
  (interactive "bBuffer to make unique: ")
  (setq buffer (get-buffer buffer))
  (cond ((buffer-file-name buffer)
         (let ((name (file-name-nondirectory (buffer-file-name buffer))))
           (loop for ob in (buffer-list)
                 do (if (and (not (eq ob buffer))
                             (buffer-file-name ob)
                             (let ((ob-file-name (file-name-nondirectory (buffer-file-name ob))))
                               (or (equal ob-file-name name)
                                   (string-match (concat name "\\.~.*~$") ob-file-name))) )
                        (kill-buffer ob)))))
        (default (message "This buffer has no file name."))))


;; Sudo tools

(setq tramp-default-method "ssh")
(defun sudo-edit (&optional arg)
  (interactive "p")
  (if arg
      (find-file (concat "/sudo:root@localhost:" (ido-read-file-name "File: ")))
    (find-alternate-file (concat "/sudo:root@localhost:" buffer-file-name))))

;; It appears I need to allow ssh into localhost and with root?!?
(defun sudo-edit-current-file ()
  (interactive)
  (find-alternate-file (concat "/sudo:root@localhost:" (buffer-file-name (current-buffer)))))

(global-set-key (kbd "C-c C-r") 'sudo-edit-current-file)

;; Fix indentation for buffer
(defun fix-read-only-indentation ()
  "Fix the indentation of a read only file.  For now you have to
remember to not save this change if you have write access to the
file"
  (interactive)
  (toggle-read-only)
  (indent-region (point-min) (point-max)))



;;http://blog.plover.com/prog/revert-all.html
;; Could rewrite this to be more functional
(defun revert-all-buffers ()
  "Refreshes all open buffers from their respective files"
  (interactive)
  (let* ((list (buffer-list))
         (buffer (car list)))
    (while buffer
      (when (and (buffer-file-name buffer)
                 (not (buffer-modified-p buffer)))
        (set-buffer buffer)
        (revert-buffer t t t))
      (setq list (cdr list))
      (setq buffer (car list))))
  (message "Refreshed open files"))

;;http://blog.tuxicity.se/elisp/emacs/2010/11/16/delete-file-and-buffer-in-emacs.html
(defun delete-this-buffer-and-file ()
  "Removes file connected to current buffer and kills buffer."
  (interactive)
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        (name (buffer-name)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (when (yes-or-no-p "Are you sure you want to remove this file? ")
        (delete-file filename)
        (kill-buffer buffer)
        (message "File '%s' successfully removed" filename)))))


;;http://www.emacswiki.org/emacs/CopyAndPaste
(defun path-to-clipboard ()
  "Copy the current file's path to the clipboard.

  If the current buffer has no file, copy the buffer's default directory."
  (interactive)
  (let ((path (expand-file-name (or (buffer-file-name) default-directory))))
    (set-clipboard-contents-from-string path)
    (message "%s" path)))

(defun set-clipboard-contents-from-string (str)
  "Copy the value of string STR into the clipboard."
  (let ((x-select-enable-clipboard t))
    (x-select-text str)))


(defun colorize-rails-log ()
  "Setup the ansi log color"
  (interactive)
  ;; prevent running this on non log files!
  (if (string-match ".log$" buffer-file-name)
      (ansi-color-apply-on-region (point-min) (point-max))))



;;; https://gist.github.com/1034475
;;; Prevent acidental iconify/suspend.
(when (window-system)
  (defun smart-iconify-or-deiconify-frame ()
    "Present a confirmation before suspending/iconifying."
    (interactive)
    (if (yes-or-no-p (format "Are you sure you want to iconify/deiconify Emacs? "))
        (iconify-frame)))
  ;; Rebinding C-z to the new function.
  (global-set-key (kbd "C-z") 'smart-iconify-or-deiconify-frame)
  ;; Rebinding C-x C-z to the new function. Overrides suspend-frame.
  (global-set-key (kbd "C-x C-z") 'smart-iconify-or-deiconify-frame))

;;; Auto revert any files that have changed since I viewed it.
;;; Warns when I've made changes and the backend has changed
(global-auto-revert-mode t)

(global-auto-revert-mode nil)


;; http://stackoverflow.com/questions/2550474/is-it-possible-to-auto-regenerate-and-load-tags-table-in-emacs-rather-than-having
(setq tags-revert-without-query t)



(defun cleanup-timers-on-killed-buffers ()
  (interactive)
  (mapc (lambda (timer) (cancel-timer timer))
        (remove-if-not
         (lambda (timer) (string-equal "(#<killed buffer>)" (prin1-to-string (aref timer 6))))
         timer-list)))

(run-with-idle-timer 60 t 'cleanup-timers-on-killed-buffers)


;; From http://emacs-fu.blogspot.jp/2010/03/cleaning-up-buffers-automatically.html
(require 'midnight)




(provide 'init-my-defaults)