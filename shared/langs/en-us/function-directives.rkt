#lang racket
#|
|#

(provide *function-list*)

(define *solutions-mode?* (getenv "SOLUTIONS"))

(define *show-funname-contract?* #f)
(define *show-domains?* #f)
(define *show-range?* #f)
(define *show-purpose?* #f)
(define *show-examples* #f)
(define *show-funname-defn?* #f)
(define *show-params?* #f)
(define *show-body?* #f)

(define *div-nesting* 0)

(define (ft-list-ref s i)
  (let ((n (length s)))
    (and (< i n) (list-ref s i))))

(define (encoded-ans style s show?)
  (format "[.studentAnswer.~a.~a]##~a##"
          (if show? "solution" "blank")
          style
          (if show? s
              (let ((n (string-length (if (string? s) s (format "~a" s)))))
                (make-string n #\M)))))

(define (write-directions page-header funname directions)
  (format "\n
== ~a: ~a\n
_**Directions**: ~a_
" page-header
          funname
          directions))

(define (write-purpose funname domain-list range purpose)
  (format "\n
=== Contract and Purpose Statement\n
_Every contract has three parts..._\n

[.wrapper]
~a :
~a →
~a

~a

"
          (encoded-ans "recipe_name" funname *show-funname-defn?*)
          (encoded-ans "recipe_domain" (list-to-string domain-list) *show-domains?*)
          (encoded-ans "recipe_range" range *show-range?*)

          (encoded-ans "recipe_purpose" purpose *show-purpose?*)

          ))

(define (write-examples funname num-examples example-list buggy-example-list)
  ;(printf "doing write-examples num-examples=~a example-list=~a buggy-example-list=~a " num-examples example-list buggy-example-list)
  (string-append
    (format "\n
=== Examples\n
_Write some examples, then circle and label what changes..._\n
")
    ;examples

    (apply string-append
           (cond [(and #t (cons? buggy-example-list))
                  ;(printf "doing buggy-example-list ~s\n" buggy-example-list)
                  (map (lambda (e)
                         (write-each-example (caar e) (cdar e) (cadr e) #t))
                       buggy-example-list) ]
                 [else
                   (let* ((example-list-len (length example-list))
                          (num-blank-examples (- num-examples example-list-len)))
                     (append
                       (map (lambda (e s)
                              (let* ((n (- (length e) 1))
                                     (body (list-ref e n))
                                     (parms (take e n)))
                                (write-each-example funname parms body s)))
                            example-list
                            (cond ((eq? *show-examples* #t)
                                   (build-list example-list-len (lambda (i) #t)))
                                  ((eq? *show-examples* #f)
                                   (build-list example-list-len (lambda (i) #f)))
                                  (else
                                    (append *show-examples*
                                            (build-list (- example-list-len (length *show-examples*))
                                                        (lambda (i) #f))))))
                       (build-list num-blank-examples
                                   (lambda (i)
                                     (write-each-example funname '() '() #f)))))]
                 ))
    ))

(define (write-each-example funname parms body show)
  ;(printf "write-each-example ~s ~s ~s ~s\n" funname parms body show)
  (let ((show-funname? #f)
        (show-args? #f)
        (show-body? #f))
    (cond ((not show) #f)
          ((not *solutions-mode?*) #f)
          ((eqv? show #t)
           (set! show-funname? #t)
           (set! show-args? #t)
           (set! show-body? #t))
          ((list? show)
           (set! show-funname? (list-ref show 0))
           (set! show-args? (list-ref show 1))
           (set! show-body? (list-ref show 2))))
    (format "~n
[.wrapper]
(EXAMPLE (~a ~a) ~a)~n
~a
~n"
            (encoded-ans "recipe_name" funname show-funname? )
            (encoded-ans "recipe_example_inputs" (list-to-string parms) show-args?)
            (encoded-ans "recipe_example_body" body show-body?)
            (write-clear)

            )))

(define (list-to-string xx)
  (apply string-append
         (reverse
           (let loop ((xx xx) (r '()))
             (if (null? xx) r
                 (loop (cdr xx) (cons (format " ~a" (car xx)) r)))))))

(define (write-definition funname param-list body)
  (string-append
  (format "\n
=== Definition\n
_Write the definition, given variable names to all your input values..._\n

[.wrapper]
(define (
~a
~a)
"
            (encoded-ans "recipe_name" funname *show-funname-defn?*)
            (encoded-ans "recipe_variables" (list-to-string param-list) *show-params?*)

            )

    (if (eqv? (car body) 'cond)
        (apply string-append
               (let loop ((clauses (cdr body))
                          (r (list (format "~a(~a~%"
                                           (write-clear)
                                           (encoded-ans "recipe_cond" "cond" *show-body?*)))))
                 (if (null? clauses)
                     (reverse (cons (format ")~%") r))
                     (loop (cdr clauses)
                           (cons
                             (format "~a{startsb}~a{endsb}~%"
                                     (write-clear)
                                     (write-cond-clause (car clauses) *show-body?*))
                             r)))))
        (format "~a~a" (write-clear) (encoded-ans "recipe_body" body *show-body?*))
        )

    (format ")~%~%")
))

(define (write-clear)
  "[.clear]## ##")

(define (write-cond-clause clause show?)
  ;(printf "doing write-cond-clause ~a ~a\n" clause show?)
  (string-append (encoded-ans "questions" (car clause) show?)
                 " "
                 (encoded-ans "answers" (list-to-string (cdr clause)) show?)))

(define (design-recipe-exercise funname directions
                                #:page-header (page-header "Word Problem")
                                #:show-funname-contract? (show-funname-contract? #f)
                                #:domain-list (domain-list '()) ; list of string
                                #:show-domains? (show-domains? #f)
                                #:range (range #f)
                                #:show-range? (show-range? #f)
                                #:purpose (purpose #f)
                                #:show-purpose? (show-purpose? #f)
                                ; num-examples = 1, in orig
                                ; = 0, debug
                                #:num-examples (num-examples 1) ; number of total example spaces to generate
                                #:example-list (example-list '()) ;concrete examples -- see doc above func for details
                                #:buggy-example-list (buggy-example-list '()) ; full concrete examples with error
                                #:show-examples (show-examples '()) ; see doc above func for details
                                #:buggy-funname-defn (buggy-funname-defn #f)
                                #:show-funname-defn? (show-funname-defn? #f)
                                #:param-list (param-list '()) ; list of string
                                #:show-params? (show-params? #f)
                                #:body (body #f) ; a string
                                #:show-body? (show-body? #f)
                                #:grid-lines? (grid-lines? #f)
                                #:lang (lang 'racket)
                                )

  (set! *show-funname-contract?* show-funname-contract?)
  (set! *show-domains?* show-domains?)
  (set! *show-range?* show-range?)
  (set! *show-purpose?* show-purpose?)
  (set! *show-examples* show-examples)
  (set! *show-funname-defn?* show-funname-defn?)
  (set! *show-params?* show-params?)
  (set! *show-body?* show-body?)

  (unless *solutions-mode?*
    (set! *show-funname-contract?* #f)
    (set! *show-domains?* #f)
    (set! *show-range?* #f)
    (set! *show-purpose?* #f)
    (set! *show-examples* #f)
    (set! *show-funname-defn?* #f)
    (set! *show-params?* #f)
    (set! *show-body?* #f)
    )

  ;(printf "d-r-e body= ~s\n" body)
  ;uncomment in orig;
  ;comment, debug
  (when (and (cons? example-list) (cons? buggy-example-list))
    (error 'design-recipe-exercise "At most one of example-list and buggy-example-list should be provided"))

  (string-append

    (write-directions page-header funname directions)

    (write-purpose funname domain-list range purpose)

    (write-examples funname num-examples example-list buggy-example-list)

    (write-definition funname param-list body)

    )

  )

(define (assess-design-recipe
          funname directions
          #:domain-list (domain-list '()) ; list of string
          #:range (range #f)
          #:purpose (purpose #f)
          #:example-list (example-list '()) ;concrete examples -- see doc above func for details
          #:buggy-example-list (buggy-example-list '()) ; full concrete examples with error
          #:buggy-funname-defn (buggy-funname-defn #f)
          #:param-list (param-list '()) ; list of string
          #:body (body #f) ; a string
          #:grid-lines? (grid-lines? #f)
          )
  (unless range (error 'assess-design-recipe "range required"))
  (unless purpose (error 'assess-design-recipe "purpose required"))
  (unless body (error 'assess-design-recipe "body required"))
  (let ((use-examples (if (cons? buggy-example-list) buggy-example-list example-list)))
    (design-recipe-exercise funname directions
                            #:page-header "Check for Mistakes in this Word Problem"
                            #:show-funname-contract? #t
                            #:domain-list domain-list
                            #:show-domains? #t
                            #:range range
                            #:show-range? #t
                            #:purpose purpose
                            #:show-purpose? #t
                            #:num-examples (length use-examples)
                            ;orig example-list, debug = use-examples
                            ;#:example-list use-examples
                            #:example-list example-list
                            ;orig buggy-example-list, debug = use-examples
                            ;#:buggy-example-list use-examples
                            #:buggy-example-list buggy-example-list
                            #:show-examples (build-list (length use-examples) (lambda (i) #t))
                            #:buggy-funname-defn buggy-funname-defn
                            #:show-funname-defn? #t
                            #:param-list param-list
                            #:show-params? #t
                            #:body body
                            #:show-body? #t
                            #:grid-lines? grid-lines?
                            )))

(define *function-list*
  `(
    ("assess-design-recipe" ,assess-design-recipe)
    ("design-recipe-exercise" ,design-recipe-exercise)
    ))
