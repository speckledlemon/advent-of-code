#lang racket/base

(require rackunit racket/file)

(define (get-fuel mass)
  (- (quotient mass 3) 2))

(define (get-all-fuel-acc mass acc)
  (define additional-fuel (get-fuel mass))
  (if (<= additional-fuel 0)
      acc
      (get-all-fuel-acc additional-fuel (+ acc additional-fuel))))
(define (get-all-fuel mass)
  (get-all-fuel-acc mass 0))

(check-equal? (get-fuel 12) 2)
(check-equal? (get-fuel 14) 2)
(check-equal? (get-fuel 1969) 654)
(check-equal? (get-fuel 100756) 33583)

(define numlines (map string->number (file->lines "day1_input.txt")))

(define ans-part1 (apply + (map get-fuel numlines)))
(println ans-part1)

(check-equal? (get-all-fuel 14) 2)
(check-equal? (get-all-fuel 1969) 966)
(check-equal? (get-all-fuel 100756) 50346)

(define ans-part2 (apply + (map get-all-fuel numlines)))
(println ans-part2)
