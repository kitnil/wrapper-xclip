;;; guix.scm --- Guix package for Emacs-Guix

;; Copyright © 2018 Oleg Pykhalov <go.wigust@gmail.com>

;; This file is part of Emacs-Guix.

;; Emacs-Guix is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Emacs-Guix is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Emacs-Guix.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file contains Guix package for development version of
;; wrapper-xclip.  To build or install, run:
;;
;;   guix build --file=guix.scm
;;   guix package --install-from-file=guix.scm

;;; Code:

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (guix build utils)
             (guix gexp)
             (guix git-download)
             (guix packages)
             (gnu packages bash)
             (gnu packages xdisorg)
             (guix build-system trivial)
             ((guix licenses) #:prefix license:))

(define %source-dir (dirname (current-filename)))

(define (git-output . args)
  "Execute 'git ARGS ...' command and return its output without trailing
newspace."
  (with-directory-excursion %source-dir
    (let* ((port   (apply open-pipe* OPEN_READ "git" args))
           (output (read-string port)))
      (close-port port)
      (string-trim-right output #\newline))))

(define (current-commit)
  (git-output "log" "-n" "1" "--pretty=format:%H"))

(define wrapper-xclip
  (let ((commit (current-commit)))
    (package
      (name "wrapper-xclip")
      (version (string-append "0.1" "-" (string-take commit 7)))
      (source (local-file %source-dir
                          #:recursive? #t
                          #:select? (git-predicate %source-dir)))
      (build-system trivial-build-system)
      (arguments
       '(#:modules
         ((guix build utils))
         #:builder
         (begin
           (use-modules (guix build utils))
           (setenv "PATH"
                   (string-append
                    (assoc-ref %build-inputs "bash") "/bin" ":"
                    (assoc-ref %build-inputs "xclip") "/bin"))
           (copy-recursively (assoc-ref %build-inputs "source") ".")
           (for-each (lambda (file)
                       (substitute* file
                         (("/bin/sh") (which "bash"))
                         (("@XCLIP_BIN@") (which "xclip")))
                       (install-file file
                                     (string-append %output "/bin")))
                     '("xcopy" "xpaste")))))
      (inputs
       `(("bash" ,bash)
         ("xclip" ,xclip)))
      (synopsis "Wrapper for xclip")
      (description "This package provides wrapper for @code{xclip}.")
      (home-page #f)
      (license license:gpl3+))))

wrapper-xclip

;;; guix.scm ends here
