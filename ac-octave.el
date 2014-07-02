;;; ac-octave.el --- An auto-complete source for Octave

;; Copyright (c) 2012 coldnew <coldnew.tw@gmail.com>
;;
;; Author: coldnew <coldnew.tw@gmail.com>
;; Keywords: Octave, auto-complete, completion
;; Package-Requires: ((auto-complete "1.4.0"))
;; X-URL: http://www.emacswiki.org/cgi-bin/wiki/download/ac-octave.el
;; Version: 0.2

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Change Log:
;;
;; 0.3: fix for working on emacs 24
;; 0.2: remove dulpicates completions.
;; 0.1: ac-octave.el 0.1 released.
;;

;;; Install
;; Put this file into load-path'ed directory, and byte compile it if
;; desired. And put the following expression into your ~/.emacs.
;;
;; (require 'ac-octave)
;; (defun ac-octave-mode-setup ()
;; (setq ac-sources '(ac-source-octave)))
;; (add-hook 'octave-mode-hook
;; '(lambda () (ac-octave-mode-setup)))
;;

;;; NOTE:
;; If you can't use ac-octave in octave-mode,
;; check whether auto-complete-mode is running or not.

;;; Code:

(eval-when-compile (require 'cl))
(require 'auto-complete)

;; octave-inf.el merge to octave.el since emacs version 24
;; see issue #6: Error when require octave-inf
(if (>= emacs-major-version 24)
    (require 'octave)
  ;; for emacs 23 or below
  (require 'octave-inf))

;;;;##########################################################################
;;;; User Options, Variables
;;;;##########################################################################


;;;;;;;; faces
(defface ac-octave-candidate-face
  '((t (:inherit ac-candidate-face)))
  "face for octave candidate"
  :group 'auto-complete)

(defface ac-octave-selection-face
  '((t (:inherit ac-selection-face)))
  "face for the octave selected candidate."
  :group 'auto-complete)


;;;;;;;; local variables

(defvar ac-octave-complete-list nil)

;;;;;;;; functions

(defun ac-octave-init ()
  "Start inferior-octave in background before use ac-octave."
  (run-octave t)
  ;; Update current directory of inferior octave whenever completion starts.
  ;; This allows local functions to be completed when user switches
  ;; between octave buffers that are located in different directories.
  (when (file-readable-p default-directory)
    (inferior-octave-send-list-and-digest
     (list (concat "cd " default-directory ";\n")))))

(defun ac-octave-do-complete ()
  (interactive)
  (let* ((end (point))
	 (command (save-excursion
		   (skip-syntax-backward "w_")
		   (buffer-substring-no-properties (point) end))))

    (inferior-octave-send-list-and-digest
     (list (concat "completion_matches (\"" command "\");\n")))

    (setq ac-octave-complete-list
	  (sort inferior-octave-output-list 'string-lessp))

    ;; remove dulpicates lists
    (delete-dups ac-octave-complete-list)))

(defun ac-octave-candidate ()
  (let (table)
    (ac-octave-do-complete)
    (dolist (s ac-octave-complete-list)
	    (push s table))
    table))

(defun ac-octave-documentation (symbol)
  (with-local-quit
    (ignore-errors
      (inferior-octave-send-list-and-digest
       (list (concat "help " symbol ";\n")))
      (mapconcat #'identity
                 inferior-octave-output-list
                 "\n"))))

(ac-define-source octave
		  '((candidates . ac-octave-candidate)
                    (document . ac-octave-documentation)
		    (candidate-face . ac-octave-candidate-face)
		    (selection-face . ac-octave-selection-face)
		    (init . ac-octave-init)
		    (requires . 0)
		    (cache)
		    (symbol . "f")))

(provide 'ac-octave)
;;; ac-octave.el ends here.
