#|
 This file is a part of trial
 (c) 2016 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.fraf.trial)
(in-readtable :qtools)

(defvar *main-window* NIL)

(defun make-gl-format ()
  (let ((format (q+:make-qglformat)))
    (setf (q+:alpha format) T)
    (setf (q+:depth format) T)
    (setf (q+:direct-rendering format) T)
    (setf (q+:double-buffer format) T)
    (setf (q+:rgba format) T)
    (setf (q+:stencil format) T)
    format))

(define-widget main (QGLWidget)
  ((scene :initform (make-instance 'scene) :accessor scene :finalized T))
  (:constructor (make-gl-format)))

(define-initializer (main setup)
  (v:info :trial "GENESIS")
  (setf *main-window* main)
  (q+:resize main 1024 768)
  (setf (q+:auto-buffer-swap main) NIL)
  (setf (q+:window-title main) "Trial"))

(define-finalizer (main teardown)
  (v:info :trial "RAPTURE"))

(define-subwidget (main background) (q+:make-qcolor 0 0 0))

(define-override (main "initializeGL" initialize-gl) ()
  (q+:qgl-clear-color main background)
  (gl:enable :depth-test :blend :cull-face :texture-2d)
  (gl:depth-mask T)
  (gl:depth-func :lequal)
  (gl:clear-depth 1.0)
  (gl:blend-func :src-alpha :one-minus-src-alpha)
  (gl:shade-model :smooth)
  (gl:front-face :ccw)
  (gl:cull-face :back)
  (gl:hint :perspective-correction-hint :nicest)
  (setup-scene scene))

(defclass resize (event)
  ((width :initarg :width :reader width)
   (height :initarg :height :reader height)))

(define-override (main "resizeGL" resize-gl) (width height)
  (issue scene 'resize :width width :height height))

(defmethod resize ((main main) width height)
  (gl:matrix-mode :projection)
  (gl:load-identity)
  (set-perspective 45 (/ width (max 1 height)) 0.01 1000.0)
  (gl:matrix-mode :modelview)
  (gl:load-identity)
  (gl:viewport 0 0 width height))

(defmethod draw ((main main))
  (gl:clear :color-buffer :depth-buffer)
  (gl:load-identity)
  (gl:enable :depth-test :blend :cull-face :texture-2d)
  ;; FIXME: Move into camera code
  (gl:translate 0 -30 -200)
  (draw (scene main)))

(defmethod draw-hud ((main main))
  (gl:matrix-mode :projection)
  (gl:push-matrix)
  (gl:load-identity)
  (gl:ortho 0 (q+:width main) (q+:height main) 0 -1 10)
  (gl:matrix-mode :modelview)
  (gl:load-identity)
  (gl:disable :cull-face)
  (gl:clear :depth-buffer)
  (draw-hud (scene main))
  (gl:matrix-mode :projection)
  (gl:pop-matrix)
  (gl:matrix-mode :modelview))

(defun set-perspective (fovy aspect z-near z-far)
  ;; http://nehe.gamedev.net/article/replacement_for_gluperspective/21002/
  (let* ((fh (* (tan (* (/ fovy 360) PI)) z-near))
         (fw (* fh aspect)))
    (gl:frustum (- fw) fw (- fh) fh z-near z-far)))

(defun setup-scene (scene)
  (add-subject (make-instance 'player) scene)
  (add-subject (make-instance 'controller) scene))


(defun main ()
  (q+:qcoreapplication-set-attribute (q+:qt.aa_x11-init-threads))
  (with-main-window (window 'main #-darwin :main-thread #-darwin NIL)))
