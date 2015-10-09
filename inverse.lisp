(in-package "NAPA-FFT.GEN")

(defvar *inv-base-case* 32)

(defun %gen-flat-dit (n scale window)
  (with-vector (n)
    (labels ((rec (start n)
               (cond
                 ((= n 1)
                  (when (or (not (eql scale 1.0))
                            window)
                    (scale start scale window)))
                 ((= n 2)
                  (when (or (not (eql scale 1.0))
                            window)
                    (scale start      scale window)
                    (scale (1+ start) scale window))
                  (butterfly start (1+ start)))
                 (t
                  (let* ((n/2    (truncate n 2))
                         (start2 (+ start n/2))
                         (n/4    (truncate n/2 2))
                         (start3 (+ start2 n/4)))
                    (rec start3 n/4)
                    (rec start2 n/4)
                    (dotimes (count n/4)
                      (let ((i (+ start2 count))
                            (j (+ start3 count))
                            (k (+ n/2 +twiddle-offset+ (* 2 count))))
                        (rotate i k      (/ count n))
                        (rotate j (1+ k) (/ (* 3 count) n))
                        (butterfly i j)
                        (rotate j nil -3/4)))
                    (rec start n/2)
                    (dotimes (i n/2)
                      (butterfly (+ start  i)
                                 (+ start2 i))))))))
      (rec 0 n))))

(defun gen-flat-dit (n &key (scale 1.0) window)
  (let ((table (load-time-value (make-hash-table :test #'equal)))
        (key   (list n scale window)))
    (or (gethash key table)
        (setf (gethash key table)
              (%gen-flat-dit n scale window)))))

(defun gen-dit (n &key (scale 1.0) window)
  (let ((defs '())
        (last n))
    (labels ((name (n)
               (intern (format nil "~A/~A" 'dit n)
                       "NAPA-FFT.GEN"))
             (gen (n &aux (name (name n)))
               (when (member name defs :key #'first)
                 (return-from gen))
               (cond
                 ((<= n *inv-base-case*)
                  (push `(,(name n) (start ,@(and window '(window-start)))
                          (declare (type index start
                                              ,@(and window
                                                     '(window-start)))
                                   (ignorable start
                                              ,@(and window
                                                     '(window-start))))
                          ,(gen-flat-dit n :scale scale :window window))
                        defs))
                 (t
                  (gen (truncate n 4))
                  (gen (truncate n 2))
                  (let* ((n/2 (truncate n 2))
                         (n/4 (truncate n 4))
                         (name/2 (name n/2))
                         (name/4 (name n/4))
                         (body
                           `(,(name n) (start ,@(and window
                                                     '(window-start)))
                             (declare (type index start
                                            ,@(and window
                                                   '(window-start))))
                             (,name/4 (+ start ,n/2)
                                      ,@(and window
                                             `((+ window-start ,n/2))))
                             (,name/4 (+ start ,(+ n/2 n/4))
                                      ,@(and window
                                             `((+ window-start
                                                  ,(+ n/2 n/4)))))
                             (for (,n/4 (i start)
                                        (k ,(+ n/2 +twiddle-offset+) 2))
                               (let* ((t1 (aref twiddle k))
                                      (t2 (aref twiddle (1+ k)))
                                      (x  (* t1 (aref vec (+ i ,n/2))))
                                      (y  (* t2 (aref vec (+ i ,(+ n/2 n/4))))))
                                 (setf (aref vec (+ i ,n/2))
                                       (+ x y)
                                       (aref vec (+ i ,(+ n/2 n/4)))
                                       (mul+i (- x y)))))
                             (,name/2 start
                                      ,@(and window '(window-start)))
                             (for (,n/2 (i start)
                                        ,@(and (= n last)
                                               window
                                               `((k window-start))))
                               (let ((x (aref vec i))
                                     (y (aref vec (+ i ,n/2))))
                                 (setf (aref vec          i) (+ x y)
                                       (aref vec (+ i ,n/2)) (- x y)))))))
                    (push body defs))))))
      (gen n)
      `(labels (,@(nreverse defs))
         (declare (inline ,(name n)))
         (,(name n) start
          ,@(and window '(window-start)))))))

(defun %dit (vec start n twiddle)
  (declare (type complex-sample-array vec twiddle)
           (type index start)
           (type size n))
  (labels ((rec (start n)
             (declare (type index start)
                      (type size n))
             (cond ((>= n 4)
                    (let* ((n/2    (truncate n 2))
                           (start2 (+ start n/2))
                           (n/4    (truncate n/2 2))
                           (start3 (+ start2 n/4)))
                      (rec start3 n/4)
                      (rec start2 n/4)
                      (for (n/4 (i start2)
                                (j start3)
                                (k (+ n/2 +twiddle-offset+) 2))
                           (let* ((t1 (aref twiddle k))
                                  (t2 (aref twiddle (1+ k)))
                                  (x  (* (aref vec i) t1))
                                  (y  (* (aref vec j) t2)))
                             (setf (aref vec i) (+ x y)
                                   (aref vec j) (mul+i (- x y)))))
                      (rec start n/2)
                      (for (n/2 (i start)
                                (j start2))
                           (let ((x (aref vec i))
                                 (y (aref vec j)))
                             (setf (aref vec i) (+ x y)
                                   (aref vec j) (- x y))))))
                   ((= n 2)
                    (let ((s0 (aref vec start))
                          (s1 (aref vec (1+ start))))
                      (setf (aref vec start)      (+ s0 s1)
                            (aref vec (1+ start)) (- s0 s1)))
                    nil))))
    (rec start n)
    vec))
