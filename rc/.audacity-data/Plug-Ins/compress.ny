;nyquist plug-in
;version 1
;type process
;categories "http://lv2plug.in/ns/lv2core#CompressorPlugin"
;name "Compress &dynamics..."
;action "Compressing..."
;info "Does dynamic (volume) compression with lookahead.\n'Compress ratio' is how much compression to apply. Raise when soft parts\n  are too soft, and lower to keep some dynamic range. You can soften the\n  soft parts instead of increasing them with values < 0, and invert\n  loudness with values > 1 (lower max amp when you do).\n'Hardness' is how agressively to compress. Raise when parts are still\n  hard to hear (even with a high compress ratio). Lower when the result\n  sounds distorted.\nRaise 'floor' to make quiet parts stay quiet.\nRaise 'noise gate falloff' to make quiet parts (beneath 'floor') disappear.\nLower 'maximum amplitude' if you experience clipping."
;control compress-ratio "Compress ratio" real "" .5 -.5 1.25

;; TO ENABLE ADVANCED SETTINGS: delete one semicolon from the beginning of the next two lines, then add one to following four.

;;control left-width-s "Release speed" real "~ms" 510 1 5000
;;control right-width-s "Attack speed" real "~ms" 340 1 5000

;control hardness "Compression hardness" real "" .5 .1 1
(setf hardness (* (- 1.1 hardness) 3))
(setf left-width-s (* hardness hardness 510))
(setf right-width-s (* hardness hardness 340))

;control floor "Floor" real "dB" -32 -96 0
;control noise-factor "Noise gate falloff" real "factor" 0 -2 10
;control scale-max "Maximum amplitude" real "linear" .99 .0 1.0

;; TO ENABLE ADVANCED SETTINGS: delete one semicolon from the beginning of the next two lines, then add one to following two.

;;control left-exponent "Release exponent" real "" 2 1 6
;;control right-exponent "Attack exponent" real "" 4 1 6

(setf left-exponent 2)
(setf right-exponent 4)

;;Version 1.2.6

;;Authored by Chris Capel (http://pdf23ds.net)
;;All rights reserved
;;Permission granted for personal use, without redistribution.

;;This algorithm works by enveloping the average of an incoming signal (like
;;all dynamic compressors, really). The envelope is constructed using sections
;;of paraboloids (explained below). The closest-fitting envelope possible is
;;found for paraboloids constructed using the parameters, such no two points
;;have a connecting paraboloid that passes above an intermediate point on the
;;envelope. The envelope is inverted and multiplied against the source signal
;;to apply the appropriate gain.

;;The motivation for using paraboloids is that I was unhappy with the results
;;using lines (used in a previous version of this plugin). It would not
;;respond quickly enough to very steep changes in the signal without the
;;compression getting too hard for my taste. The behavior of this compressor
;;(with the default parameters) is that the envelope will "hover over"/hug the
;;low points of the input signal, while applying an accelerating amount of
;;gain (especially on attacks, but also on release) to meet peaks.

;convert to seconds
(setf right-width-s (/ right-width-s 1000))
(setf left-width-s (/ left-width-s 1000))

; umm, this isn't ready for prime-time
; control use-percep "Use perceptual model" int "yes/no" 0 0 1
(setf use-percep 0)

(setf *window-size* 1500)

(setf *gc-flag* nil)

;;Compressing based on perceived loudness--perceptual model

;;would use rms instead of absolute peak, on the theory that it would more closely
;;follow perceived loudness, except that the theory is wrong. absolute peak actually
;;seems to *more* closely track perceived loudness, though it's not perfect. (I think
;;the main shortcoming is that it doesn't know about the response curve of the human
;;ear, where middle-range sounds seem louder than very high or low ones.) Perhaps to
;;fix it would require applying equalization that makes the computer "hear" what humans
;;do as far as frequency response, so that the peak values (or maybe RMS then) would
;;then nearly perfectly track perceptual loudness. Frequency response actually varies
;;considerably between different people, and volume levels and playback systems, and
;;is especially affected by age, but it might still be possible to improve on an
;;unequalized absolute peak, so that brass don't sound louder than strings at the same
;;amplitude.

;;http://personal.cityu.edu.hk/~bsapplec/frequenc.htm
;;20 hz -40 db
;;30 hz -30 db
;;50 hz -20
;;80 hz -10
;;120 hz -5
;;200 hz 0
;;300 hz +4
;;450 hz +5
;;600 hz +4
;;800 hz +2
;;1300 hz 0
;;2000 hz +3
;;3000 hz +7
;;4000 hz +9
;;6000 hz +1
;;8500 hz -7
;;12000 hz 0
;;14000 hz +4
;;16000 hz -3
;;20000 hz -30

;;this EQ setting can probably be improved on a lot

;;20 -40
;;40 -23
;;80 -10
;;160 -4
;;320 +3
;;640 +2
;;1280 0
;;2560 +4
;;5120 +9
;;10240 -7
;;20480 -20

;;

(defun get-percep-adjusted-sound (sound)
  (let ((bands '((20 -40)
                 (40 -23)
                 (80 -10)
                 (160 -4)
                 (320 +3)
                 (640 +2)
                 (1280 0)
                 (2560 +4)
                 (5120 +9)
                 (10240 -7)
                 (20480 -20))))
    (dolist (band bands)
      (setf sound (eq-band sound (car band) (cadr band) 1)))
    sound))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Work with sound arrays
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setf s-length (/ len *window-size*))

(defun my-snd-fetch-array (snds size)
  (if (<= s-length 0)
      nil
      (if (arrayp snds)
          (let (buffers)
            (dotimes (x (length snds))
              (push (snd-fetch-array (aref snds x) size size)
                    buffers))
            (setf s-length (- s-length size))
            (dotimes (i (length (first buffers)))
              (setf (aref (first buffers) i)
                    (apply #'max (mapcar (lambda (x)
                                           (linear-to-db (abs (aref x i))))
                                         buffers))))
            (first buffers))
          (let ((val (snd-fetch-array snds size size)))
            (setf s-length (- s-length size))
            (dotimes (i (length val))
              (setf (aref val i) (linear-to-db (abs (aref val i)))))
            val))))

(defun my-snd-srate (snds)
  (if (arrayp snds)
      (snd-srate (aref snds 0))
      (snd-srate snds)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Paraboloid stuff
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; A paraboloid is an equation of the form
;; f(x) =
;; when x < 0: -abs(x^n1)
;; when x >= 0: x^n2

(defun make-curve (max power coeff)
  "return (x/coeff)^power for x from 0 to n where (x/coeff)^n is around max"
  (let (ret (len 0))
    (do* ((x 0 (+ 1 x))
          (y 0 (expt (/ x coeff) power)))
         ((> y max))
      (push y ret)
      (incf len))
    ;return the reversed version
    (list ret len)))

;; these are initialized later
(setf left-width nil)
(setf right-width nil)

(defun init-para ()
  "make left and right curves and stick them together (in a U/V shape) in a
  single array for easier processing."
  (let ((left  (make-curve 10000  left-exponent  left-width))
        (right (make-curve 10000 right-exponent right-width)))
    (setf para (make-array (1- (+ (second left) (second right)))))
    (setf para-mid (second left))
    ;copy (already) reversed left to left side of vector
    (do ((i 0 (1+ i))) ((>= i (second left)))
      (setf (aref para i) (caar left))
      (setf (car left) (cdar left)))
    ;(format t "parabola: ~a~%" para)
    ;reverse right and copy to right side of vector
    (do ((i (- (+ (second left) (second right)) 2) (1- i)))
        ((< i (second left)))
      (setf (aref para i) (caar right))
      (setf (car right) (cdar right)))))

(defun solve-para (x1 y1 x2 y2)
  "return a function that takes x and returns the value of a paraboloid at x
  where the paraboloid solves {<x1, y1>, <x2, y2>}"
  (let ((y (- y2 y1))
        (x (- x2 x1)))
    ;;check for errors, early exit
    (when (> (abs y) (aref para (1- (length para))))
      (error "y is too big"))
    (when (<= x 0)
      (error "x is too small"))
    (when (>= x (length para)) (return nil))
    ;;ok, now real code
    (let* ((left (< y 0))
           ;;first get in the general area with integers
           (res (binary-search-int y x left))
           (i (if (or (= res 0) (= res (1- (length para))))
                  res
                  ;;then if we need to get closer to make up for poor precision
                  (binary-search-float res y x left)))
           (yOff (- y1 (interp i)))
           (i (- i x1)))
      (lambda (x)
        ;(when (>= (+ x i) (length para))
        ;  (break "detected array out of bounds"))
        (+ (interp (+ x i)) yOff)))))

(defun binary-search-int (y x left)
  "do an integer binary search to find the best matching part of para for the
  given vector (i.e. that would fit best between the two given points)."
  (labels (
    (bounds-check (start end)
      (let ((ystart (- (aref para (+ start x)) (aref para start)))
            (yend (- (aref para (+ end x)) (aref para end))))
        (when (if left (> y yend) (< y ystart))
          (error "internal math problem")))))

    ;; the actual search
    (let* ((start (if left 0 (1- (- para-mid x))))
           (end (if left
                    (min para-mid (1- (- (length para) x)))
                    (1- (- (length para) x))))
          )
      (bounds-check start end)
      ;;do a basic binary search
      (do ((i (+ start 1) (+ start (/ (- end start) 2))))
          ((or (= i start) (= i end))
           i)
        (let ((yi (- (aref para (+ i x)) (aref para i))))
          (if (> yi y)
              (setf end i)
              (setf start i)))))))

(defun binary-search-float (i y x left)
  "do an increased-precision search that includes linear interpolation of para
  to minimize the effect of precision errors on the final audio."
  (let ((start (- i 1))
        (end (+ i 1))
        (dy 0)
        (count 0))
    (do ()
        ((< (abs (- dy y)) .1)
         i)
      (incf count)
      (when (> count 10000) (break "float loop"))
      (setf i (+ start (/ (- end start) 2.0)))
      (setf dy (- (interp (+ i x)) (interp i)))
      (if (> dy y)
          (setf end i)
          (setf start i)))))

(defun interp (i)
  "linear interpolation of point i in para."
  (let* ((low (truncate i))
         (high (if (= i low) low (if (> i 0) (1+ low) (1- low))))
         (fact (- high i)))
    (+ (* fact (aref para low))
       (* (- 1 fact) (aref para high)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sound buffer object
;;
;; The sound buffer takes a sound and a buffer size and returns any random
;; sample, keeping everything needed in memory. _set-buffer-pos_ is used to
;; tell it you're done with samples before that offset so it can discard the
;; earlier samples.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun make-snd-buffer (sound buffer-size)
  (list 0 ;position
        sound
        buffer-size
        nil ;; list of buffer arrays
        ))

;(setf temp 3)

(defun get-buffer-sample (buf samp-num)
  (let ((pos (first buf))
        (sound (second buf))
        (size (third buf))
        (bufs (fourth buf)))
    (let ((buffer-num (truncate (/ (- samp-num pos) size))))
      (while (>= buffer-num (length bufs))
        (setf (nth 3 buf)
              (nconc bufs (list (my-snd-fetch-array sound size))))
              ;(if (>= temp 0) (progn
              ;  (decf temp)
              ;  (nconc bufs (list (let ((a (make-array size)))
              ;                      (dotimes (i size)
              ;                        (setf (aref a i) 0.0))
              ;                      a))))
              ;  bufs))
        (setf bufs (fourth buf)))
      (let* ((buf-vec (nth buffer-num bufs))
             (idx (and buf-vec (rem (- samp-num pos) size)))
             (sample (and buf-vec (< idx (length buf-vec))
                          (aref buf-vec idx))))
        (and sample (max sample -1000))))))

(defun set-buffer-pos (buf pos)
  "tell the buffer what position you're currently at, promising you won't need
  any samples before pos, so that the buffer can discard earlier samples."
  (let ((size (third buf)))
    (while (< (+ (first buf) size) pos)
      (setf (nth 3 buf) (rest (fourth buf))
            (nth 0 buf) (+ (first buf) size)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Compressor object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; define class
(setf compression-env (send class :new '(input-buf cur-para cur-para-end i)))

;; constructor
(send compression-env :answer :isnew '(snd)
  '((progn
     (setf input-buf (make-snd-buffer snd 1000)
           ;; this is a function returning offsetted points of a paraboloid
           cur-para nil
           ;; the sample number where we need to get a new cur-para
           cur-para-end 0
           ;; the current sample number
           i 0
           first-samp t))
     ;; set up some common data used in the cur-para function
     (init-para)))

;; obtain individual samples for the envelope
(send compression-env :answer :next '() '(
(labels ((samp (i) (get-buffer-sample input-buf i)))
  ;; when we need to get a new cur-para
  (when (or (null cur-para)
            (and (= i cur-para-end) (samp (+ i 2))))
    ;; this is the envelope fitting code. pretty, huh? I'd like to see *you*
    ;; do better
    (let ((iY (samp i))
          ;; if this is the first time through the loop
          (first (null cur-para))
          ;; the point at the other end of the current paraboloid section
          j jY)
      (tagbody again
        (setf j (1+ i)
              jY (samp j))
        (setf cur-para (solve-para i iY j jY)
              cur-para-end j)
        ;; j is almost certainly not right at this point, so keep looking
        (loop
          (incf j)
          (when (null (samp j)) (progn
            (when (null cur-para)
              (setf cur-para (solve-para i iY j jY)))
            (return)))
          (setf jY (samp j))
          (let (iY-changed
                (parY -1))
            ;; comments? you need comments?
            (when (and first
                       (> (/ (/ (- jY iY) right-width) (- j i)) .01))
              (progn
                (setf iY-changed t)
                (setf iY (- jY (* .01 (* right-width (- j i)))))))
            (when cur-para
              (setf parY (funcall cur-para j)))
            (when (>= parY 0)
              (return))
            (when (or (< parY jY) iY-changed (null cur-para)) (progn
              (setf cur-para (solve-para i iY j jY))
              (setf cur-para-end j)))))
        (when first (progn
          (setf first nil)
          ;;iY now has the value it needs, but the paraboloid
          ;;could overlap some peaks, so we need to recalculate those now
          (go again))))))
  (when (= 0 (rem i 1000)) (set-buffer-pos input-buf i))
  (let* ((v (funcall cur-para i))
         ;;s-min seems to behave strangely, so we do the floor/noisegate thing
         ;;here instead
         (res (if (> v floor)
                  v
                  (+ (* (- v floor) -1 noise-factor)
                     floor))))
    ;;put out an extra sample at the beginning.
    ;;otherwise it doesn't line up for some weird reason. who knows?
    (if first-samp
      (progn (setf first-samp nil) 
        res)
      (progn
        (incf i)
        ;;put an extra sample at the end, too.
        ;;otherwise the volume drops off at the very end
        ;;because nyquist adds an implicit last sample with value 0
        (if (and (null (samp i)) (null (samp (1- i))))
          ;(progn (close debug) nil)
          nil
          res)))))))

(defun get-compression-env (snd)
  (let ((sound (if (arrayp snd) (aref snd 1) snd)))
    (snd-fromobject (snd-t0 sound) (snd-srate sound)
                    (send compression-env :new snd))))

(defun get-my-sound (sound)
  "take care of averaging and multichannel bookkeeping"
  (let ((sound (if (= use-percep 1) (get-percep-adjusted-sound sound) sound))
        (avg-fun (lambda (snd) (snd-avg snd (* 2 *window-size*) *window-size* op-peak))))
    (if (arrayp sound)
        (let ((avg-channels (make-array (length sound))))
          (dotimes (i (length sound))
            (setf (aref avg-channels i)
                  (funcall avg-fun (aref sound i))))
          avg-channels)
        (funcall avg-fun sound))))

(defun do-compression ()
  (let* ((ret (get-my-sound s))
         (srate (my-snd-srate ret)))
    (setf right-width (* right-width-s srate))
    (setf  left-width (*  left-width-s srate))

    ;;get-compression-env applies linear-to-db(max(abs(s))) to its input
    (setf ret (get-compression-env ret))
    (setf ret (mult compress-ratio ret))
    (setf ret (db-to-linear ret))
    (setf ret (recip ret))
    (setf ret (mult scale-max ret))
    ;(snd-length ret 10000000000)
    (mult s ret)
    ))

(defun prin (&rest args)
  ;(dolist (x args)
  ;  (princ x debug))
  ;(terpri debug)
  )

;(setf debug (open "C:\\debug.txt" :direction :output))
(do-compression)
