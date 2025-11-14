;; title: Fractional-Ownership-of-Wells-or-Royalties

(define-non-fungible-token well-share uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-does-not-exist (err u103))
(define-constant err-no-dividends (err u104))
(define-constant err-transfer-failed (err u105))
(define-constant err-invalid-amount (err u106))
(define-constant err-already-claimed (err u107))
(define-constant err-insufficient-balance (err u108))
(define-constant err-not-listed (err u109))
(define-constant err-already-listed (err u110))
(define-constant err-invalid-price (err u111))
(define-constant err-no-offer (err u112))

(define-data-var total-shares uint u0)
(define-data-var total-revenue uint u0)
(define-data-var revenue-per-share uint u0)
(define-data-var dividend-period uint u144)
(define-data-var last-dividend-block uint u0)
(define-data-var well-name (string-ascii 50) "")
(define-data-var share-price uint u1000000)
(define-data-var revenue-pool uint u0)

(define-map share-owners uint principal)
(define-map owner-shares principal (list 100 uint))
(define-map claimed-dividends {owner: principal, period: uint} bool)
(define-map share-metadata uint {minted-at: uint, original-owner: principal})
(define-map dividend-history uint {amount: uint, block-height: uint, shares: uint})
(define-map pending-claims principal uint)
(define-map share-listings uint {seller: principal, price: uint, listed-at: uint})
(define-map share-offers {token-id: uint, buyer: principal} {price: uint, offered-at: uint})

(define-read-only (get-last-token-id)
  (ok (var-get total-shares))
)

(define-read-only (get-token-uri (token-id uint))
  (ok (some (var-get well-name)))
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? well-share token-id))
)

(define-read-only (get-total-shares)
  (ok (var-get total-shares))
)

(define-read-only (get-total-revenue)
  (ok (var-get total-revenue))
)

(define-read-only (get-revenue-per-share)
  (ok (var-get revenue-per-share))
)

(define-read-only (get-share-price)
  (ok (var-get share-price))
)

(define-read-only (get-well-name)
  (ok (var-get well-name))
)

(define-read-only (get-revenue-pool)
  (ok (var-get revenue-pool))
)

(define-read-only (get-dividend-period)
  (ok (var-get dividend-period))
)

(define-read-only (get-last-dividend-block)
  (ok (var-get last-dividend-block))
)

(define-read-only (get-share-metadata (token-id uint))
  (ok (map-get? share-metadata token-id))
)

(define-read-only (get-owner-shares (owner principal))
  (ok (default-to (list) (map-get? owner-shares owner)))
)

(define-read-only (get-pending-claims (owner principal))
  (ok (default-to u0 (map-get? pending-claims owner)))
)

(define-read-only (get-dividend-history (period uint))
  (ok (map-get? dividend-history period))
)

(define-read-only (has-claimed-dividend (owner principal) (period uint))
  (ok (default-to false (map-get? claimed-dividends {owner: owner, period: period})))
)

(define-read-only (get-listing (token-id uint))
  (ok (map-get? share-listings token-id))
)

(define-read-only (get-offer (token-id uint) (buyer principal))
  (ok (map-get? share-offers {token-id: token-id, buyer: buyer}))
)

(define-read-only (calculate-dividends (owner principal))
  (let
    (
      (shares (unwrap! (map-get? owner-shares owner) (ok u0)))
      (share-count (len shares))
      (current-revenue-per-share (var-get revenue-per-share))
    )
    (ok (* share-count current-revenue-per-share))
  )
)

(define-read-only (blocks-until-next-dividend)
  (let
    (
      (last-block (var-get last-dividend-block))
      (period (var-get dividend-period))
      (current-block stacks-block-height)
      (next-dividend-block (+ last-block period))
    )
    (ok (if (> next-dividend-block current-block)
          (- next-dividend-block current-block)
          u0))
  )
)

(define-public (initialize (name (string-ascii 50)) (price uint) (period uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (var-get total-shares) u0) err-already-exists)
    (var-set well-name name)
    (var-set share-price price)
    (var-set dividend-period period)
    (var-set last-dividend-block stacks-block-height)
    (ok true)
  )
)

(define-public (mint-share)
  (let
    (
      (token-id (+ (var-get total-shares) u1))
      (current-shares (default-to (list) (map-get? owner-shares tx-sender)))
    )
    (try! (stx-transfer? (var-get share-price) tx-sender contract-owner))
    (try! (nft-mint? well-share token-id tx-sender))
    (map-set share-owners token-id tx-sender)
    (map-set share-metadata token-id {
      minted-at: stacks-block-height,
      original-owner: tx-sender
    })
    (map-set owner-shares tx-sender (unwrap! (as-max-len? (append current-shares token-id) u100) err-invalid-amount))
    (var-set total-shares token-id)
    (ok token-id)
  )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (let
    (
      (owner (unwrap! (nft-get-owner? well-share token-id) err-does-not-exist))
      (sender-shares (default-to (list) (map-get? owner-shares sender)))
      (recipient-shares (default-to (list) (map-get? owner-shares recipient)))
    )
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    (asserts! (is-eq owner sender) err-not-token-owner)
    (try! (nft-transfer? well-share token-id sender recipient))
    (map-set share-owners token-id recipient)
    (map-set owner-shares sender (filter-share sender-shares token-id))
    (map-set owner-shares recipient (unwrap! (as-max-len? (append recipient-shares token-id) u100) err-invalid-amount))
    (ok true)
  )
)

(define-private (filter-share (shares (list 100 uint)) (token-id uint))
  (filter remove-token-id shares)
)

(define-private (remove-token-id (id uint))
  (not (is-eq id u0))
)

(define-public (add-revenue (amount uint))
  (let
    (
      (current-pool (var-get revenue-pool))
      (new-pool (+ current-pool amount))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-amount)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set revenue-pool new-pool)
    (var-set total-revenue (+ (var-get total-revenue) amount))
    (ok true)
  )
)

(define-public (distribute-dividends)
  (let
    (
      (current-block stacks-block-height)
      (last-block (var-get last-dividend-block))
      (period (var-get dividend-period))
      (pool (var-get revenue-pool))
      (shares (var-get total-shares))
      (per-share (if (> shares u0) (/ pool shares) u0))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= (- current-block last-block) period) err-invalid-amount)
    (asserts! (> pool u0) err-no-dividends)
    (asserts! (> shares u0) err-invalid-amount)
    (var-set revenue-per-share per-share)
    (var-set last-dividend-block current-block)
    (map-set dividend-history current-block {
      amount: pool,
      block-height: current-block,
      shares: shares
    })
    (ok true)
  )
)

(define-public (claim-dividends)
  (let
    (
      (shares (unwrap! (map-get? owner-shares tx-sender) err-does-not-exist))
      (share-count (len shares))
      (current-period (var-get last-dividend-block))
      (per-share (var-get revenue-per-share))
      (total-claim (* share-count per-share))
      (pool (var-get revenue-pool))
    )
    (asserts! (> share-count u0) err-does-not-exist)
    (asserts! (is-eq (default-to false (map-get? claimed-dividends {owner: tx-sender, period: current-period})) false) err-already-claimed)
    (asserts! (> total-claim u0) err-no-dividends)
    (asserts! (>= pool total-claim) err-insufficient-balance)
    (try! (as-contract (stx-transfer? total-claim tx-sender tx-sender)))
    (map-set claimed-dividends {owner: tx-sender, period: current-period} true)
    (var-set revenue-pool (- pool total-claim))
    (ok total-claim)
  )
)

(define-public (update-share-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-price u0) err-invalid-amount)
    (var-set share-price new-price)
    (ok true)
  )
)

(define-public (update-dividend-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-period u0) err-invalid-amount)
    (var-set dividend-period new-period)
    (ok true)
  )
)

(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-amount)
    (try! (as-contract (stx-transfer? amount tx-sender contract-owner)))
    (ok true)
  )
)

(define-public (list-share (token-id uint) (price uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? well-share token-id) err-does-not-exist))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (is-none (map-get? share-listings token-id)) err-already-listed)
    (asserts! (> price u0) err-invalid-price)
    (map-set share-listings token-id {
      seller: tx-sender,
      price: price,
      listed-at: stacks-block-height
    })
    (ok true)
  )
)

(define-public (cancel-listing (token-id uint))
  (let
    (
      (listing (unwrap! (map-get? share-listings token-id) err-not-listed))
      (seller (get seller listing))
    )
    (asserts! (is-eq tx-sender seller) err-not-token-owner)
    (map-delete share-listings token-id)
    (ok true)
  )
)

(define-public (buy-listed-share (token-id uint))
  (let
    (
      (listing (unwrap! (map-get? share-listings token-id) err-not-listed))
      (seller (get seller listing))
      (price (get price listing))
      (seller-shares (default-to (list) (map-get? owner-shares seller)))
      (buyer-shares (default-to (list) (map-get? owner-shares tx-sender)))
    )
    (try! (stx-transfer? price tx-sender seller))
    (try! (nft-transfer? well-share token-id seller tx-sender))
    (map-set share-owners token-id tx-sender)
    (map-set owner-shares seller (filter-share seller-shares token-id))
    (map-set owner-shares tx-sender (unwrap! (as-max-len? (append buyer-shares token-id) u100) err-invalid-amount))
    (map-delete share-listings token-id)
    (ok true)
  )
)

(define-public (make-offer (token-id uint) (price uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? well-share token-id) err-does-not-exist))
    )
    (asserts! (not (is-eq tx-sender owner)) err-not-token-owner)
    (asserts! (> price u0) err-invalid-price)
    (map-set share-offers {token-id: token-id, buyer: tx-sender} {
      price: price,
      offered-at: stacks-block-height
    })
    (ok true)
  )
)

(define-public (cancel-offer (token-id uint))
  (let
    (
      (offer (unwrap! (map-get? share-offers {token-id: token-id, buyer: tx-sender}) err-no-offer))
    )
    (map-delete share-offers {token-id: token-id, buyer: tx-sender})
    (ok true)
  )
)

(define-public (accept-offer (token-id uint) (buyer principal))
  (let
    (
      (owner (unwrap! (nft-get-owner? well-share token-id) err-does-not-exist))
      (offer (unwrap! (map-get? share-offers {token-id: token-id, buyer: buyer}) err-no-offer))
      (price (get price offer))
      (seller-shares (default-to (list) (map-get? owner-shares tx-sender)))
      (buyer-shares (default-to (list) (map-get? owner-shares buyer)))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (try! (stx-transfer? price buyer tx-sender))
    (try! (nft-transfer? well-share token-id tx-sender buyer))
    (map-set share-owners token-id buyer)
    (map-set owner-shares tx-sender (filter-share seller-shares token-id))
    (map-set owner-shares buyer (unwrap! (as-max-len? (append buyer-shares token-id) u100) err-invalid-amount))
    (map-delete share-offers {token-id: token-id, buyer: buyer})
    (if (is-some (map-get? share-listings token-id))
      (map-delete share-listings token-id)
      true
    )
    (ok true)
  )
)
