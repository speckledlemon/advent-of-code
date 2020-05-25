;; def find_duplicate_frequencies(changes):
;;     def find_duplicate_frequencies_acc(changes, current_frequency, frequencies):
;;         if not frequencies:
;;             frequencies.add(current_frequency)
;;         for change in changes:
;;             current_frequency += change
;;             if not current_frequency in frequencies:
;;                 frequencies.add(current_frequency)
;;             else:
;;                 return current_frequency
;;         return find_duplicate_frequencies_acc(changes, current_frequency, frequencies)
;;     return find_duplicate_frequencies_acc(changes, 0, set())

;; assert find_duplicate_frequencies([+1, -1]) == 0
;; assert find_duplicate_frequencies([+3, +3, +4, -2, -4]) == 10
;; assert find_duplicate_frequencies([-6, +3, +8, +5, -6]) == 5
;; assert find_duplicate_frequencies([+7, +7, -2, -7, -4]) == 14
;; print(find_duplicate_frequencies(changes))

(defmain [&rest_]
  (with [handle (open "input.txt")]
    (setv changes (lfor x (.readlines handle) (int (.strip x)))))
  (print changes))
