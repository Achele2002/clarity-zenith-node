;; ZenithNode Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-insufficient-stake (err u103))
(define-constant err-invalid-uptime (err u104))
(define-constant err-transfer-failed (err u105))
(define-constant err-cooldown-active (err u106))
(define-constant err-no-stake (err u107))

;; Data vars
(define-data-var min-stake-amount uint u10000)
(define-data-var total-nodes uint u0)
(define-data-var cooldown-blocks uint u100)

;; Data maps
(define-map nodes principal 
  {
    status: (string-ascii 20),
    stake: uint,
    rewards: uint,
    uptime: uint,
    last-active: uint,
    withdrawal-block: uint
  }
)

;; Register new node
(define-public (register-node (stake-amount uint))
  (let ((node-data (map-get? nodes tx-sender)))
    (asserts! (>= stake-amount (var-get min-stake-amount)) err-insufficient-stake)
    (asserts! (is-none node-data) err-already-registered)
    
    (match (stx-transfer? stake-amount tx-sender (as-contract tx-sender))
      success (begin
        (map-set nodes tx-sender {
          status: "active",
          stake: stake-amount,
          rewards: u0,
          uptime: u100,
          last-active: block-height,
          withdrawal-block: u0
        })
        
        (var-set total-nodes (+ (var-get total-nodes) u1))
        (ok true))
      error err-transfer-failed)
  )
)

;; Deregister node
(define-public (deregister-node)
  (let ((node-data (map-get? nodes tx-sender)))
    (asserts! (is-some node-data) err-not-registered)
    
    (map-delete nodes tx-sender)
    (var-set total-nodes (- (var-get total-nodes) u1))
    
    (match (as-contract 
      (stx-transfer? 
        (get stake (unwrap-panic node-data))
        tx-sender 
        tx-sender))
      success (ok true)
      error err-transfer-failed)
  )
)

;; Update node status
(define-public (update-status (new-status (string-ascii 20)))
  (let ((node-data (map-get? nodes tx-sender)))
    (asserts! (is-some node-data) err-not-registered)
    
    (map-set nodes tx-sender (merge (unwrap-panic node-data)
      {
        status: new-status,
        last-active: block-height
      }
    ))
    (ok true)
  )
)

;; Initiate stake withdrawal
(define-public (initiate-withdrawal)
  (let ((node-data (map-get? nodes tx-sender)))
    (asserts! (is-some node-data) err-not-registered)
    (asserts! (> (get stake (unwrap-panic node-data)) u0) err-no-stake)
    
    (map-set nodes tx-sender (merge (unwrap-panic node-data)
      {
        withdrawal-block: block-height
      }
    ))
    (ok true)
  )
)

;; Complete stake withdrawal
(define-public (complete-withdrawal)
  (let (
    (node-data (map-get? nodes tx-sender))
    (current-node (unwrap-panic (map-get? nodes tx-sender))))
    
    (asserts! (is-some node-data) err-not-registered)
    (asserts! (>= block-height (+ (get withdrawal-block current-node) (var-get cooldown-blocks))) err-cooldown-active)
    
    (match (as-contract 
      (stx-transfer? 
        (get stake current-node)
        tx-sender 
        tx-sender))
      success (begin
        (map-set nodes tx-sender (merge current-node
          {
            stake: u0,
            withdrawal-block: u0
          }
        ))
        (ok true))
      error err-transfer-failed)
  )
)

;; [Previous functions remain unchanged...]
