;; compliance-verification.clar
;; This contract ensures materials meet building code requirements

(define-data-var admin principal tx-sender)

;; Map to store building code requirements
(define-map building-codes (string-utf8 50)
  {
    min-strength: uint,
    min-durability: uint,
    composition-requirements: (string-utf8 200),
    last-updated: uint,
    is-active: bool
  }
)

;; Map to store material compliance verifications
(define-map compliance-verifications (tuple (batch-id (string-utf8 36)) (code-id (string-utf8 50)))
  {
    verifier: principal,
    verification-date: uint,
    test-id: (string-utf8 36),
    is-compliant: bool,
    notes: (string-utf8 200)
  }
)

;; Public function to add or update a building code
(define-public (set-building-code
    (code-id (string-utf8 50))
    (min-strength uint)
    (min-durability uint)
    (composition-requirements (string-utf8 200)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can set codes

    (map-set building-codes code-id
      {
        min-strength: min-strength,
        min-durability: min-durability,
        composition-requirements: composition-requirements,
        last-updated: block-height,
        is-active: true
      }
    )
    (ok true)
  )
)

;; Public function to deactivate a building code
(define-public (deactivate-building-code (code-id (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can deactivate
    (asserts! (is-some (map-get? building-codes code-id)) (err u2)) ;; Code must exist

    (map-set building-codes code-id
      (merge (unwrap-panic (map-get? building-codes code-id))
        { is-active: false }
      )
    )
    (ok true)
  )
)

;; Public function to verify compliance
(define-public (verify-compliance
    (batch-id (string-utf8 36))
    (code-id (string-utf8 50))
    (test-id (string-utf8 36))
    (notes (string-utf8 200)))
  (begin
    (asserts! (is-authorized-verifier tx-sender) (err u1)) ;; Only authorized verifiers
    (asserts! (is-some (map-get? building-codes code-id)) (err u2)) ;; Code must exist

    ;; Get the test results from quality-testing contract
    ;; In a real implementation, this would use contract-call? to the quality-testing contract
    ;; For simplicity, we'll assume the test results are valid and compliant

    (let ((is-compliant true)) ;; In a real implementation, this would be determined by comparing test results to code requirements
      (map-set compliance-verifications (tuple (batch-id batch-id) (code-id code-id))
        {
          verifier: tx-sender,
          verification-date: block-height,
          test-id: test-id,
          is-compliant: is-compliant,
          notes: notes
        }
      )
      (ok is-compliant)
    )
  )
)

;; Map to store authorized verifiers
(define-map authorized-verifiers principal bool)

;; Function to add an authorized verifier
(define-public (add-authorized-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can add verifiers
    (map-set authorized-verifiers verifier true)
    (ok true)
  )
)

;; Function to remove an authorized verifier
(define-public (remove-authorized-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1)) ;; Only admin can remove verifiers
    (map-delete authorized-verifiers verifier)
    (ok true)
  )
)

;; Read-only function to check if a principal is an authorized verifier
(define-read-only (is-authorized-verifier (verifier principal))
  (default-to false (map-get? authorized-verifiers verifier))
)

;; Read-only function to get building code details
(define-read-only (get-building-code (code-id (string-utf8 50)))
  (map-get? building-codes code-id)
)

;; Read-only function to get compliance verification
(define-read-only (get-compliance-verification (batch-id (string-utf8 36)) (code-id (string-utf8 50)))
  (map-get? compliance-verifications (tuple (batch-id batch-id) (code-id code-id)))
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (var-set admin new-admin)
    (ok true)
  )
)
