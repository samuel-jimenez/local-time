(in-package #:local-time)


(defmacro defvar-unbound (variable-name documentation)
	"Like DEFVAR, but the variable will be unbound rather than getting
an initial value.  This is useful for variables which should have no
global value but might have a dynamically bound value."
	;; stolen from comp.lang.lisp article <k7727i3s.fsf@comcast.net> by
	;; "prunesquallor@comcast.net"
	`(eval-when (:load-toplevel :compile-toplevel :execute)
		(defvar ,variable-name)
		(setf (documentation ',variable-name 'variable)
						,documentation)))

(defvar-unbound *stream*
	"Bound to the stream which is read from while parsing a string.")

(defvar *previous-readtables* nil
	"A stack which holds the previous readtables that have been pushed
here by ENABLE-LOCAL-TIME-SYNTAX.")


(defmacro read-char* ()
	"Convenience macro because we always read from the same string with
the same arguments."
	`(read-char *stream* t nil t))

(declaim (inline make-collector))
(defun make-collector ()
	"Create an empty string which can be extended by
VECTOR-PUSH-EXTEND."
				(make-array 0
					:element-type 'character
					:fill-pointer t
					:adjustable t))

(defun local-time-reader (*stream* char arg &key (recursive-p t))
	"The actual reader function for the 'sub-character' #\@."
	(let ((collector (make-collector))
			result)
		(block main-loop ;; we need this name so we can leave the LOOP below
			(flet (
				(compute-result ()
					(push (parse-integer collector) result)
					(setf collector (make-collector))))
			(loop
				(let* ((next-char (read-char*)))
							(case next-char
												((#\Z)
													(setf collector (concatenate 'string collector "000"))
													;because encode-timestamp takes input in ns, but displays output in μs
													;dirty hack, the right thing would be to read this in as a real number,
														;maybe (parse-number) https://www.cliki.net/PARSE-NUMBER
													;then convert to ns (*  1e9)
													(compute-result)
													(return-from main-loop))
												((#\- #\T #\: #\.)
													(compute-result))
												(t
													(vector-push-extend next-char collector)))))))
	(apply #'encode-timestamp result)))

(defun %enable-local-time-syntax (&key (modify-*readtable* T))
	"Internal function used to enable reader syntax and store current
readtable on stack."
	(unless modify-*readtable*
		(push *readtable*
					*previous-readtables*)
		(setq *readtable* (copy-readtable)))
	(set-dispatch-macro-character #\# #\@ #'local-time-reader)
	(values))

(defun %disable-local-time-syntax ()
	"Internal function used to restore previous readtable."
	(if *previous-readtables*
		(setq *readtable* (pop *previous-readtables*))
		(setq *readtable* (copy-readtable nil)))
	(values))

(defmacro enable-local-time-syntax (&rest %enable-local-time-syntax-args)
	"Enable CL-LOCAL-TIME reader syntax."
	`(eval-when (:compile-toplevel :load-toplevel :execute)
		(%enable-local-time-syntax ,@%enable-local-time-syntax-args)))

(defmacro disable-local-time-syntax ()
	"Restore readtable which was active before last call to
ENABLE-LOCAL-TIME-SYNTAX. If there was no such call, the standard
readtable is used."
	`(eval-when (:compile-toplevel :load-toplevel :execute)
		(%disable-local-time-syntax)))


