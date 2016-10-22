#+nil(progn
  (push #p"~/src/xml-emitter/" asdf:*central-registry*)
  (push #p"~/src/dbus/" asdf:*central-registry*)
  (ql:quickload "dbus"))

(defvar *current-id* 1)
(defvar *current-id-lock* (bordeaux-threads:make-lock))

(defclass notification ()
  ((id             :type integer
                   :reader notification/id)
   (title          :type string
                   :initarg :title
                   :reader notification/title)
   (body           :type string
                   :initarg :body
                   :reader notification/body)
   (app-name       :type string
                   :initarg :app-name
                   :reader notification/app-name)
   (actions        :initarg :actions
                   :reader notification/actions)
   (expire-timeout :type integer
                   :initarg :expire-timeout
                   :reader notifications/expire-timeout)))

(defmethod initialize-instance :after ((obj notification) &key)
  (setf (slot-value obj 'id)
        (bordeaux-threads:with-lock-held (*current-id-lock*)
          (prog1
              *current-id*
            (incf *current-id*)))))

(dbus:define-dbus-method get-server-information ()
    (:in "" :out "ssss" :dbus-name "GetServerInformation")
  (values "StumpWM notifications service" "com.dhsdevelopments" "1.0" "1.2"))

(dbus:define-dbus-method get-capabilities ()
    (:in "" :out "as" :dbus-name "GetCapabilities")
  (format t "get-capabilities~%")
  nil)

(dbus:define-dbus-method notify (app-name replaces-id app-icon summary body actions hints expire-timeout)
    (:in "susssasa{sv}i" :out "i" :dbus-name "Notify")
  (format t "Notify got summary: ~s, body: ~s, actions: ~s, hints: ~s, timeout: ~s~%" summary body actions hints expire-timeout)
  (let ((notification (make-instance 'notification
                                     :title summary
                                     :body body
                                     :app-name app-name
                                     :actions actions
                                     :expire-timeout expire-timeout)))
    (notification/id notification)))

(defun foo ()
  (dbus:with-open-bus (bus (dbus:session-server-addresses))
    (dbus:dbus-serve bus "org.freedesktop.Notifications" "com.dhsdevelopments.stumpwm-notifications" nil)))
