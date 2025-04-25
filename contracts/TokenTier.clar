;; Subscription Service Contract

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-EXPIRED (err u104))
(define-constant ERR-INVALID-INPUT (err u105))

;; Data maps
(define-map subscription-plans
  { plan-id: uint }
  { plan-name: (string-ascii 50), subscription-duration: uint, plan-price: uint }
)

(define-map user-subscriptions
  { subscriber: principal }
  { subscribed-plan-id: uint, subscription-start-block: uint, subscription-end-block: uint }
)

;; Variables
(define-data-var next-available-plan-id uint u1)

;; Read-only functions
(define-read-only (get-subscription-plan (plan-id uint))
  (map-get? subscription-plans { plan-id: plan-id })
)

(define-read-only (get-user-subscription-details (subscriber principal))
  (map-get? user-subscriptions { subscriber: subscriber })
)

(define-read-only (is-subscription-active (subscriber principal))
  (match (get-user-subscription-details subscriber)
    subscription-details (> (get subscription-end-block subscription-details) block-height)
    false
  )
)

;; Private functions
(define-private (transfer-stx-tokens (amount uint) (sender principal) (recipient principal))
  (match (stx-transfer? amount sender recipient)
    transfer-success (ok true)
    transfer-error (err transfer-error)
  )
)

(define-private (validate-plan-input (plan-name (string-ascii 50)) (subscription-duration uint) (plan-price uint))
  (and
    (> (len plan-name) u0)
    (< (len plan-name) u51)
    (> subscription-duration u0)
    (> plan-price u0)
  )
)

;; Public functions
(define-public (add-subscription-plan (plan-name (string-ascii 50)) (subscription-duration uint) (plan-price uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (validate-plan-input plan-name subscription-duration plan-price) ERR-INVALID-INPUT)
    (let ((new-plan-id (var-get next-available-plan-id)))
      (asserts! (is-none (get-subscription-plan new-plan-id)) ERR-ALREADY-EXISTS)
      (map-set subscription-plans
        { plan-id: new-plan-id }
        { plan-name: plan-name, subscription-duration: subscription-duration, plan-price: plan-price }
      )
      (var-set next-available-plan-id (+ new-plan-id u1))
      (ok new-plan-id)
    )
  )
)

(define-public (update-subscription-plan (plan-id uint) (plan-name (string-ascii 50)) (subscription-duration uint) (plan-price uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (validate-plan-input plan-name subscription-duration plan-price) ERR-INVALID-INPUT)
    (asserts! (is-some (get-subscription-plan plan-id)) ERR-NOT-FOUND)
    (map-set subscription-plans
      { plan-id: plan-id }
      { plan-name: plan-name, subscription-duration: subscription-duration, plan-price: plan-price }
    )
    (ok true)
  )
)

(define-public (delete-subscription-plan (plan-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (is-some (get-subscription-plan plan-id)) ERR-NOT-FOUND)
    (map-delete subscription-plans { plan-id: plan-id })
    (ok true)
  )
)

(define-public (subscribe-to-plan (plan-id uint))
  (let (
    (selected-plan (unwrap! (get-subscription-plan plan-id) ERR-NOT-FOUND))
    (plan-price (get plan-price selected-plan))
    (subscription-duration (get subscription-duration selected-plan))
    (subscription-start-block block-height)
    (subscription-end-block (+ block-height subscription-duration))
  )
    (asserts! (>= (stx-get-balance tx-sender) plan-price) ERR-INSUFFICIENT-BALANCE)
    (match (transfer-stx-tokens plan-price tx-sender (as-contract tx-sender))
      transfer-success (begin
        (map-set user-subscriptions
          { subscriber: tx-sender }
          { subscribed-plan-id: plan-id, subscription-start-block: subscription-start-block, subscription-end-block: subscription-end-block }
        )
        (ok true)
      )
      transfer-error (err transfer-error)
    )
  )
)

(define-public (cancel-user-subscription)
  (begin
    (asserts! (is-some (get-user-subscription-details tx-sender)) ERR-NOT-FOUND)
    (map-delete user-subscriptions { subscriber: tx-sender })
    (ok true)
  )
)

(define-public (renew-user-subscription)
  (let (
    (current-subscription (unwrap! (get-user-subscription-details tx-sender) ERR-NOT-FOUND))
    (subscribed-plan-id (get subscribed-plan-id current-subscription))
    (subscription-plan (unwrap! (get-subscription-plan subscribed-plan-id) ERR-NOT-FOUND))
    (renewal-price (get plan-price subscription-plan))
    (renewal-duration (get subscription-duration subscription-plan))
    (new-subscription-end-block (+ block-height renewal-duration))
  )
    (asserts! (>= (stx-get-balance tx-sender) renewal-price) ERR-INSUFFICIENT-BALANCE)
    (match (transfer-stx-tokens renewal-price tx-sender (as-contract tx-sender))
      transfer-success (begin
        (map-set user-subscriptions
          { subscriber: tx-sender }
          { subscribed-plan-id: subscribed-plan-id, subscription-start-block: block-height, subscription-end-block: new-subscription-end-block }
        )
        (ok true)
      )
      transfer-error (err transfer-error)
    )
  )
)

(define-public (withdraw-contract-funds (withdrawal-amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (<= withdrawal-amount (stx-get-balance (as-contract tx-sender))) ERR-INSUFFICIENT-BALANCE)
    (match (transfer-stx-tokens withdrawal-amount (as-contract tx-sender) CONTRACT-OWNER)
      transfer-success (ok true)
      transfer-error (err transfer-error)
    )
  )
)
