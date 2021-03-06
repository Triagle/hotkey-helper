(require-extension shell fmt args)
(use shell fmt args)
(declare (uses parse))

(define opts
  (list (args:make-option (e execute)
                          (required: "HOTKEY")
                          "Execute command for HOTKEY")
        (args:make-option (p print)
                          #:none
                          "Print hotkeys")
        (args:make-option (f file)
                          (required: "NAME")
                          "Parse file NAME")
        (args:make-option (h help)
                          #:none
                          "Display this text"
                          (usage))))

(define (usage)
 (with-output-to-port (current-error-port)
   (lambda ()
     (print "Usage: "
            (car (argv))
            " [options...]")
     (newline)
     (print (args:usage opts))))
 (exit 1))

(define (format-output hotkeys)
  (fmt #t (tabular
           (dsp (string-join (map cadr hotkeys) "\n"))
           " - "
           (dsp (string-join (map car hotkeys) "\n")))))

(define (sxhkd-default-config)
  (string-concatenate (list (get-environment-variable "HOME")
                            "/.config/sxhkd/sxhkdrc")))

(define (pad-list list len)
  (if (>= (length list) len)
      list
      (append list (make-list (- len (length list))
                              (car list)))))

(define (process-hotkey hotkey)
  (let ((command (car hotkey))
        (documentation (cadr hotkey)))
    (zip (pad-list command (length documentation))
         (pad-list documentation (length command)))))

(define (process-hotkeys hotkeys)
  (foldl append '() (map process-hotkey hotkeys)))

(define (execute-hotkey hotkey)
  (run ,(car hotkey)))

(define (start args)
  (receive (options operands) (args:parse args opts)
    (let ((hotkeys (parse-file (if (alist-ref 'file options)
                                    (alist-ref 'file options)
                                    (sxhkd-default-config)))))
      (cond
       ((alist-ref 'print options) (format-output (process-hotkeys hotkeys)))
       ((alist-ref 'execute options) (execute-hotkey (find-hotkey hotkeys
                                                                  (string-trim-both (alist-ref 'execute options)))))
       (#t (usage))))))

(start (command-line-arguments))
