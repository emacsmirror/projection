;;; projection-core-type.el --- Project type definition for `projection' -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Mohsin Kaleem

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Defines a class for project-types that will be re-used across projection.

;;; Code:

(require 'project)
(require 'eieio)
(eval-when-compile (require 'subr-x))

(defclass projection-type ()
  ((name
    :initarg :name
    :custom symbol
    :reader projection-type--name
    :documentation "Identifier for the current project type.
This should be unique within the body of the variable `projection-project-types'.
A special name of default is accepted when no specialised project type is applicable.")
   (predicate
    :initarg :predicate
    :custom (choice
             (const t :tag "Always supported")
             (function :tag "Predicate function")
             (string :tag "Marker file for project")
             (repeat (string :tag "Marker files for project")))
    :documentation "Predicate used to assert whether the current project matches this project type.
Predicate can be a string matching a file-name accessible from the root of the
project or for more complicated project types it should be a function returning a
boolean. You can also supply a list of either of these and if a project matches any
of them then PROJECT will be matched.")
   ;; Compilation commands
   (configure
    :initarg :configure
    :initform nil
    :custom (choice
             (const nil :tag "Project does not support configure.")
             (string :tag "Shell command to invoke.")
             (function :tag "Either a command or a function returning a valid command type."))
    :documentation "Compilation ommand used to configure this project.
When nil the project is interpreted as not supporting this command type. When a
string that string will be passed to `compile' as a shell command. When a function
then the behaviour depends on the type of function. If the function is interactive
(`commandp') it will be called interactively as a command. Otherwise the function
will be called and the result should be one of the other supported command types.")
   (build
    :initarg :build
    :initform nil
    :custom (choice
             (const nil :tag "Project does not support build.")
             (string :tag "Shell command to invoke.")
             (function :tag "Either a command or a function returning a valid command type."))
    :documentation "Compilation command used to build this project.
This is of the same type and semantics as the configure slot.")
   (test
    :initarg :test
    :initform nil
    :custom (choice
             (const nil :tag "Project does not support test.")
             (string :tag "Shell command to invoke.")
             (function :tag "Either a command or a function returning a valid command type."))
    :documentation "Command used to test project.
This is of the same type and semantics as the configure slot.")
   (run
    :initarg :run
    :initform nil
    :custom (choice
             (const nil :tag "Project does not support run.")
             (string :tag "Shell command to invoke.")
             (function :tag "Either a command or a function returning a valid command type."))
    :documentation "Command used to run project.
This is of the same type and semantics as the configure slot.")
   (package
    :initarg :package
    :initform nil
    :custom (choice
             (const nil :tag "Project does not support package.")
             (string :tag "Shell command to invoke.")
             (function :tag "Either a command or a function returning a valid command type."))
    :documentation "Command used to package project.
This is of the same type and semantics as the configure slot.")
   (install
    :initarg :install
    :initform nil
    :custom (choice
             (const nil :tag "Project does not support install.")
             (string :tag "Shell command to invoke.")
             (function :tag "Either a command or a function returning a valid command type."))
    :documentation "Command used to install project.
This is of the same type and semantics as the configure slot.")
   ;; File navigation
   (src-dir  :initarg :src-dir  :initform nil :documentation "Currently unused.")
   (test-dir :initarg :test-dir :initform nil :documentation "Currently unused.")
   (test-prefix
    :initarg :test-prefix
    :initform nil
    :custom (choice
             (string :tag "Test file prefix")
             (repeat (string :tag "Test file prefixes")))
    :documentation "Possible prefixes for a file to treat as a test file.
For example foo.cpp could have a related test at test_foo.cpp file with the prefix
being test_.")
   (test-suffix
    :initarg :test-suffix
    :initform nil
    :custom (choice
             (string :tag "Test file prefix")
             (repeat (string :tag "Test file prefixes")))
    :documentation "Possible suffixes for a file to treat as a test file.
For example foo.cpp could have a related test foo_test.cpp file with the suffix being
_test.")
   ;; Multi compile
   (compile-multi-targets
    :initarg :compile-multi-targets
    :initform nil
    :custom '(choice
              function
              (list (repeat function)))
    :documentation "Supported `compile-multi' targets for the current project type.
This is only used with the optional `projection-multi' package. The value is any action
supported by `compile-multi-config'."))
  "Base class for a supported project type in `projection'.")

(cl-defmethod initialize-instance :after ((obj projection-type) &rest _args)
  "Initialise a new projection type object."
  (unless (slot-boundp obj :name)
    (error "Must define the :name slot for a `projection-type' object"))
  (when (slot-boundp obj 'test-prefix)
    (oset obj test-prefix (ensure-list (oref obj test-prefix))))
  (when (slot-boundp obj 'test-suffix)
    (oset obj test-suffix (ensure-list (oref obj test-suffix)))))

(defcustom projection-project-types nil
  "List of defined project types in order of precedence."
  :group 'projection
  :type '(list (repeat projection-type)))

(defcustom projection-default-type
  (projection-type
   :name    'default
   :build   "make"
   :test    "make test"
   :run     "make run"
   :install "make install")
  "Default project type.
Used when no other registered type matches the current project."
  :group 'projection
  :type '(optional projection-type))

(defun projection--default-type-p (project-type)
  "Assert whether PROJECT-TYPE is the default project type."
  (or (not project-type)
      (eq (oref project-type name) 'default)))



(cl-defmethod projection--project-info (project (_project-type (eql t)))
  "Determine an alist of configurations for the PROJECT-TYPE in PROJECT."
  ;; The default list just contains the project directory.
  `(("Project dir" . ,(project-root project))))

(provide 'projection-core-type)

;;; projection-core-type.el ends here
