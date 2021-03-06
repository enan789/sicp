;;;; SICP Chapter 2.4.3
;;;;  Data-Directed Programming and Additivity
;;;;
;;;; Author @uents on twitter
;;;;

#lang racket

(require "../misc.scm")

;;;; -----------------------------------
;;;; operation/type table (using hash tables)
;;;;  http://docs.racket-lang.org/guide/hash-tables.html
;;;;  http://docs.racket-lang.org/reference/hashtables.html 
;;;; -----------------------------------

(define *op-table* (make-hash))

(define (put op type item)
  (if (not (hash-has-key? *op-table* op))
	  (hash-set! *op-table* op (make-hash))
	  true)
  (hash-set! (hash-ref *op-table* op) type item))

(define (get op type)
  (define (not-found . msg)
	(display msg (current-error-port))
	(display "\n")
	false)
  (if (hash-has-key? *op-table* op)
	  (if (hash-has-key? (hash-ref *op-table* op) type)
		  (hash-ref (hash-ref *op-table* op) type)
		  (not-found "Bad key -- TYPE" type))
	  (not-found "Bad key -- OPERATION" op)))


; racket@> (put 'add '(number number) +)
; racket@> (put 'sub '(number number) -)
; 
; racket@> *op-table*
; '#hash((sub . #hash(((number number) . #<procedure:->)))
;        (add . #hash(((number number) . #<procedure:+>))))
;
; racket@> ((get 'add '(number number)) 3 4)
; 7
; racket@> ((get 'sub '(number number)) 3 4)
; -1
; racket@> ((get 'mul '(number number)) 3 4)
; (Bad key -- OPERATION mul)
; application: not a procedure;
;  expected a procedure that can be applied to arguments
;   given: #f
;   arguments...:
;    3
;    4
;   context...:
;    /Applications/Racket6.0.1/collects/racket/private/misc.rkt:87:7


;;;; -----------------------------------
;;;; type-tag system
;;;; -----------------------------------

(define (attach-tag type-tag contents)
  (cons type-tag contents))

(define (type-tag datum)
  (if (pair? datum)
      (car datum)
      (error "Bad tagged datum -- TYPE-TAG" datum)))

(define (contents datum)
  (if (pair? datum)
      (cdr datum)
      (error "Bad tagged datum -- CONTENTS" datum)))


;;;; -----------------------------------
;;;; complex-arithmetic package
;;;; -----------------------------------

(define (install-rectangular-package)
  ;; internal
  (define (real-part z)
	(car z))
  (define (imag-part z)
	(cdr z))
  (define (magnitude-part z)
    (sqrt (+ (square (real-part z))
             (square (imag-part z)))))
  (define (angle-part z)
    (atan (imag-part z) (real-part z)))
  (define (make-from-real-imag x y)
	(cons x y))
  (define (make-from-mag-ang r a) 
    (cons (* r (cos a)) (* r (sin a))))

  ;; interface
  (define (tag x) (attach-tag 'rectangular x))
  (put 'real-part '(rectangular) real-part)
  (put 'imag-part '(rectangular) imag-part)
  (put 'magnitude-part '(rectangular) magnitude-part)
  (put 'angle-part '(rectangular) angle-part)
  (put 'make-from-real-imag 'rectangular
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'rectangular
       (lambda (r a) (tag (make-from-mag-ang r a))))
  'done)

(define (install-polar-package)
  ;; internal
  (define (magnitude-part z)
	(car z))
  (define (angle-part z)
	(cdr z))
  (define (real-part z)
    (* (magnitude-part z) (cos (angle-part z))))
  (define (imag-part z)
    (* (magnitude-part z) (sin (angle-part z))))
  (define (make-from-mag-ang r a)
	(cons r a))
  (define (make-from-real-imag x y) 
    (cons (sqrt (+ (square x) (square y)))
          (atan y x)))

  ;; interface
  (define (tag x) (attach-tag 'polar x))
  (put 'real-part '(polar) real-part)
  (put 'imag-part '(polar) imag-part)
  (put 'magnitude-part '(polar) magnitude-part)
  (put 'angle-part '(polar) angle-part)
  (put 'make-from-real-imag 'polar
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'polar
       (lambda (r a) (tag (make-from-mag-ang r a))))
  'done)

;; constructors
(define (make-from-real-imag x y)
  ((get 'make-from-real-imag 'rectangular) x y))

(define (make-from-mag-ang r a)
  ((get 'make-from-mag-ang 'polar) r a))

(install-rectangular-package)
(install-polar-package)


;;;; -----------------------------------
;;; generic operators
;;; アクセサは引数が複素数データのため、apply-genericを使う
;;;; -----------------------------------

(define (apply-generic op . args)
  (let* ((type-tags (map type-tag args))
		 (proc (get op type-tags)))
	(if proc
		; argsはリストで渡されるので
		; contents手続きをmapしてprocをapplyで適用する
		(apply proc (map contents args))
		(error
		 "No method for these types -- APPLY-GENERIC"
		 (list op type-tags)))))

(define (real-part z) (apply-generic 'real-part z))
(define (imag-part z) (apply-generic 'imag-part z))
(define (magnitude-part z) (apply-generic 'magnitude-part z))
(define (angle-part z) (apply-generic 'angle-part z))


;;;; -----------------------------------
;;;; arithmetic operation for complex numbers
;;;; -----------------------------------

(define (add-complex z1 z2)
  (make-from-real-imag (+ (real-part z1) (real-part z2))
                       (+ (imag-part z1) (imag-part z2))))

(define (sub-complex z1 z2)
  (make-from-real-imag (- (real-part z1) (real-part z2))
                       (- (imag-part z1) (imag-part z2))))

(define (mul-complex z1 z2)
  (make-from-mag-ang (* (magnitude-part z1) (magnitude-part z2))
                     (+ (angle-part z1) (angle-part z2))))

(define (div-complex z1 z2)
  (make-from-mag-ang (/ (magnitude-part z1) (magnitude-part z2))
                     (- (angle-part z1) (angle-part z2))))


;;;; -----------------------------------
;;;; test
;;;; -----------------------------------

#|
(define z (make-from-real-imag 4 3))

z
;;=> '(rectangular 4 . 3)

(real-part z)
;;=> 4

(imag-part z)
;;=> 3

(magnitude-part z)
;;=> 5
|#

; 例えば (real-part z) は置き換えモデルを使うと、
; 
; => (real-part '(rectanglar 4 . 3)
; => (apply-generic 'real-part '(real-parg 4 . 3))
; => (apply (get 'real-part '(rectangular)) (map contents '((rectanglar 4 . 3)))
; => (apply car '((4 . 3)))
; => 4
; 
; のような感じになる



;;;; ex 2.73

(define (deriv exp var)
   (cond ((number? exp) 0)
         ((variable? exp) (if (same-variable? exp var) 1 0))
         (else ((get 'deriv (operator exp)) (operands exp) var))))

(define (operator exp) (car exp))
(define (operands exp) (cdr exp))


;;;; a.
;;;; 演算手続きはop-tableから取得できるが、
;;;; number? variable? は type に依存しないため、op-tableには吸収できないから


;;;; b. 和算、積算を導入せよ
;;;; c. 指数計算を導入せよ


(define (variable? x) (symbol? x))

(define (same-variable? v1 v2)
  (and (variable? v1) (variable? v2) (eq? v1 v2)))


;;; deriv operation package
(define (install-deriv-package)
  (define (=number? exp num)
	(and (number? exp) (= exp num)))

  ;; add
  (define (make-sum a1 a2)
	(cond ((=number? a1 0) a2)
		  ((=number? a2 0) a1)
		  ((and (number? a1) (number? a2)) (+ a1 a2))
		  (else (list '+ a1 a2))))
  (define (addend s) (car s))
  (define (augend s) 
	(if (= (length (cdr s)) 1)
		(cadr s)
		(cons '+ (cdr s))))

  ;; product
  (define (make-product m1 m2)
	(cond ((or (=number? m1 0) (=number? m2 0)) 0)
		  ((=number? m1 1) m2)
		  ((=number? m2 1) m1)
		  ((and (number? m1) (number? m2)) (* m1 m2))
		  (else (list '* m1 m2))))
  (define (multiplier p) (car p))
  (define (multiplicand p)
	(if (= (length (cdr p)) 1)
		(cadr p)
		(cons '* (cdr p))))

  ;; exponetiation
  (define (make-exponentiation base exponent)
	(cond ((=number? exponent 0) 1)
		  ((=number? exponent 1) base)
		  (else (list '** base exponent))))
  (define (base exp) (car exp))
  (define (exponent exp) (cadr exp))

  ;; interface
  (put 'deriv '+ 
	   (lambda (exp var)
		 (make-sum (deriv (addend exp) var)
				   (deriv (augend exp) var))))
  (put 'deriv '* 
	   (lambda (exp var)
		 (make-sum
		  (make-product (multiplier exp)
						(deriv (multiplicand exp) var))
		  (make-product (deriv (multiplier exp) var)
						(multiplicand exp)))))
  (put 'deriv '**
	   (lambda (exp var)
		 (let ((b (base exp))
			   (n (exponent exp)))
		   (make-product
			(make-product n
						  (make-exponentiation b (- n 1)))
			(deriv b var)))))
  'done)

(install-deriv-package)


#|
(deriv '(+ x y z) 'x)
;;=> 1

(deriv '(+ x y z) 'y)
;;=> 1

(deriv '(+ x y z) 'w)
;;=> 0

(deriv '(** x 1) 'x)
;;=> 1

(deriv '(** x 2) 'x)
;;=> '(* 2 x)

(deriv '(** x 3) 'x)
;;=> '(* 3 (** x 2))
|#


;;; d.
;
; deriv手続きのoperator/operandsの呼び出し行を
;
; ((get (operator exp) 'deriv) (operands exp) var)
;
; とした場合に、システムの変更は何が必要か？
;
; => install-deriv-packageのputの行を
;
; (put <operation> 'deriv <procedure of operation>)
;
; とする..

