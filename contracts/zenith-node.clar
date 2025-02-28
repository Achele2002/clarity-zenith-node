;; ZenithNode Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-insufficient-stake (err u103))
(define-constant err-invalid-uptime (err u104))
(define-constant err-transfer-failed (err u105))

;; Data vars
(define-data-var min-stake-amount uint u10000)
(define-data-var total-nodes uint u0)

;; Data maps
(define-map nodes principal 
  {
    status: (string-ascii 20),
    stake: uint,
    rewards: uint,
    uptime: uint,
    last-active: uint
  }
)

;; Register new node
(define-public (register-node (stake-amount uint))
  (let ((node-data (map-get? nodes tx-sender)))
    (asserts! (>= stake-amount (var-get min-stake-amount)) err-insufficient-stake)
    (asserts! (is-none node-data) err-already-registered)
    
    ;; Transfer stake to contract
    (match (stx-transfer? stake-amount tx-sender (as-contract tx-sender))
      success (begin
        (map-set nodes tx-sender {
          status: "active",
          stake: stake-amount,
          rewards: u0,
          uptime: u100,
          last-active: block-height
        })
        
        (var-set total-nodes (+ (var-get total-nodes) u1))
        (ok true))
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

;; Get node info
(define-read-only (get-node-info (node principal))
  (ok (map-get? nodes node))
)

;; Get total nodes
(define-read-only (get-total-nodes)
  (ok (var-get total-nodes))
)

;; Add stake to node
(define-public (add-stake (amount uint))
  (let ((node-data (map-get? nodes tx-sender)))
    (asserts! (is-some node-data) err-not-registered)
    
    (match (stx-transfer? amount tx-sender (as-contract tx-sender))
      success (begin
        (map-set nodes tx-sender (merge (unwrap-panic node-data)
          {
            stake: (+ (get stake (unwrap-panic node-data)) amount)
          }
        ))
        (ok true))
      error err-transfer-failed)
  )
)

;; Update node metrics
(define-public (update-metrics (uptime uint))
  (let ((node-data (map-get? nodes tx-sender)))
    (asserts! (is-some node-data) err-not-registered)
    (asserts! (<= uptime u100) err-invalid-uptime)
    
    (map-set nodes tx-sender (merge (unwrap-panic node-data)
      {
        uptime: uptime,
        last-active: block-height
      }
    ))
    (ok true)
  )
)
