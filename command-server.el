;;; command-server.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022
;;
;; Version: 0.0.1
;; Keywords: comm lisp
;; Homepage: https://github.com/dyamito/command-server
;; Package-Requires: ((emacs "27.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:
;;;
(defcustom command-server-suffix "emacs-command-server"
  "The temporary directory name to use for storing requests and responses."
  :type '(string)
  :group 'command-server)

(defcustom command-server-command-handlers
  '(("eval" . command-server--handler-eval))
  "A list of handlers for command-server commands."
  :type '(alist :key-type string :value-type symbol)
  :group 'command-server)

(global-set-key (kbd "<C-f17>") 'command-server-run-command)

;; make sure that command-server-directory is created before we try to write to it
;(mkdir (command-server-directory) t)

;; (with-eval-after-load 'isearch-mode
;;   (define-key isearch-mode-map (kbd "<C-f17>") 'command-server-run-command))

(defun command-server--handler-eval (command-uuid wait-for-finish args)
  "A command server handler for the eval command.

COMMAND-UUID is the corresponding UUID necessary for writing a response.

WAIT-FOR-FINISH is used to determine whether or not the handler should
block until the code is executed.

ARGS contains all arguments necessary for the handler."
  (let* ((code-string (elt args 0))
         (res (read-from-string code-string))
         (code (car res)))
    (if (not (eql (cdr res) (length code-string)))
        (error "Malformed eval expression in command-server request")
      (if wait-for-finish
          (progn
            (command-server--write-response command-uuid nil nil (eval code)))
        (command-server--write-response command-uuid)
        (eval code)))))

(defun command-server-directory ()
  "Return the fully qualified directory for command server storage."
  ;; TODO: on windows suffix should be empty, I think, assuming that
  ;; (temporary-file-directory) returns the appropriate user-specific temp dir
  ;; on windows.
  (let ((suffix (format "-%s" (user-real-uid))))
    (expand-file-name
     (concat command-server-suffix suffix)
     (temporary-file-directory))))

(defun command-server--write-response (uuid &optional warnings error return-value)
  "Write a response for command request with uuid UUID.

WARNINGS is a vector of warnings to be returned to the client.

ERROR is an error message to be returned to the client.

RETURN-VALUE is a value to be returned to the client."
  (mkdir (command-server-directory) t)
  (with-temp-file (expand-file-name "response.json" (command-server-directory))
    (json-insert `(:uuid ,uuid
                   :warnings ,(or warnings [])
                   :error ,(or error :null)
                   :returnValue ,(or return-value :null)))
    ;; the trailing newline is used by clients to determine that the file is
    ;; complete, to prevent trying to parse an incomplete json blob.
    (insert "\n")))

(defun command-server--read-request ()
  "Attempt to read a command server request."
  (let* ((request-path (expand-file-name "request.json" (command-server-directory))))
    (if (not (file-exists-p request-path))
        (error "Can't find a command server request at %s" request-path)
      (with-temp-buffer
        (insert-file-contents-literally request-path)
        (json-parse-buffer)))))

;;;###autoload
(defun command-server-run-command ()
  "Trigger command execution."
  (interactive)
  (let* ((request (command-server--read-request))
         (command-id (gethash "commandId" request))
         (args (gethash "args" request))
         (wait-for-finish (eq (gethash "waitForFinish" request) t))
         ;; TODO return output
         ;; (return-command-output (gethash "returnCommandOutput" request))
         (uuid (gethash "uuid" request)))
    (let ((handler (cdr (assoc command-id command-server-command-handlers))))
      (if (not handler)
          ;; TODO: write an error response.
          (error "Unrecognized command id %S" command-id)
        (funcall handler uuid wait-for-finish args)))))

(provide 'command-server)
;;; command-server.el ends here
