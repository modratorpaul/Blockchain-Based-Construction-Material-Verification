;; quality-testing.clar
;; This contract records laboratory analysis of materials

(define-data-var admin principal tx-sender)

;; Map to store test results
(define-map test-results (tuple (material-id (string-utf8 36)) (test-id (string-utf8 36)))
  {
    tester: principal,
    test-date: uint,
    strength: uint,
    durability: uint,
    composition-verified: bool,
    passed: bool
  }
)

;; Public function to record test results
(define-public (record-test-result
    (material-id (string-utf8 36))
    (test-id (string-utf8 36))
    (strength uint)
    (durability uint)
    (composition-verified bool))
  (begin
    (asserts! (is-authorized-tester tx-sender) (err u1)) ;; Only authorized testers

    (let ((passed (and (>= strength u100) (>= durability u80) composition-verified)))
      (map-set test-results (tuple (material-id material-id) (test-id test-id))
        {
          tester: tx-sender,
          test-date: block-height,
          strength: strength,
          durability: durability,
          composition-verified: composition-verified,
          passed: passed
        }
      )
      (ok passed)
    )
  )
)

;; Map to store authorized testers
(define-map authorized-testers principal bool)

;; Function to add an authorized tester
(define-public (add-authorized-tester (tester principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can add testers
    (map-set authorized-testers tester true)
    (ok true)
  )
)

;; Function to remove an authorized tester
(define-public (remove-authorized-tester (tester principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can remove testers
    (map-delete authorized-testers tester)
    (ok true)
  )
)

;; Read-only function to check if a principal is an authorized tester
(define-read-only (is-authorized-tester (tester principal))
  (default-to false (map-get? authorized-testers tester))
)

;; Read-only function to get test results
(define-read-only (get-test-results (material-id (string-utf8 36)) (test-id (string-utf8 36)))
  (map-get? test-results (tuple (material-id material-id) (test-id test-id)))
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (var-set admin new-admin)
    (ok true)
  )
)
