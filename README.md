# 🛢️ Fractional Ownership of Wells or Royalties

## 📋 Overview

A decentralized smart contract platform for fractional ownership of oil wells and production royalties. Investors purchase NFT-based shares representing ownership stakes in oil production, and receive periodic dividend distributions based on production revenue.

## ✨ Features

- 🎨 **NFT-Based Ownership**: Each share is represented as a unique NFT token
- 💰 **Dividend Distribution**: Automated periodic dividend payments to shareholders
- 🔄 **Transferable Shares**: Trade and transfer ownership shares freely
- 📊 **Revenue Tracking**: Complete transparency of production revenue
- ⚙️ **Configurable Parameters**: Adjustable share prices and dividend periods
- 🔐 **Secure Claims**: One-time dividend claims per period to prevent double-claiming

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone https://github.com/urenyz/Fractional-Ownership-of-Wells-or-Royalties.git
cd Fractional-Ownership-of-Wells-or-Royalties
clarinet check
```

## 📖 Usage Guide

### 1️⃣ Initialize the Well

First, the contract owner must initialize the well with a name, share price, and dividend period:

```clarity
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties initialize "Texas Oil Well #1" u1000000 u144)
```

**Parameters:**
- `name`: Well identifier (string-ascii 50)
- `price`: Share price in microSTX (uint)
- `period`: Blocks between dividend distributions (uint)

### 2️⃣ Purchase Shares

Investors can mint shares by paying the set share price:

```clarity
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties mint-share)
```

This will:
- Transfer the share price to the contract owner
- Mint a unique NFT share to the investor
- Track ownership for dividend distribution

### 3️⃣ Add Production Revenue

The contract owner adds revenue from oil production:

```clarity
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties add-revenue u10000000)
```

Revenue is pooled and prepared for distribution to shareholders.

### 4️⃣ Distribute Dividends

After the dividend period has elapsed, the owner distributes dividends:

```clarity
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties distribute-dividends)
```

This calculates the revenue per share and marks dividends as claimable.

### 5️⃣ Claim Dividends

Shareholders claim their dividends:

```clarity
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties claim-dividends)
```

Dividends are calculated based on the number of shares owned and can only be claimed once per period.

### 6️⃣ Transfer Shares

Shares can be transferred to other investors:

```clarity
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties transfer u1 tx-sender 'RECIPIENT-ADDRESS)
```

## 🔍 Read-Only Functions

### Query Contract State

```clarity
;; Get total shares issued
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties get-total-shares)

;; Get total revenue collected
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties get-total-revenue)

;; Get revenue per share
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties get-revenue-per-share)

;; Get current share price
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties get-share-price)

;; Get shares owned by an address
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties get-owner-shares 'ADDRESS)

;; Calculate dividends for an address
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties calculate-dividends 'ADDRESS)

;; Check blocks until next dividend
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties blocks-until-next-dividend)

;; Check if dividend was claimed
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties has-claimed-dividend 'ADDRESS u12345)
```

## 👨‍💼 Admin Functions

### Update Share Price

```clarity
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties update-share-price u2000000)
```

### Update Dividend Period

```clarity
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties update-dividend-period u288)
```

### Emergency Withdraw

```clarity
(contract-call? .Fractional-Ownership-of-Wells-or-Royalties emergency-withdraw u5000000)
```

## 🏗️ Contract Architecture

### Data Structures

- **NFTs**: `well-share` - Unique token for each share
- **Variables**: Track total shares, revenue, prices, and periods
- **Maps**: Store ownership, claims, dividends, and metadata

### Key Functions

1. **initialize**: Set up well parameters
2. **mint-share**: Purchase new shares
3. **transfer**: Transfer share ownership
4. **add-revenue**: Deposit production revenue
5. **distribute-dividends**: Calculate and enable claims
6. **claim-dividends**: Withdraw earned dividends

## 🔐 Security Features

- ✅ Owner-only administrative functions
- ✅ Double-claim prevention
- ✅ Balance validation before transfers
- ✅ Ownership verification for transfers
- ✅ Emergency withdrawal mechanism

## 💡 Example Workflow

1. **Day 1**: Owner initializes well with 1 STX per share, 144-block dividend period
2. **Day 2-5**: 10 investors each purchase 1 share (10 shares total)
3. **Day 6**: Owner adds 10 STX revenue from production
4. **Day 8**: After 144 blocks, owner distributes dividends (1 STX per share)
5. **Day 9**: Each investor claims 1 STX dividend
6. **Repeat**: Process continues for subsequent production periods

## 📊 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | err-owner-only | Function restricted to contract owner |
| u101 | err-not-token-owner | Caller doesn't own the token |
| u102 | err-already-exists | Well already initialized |
| u103 | err-does-not-exist | Token or record not found |
| u104 | err-no-dividends | No dividends available |
| u105 | err-transfer-failed | Transfer operation failed |
| u106 | err-invalid-amount | Amount must be greater than zero |
| u107 | err-already-claimed | Dividend already claimed for this period |
| u108 | err-insufficient-balance | Insufficient contract balance |

## 🧪 Testing

Run the test suite:

```bash
clarinet test
```

Check contract validity:

```bash
clarinet check
```

## 📄 License

MIT License - See LICENSE file for details

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## 📞 Support

For questions or issues, please open a GitHub issue in the repository.

---

**⚠️ Disclaimer**: This smart contract is for educational and demonstration purposes. Always conduct thorough audits before deploying to production environments.
