# STX-TokenTier -  Subscription Service Smart Contract

This smart contract implements a decentralized, blockchain-based subscription service using the [Clarity language](https://docs.stacks.co/write-smart-contracts/clarity-ref). It allows users to subscribe to and manage paid plans directly with STX tokens, while enabling the contract owner to administer plans and withdraw funds securely.

---

## 🚀 Features

- ✅ Add, update, and delete subscription plans (admin-only)
- ✅ Subscribe to a plan and pay in STX
- ✅ Cancel or renew an existing subscription
- ✅ Validate active subscriptions by block height
- ✅ Withdraw accumulated funds (admin-only)
- ✅ Input validation and proper error handling

---

## 🧱 Data Structures

### `subscription-plans` (Map)
Stores all available subscription plans.

```clojure
{ plan-id: uint } => 
{ 
  plan-name: (string-ascii 50), 
  subscription-duration: uint,     ;; in blocks
  plan-price: uint                 ;; STX tokens
}
```

### `user-subscriptions` (Map)
Tracks current user subscriptions and their expiry.

```clojure
{ subscriber: principal } => 
{ 
  subscribed-plan-id: uint, 
  subscription-start-block: uint, 
  subscription-end-block: uint 
}
```

---

## 🧪 Read-Only Functions

### `get-subscription-plan(plan-id)`
Returns metadata of a given plan.

### `get-user-subscription-details(subscriber)`
Returns a subscriber’s current subscription data.

### `is-subscription-active(subscriber)`
Checks if the subscription is currently active (`true` if end-block > `block-height`).

---

## 🔐 Private Functions

### `transfer-stx-tokens(amount, sender, recipient)`
Performs secure STX token transfer between addresses.

### `validate-plan-input(plan-name, duration, price)`
Ensures that input plan values are valid and within expected ranges.

---

## ✨ Public Functions

### `add-subscription-plan(plan-name, duration, price)`
Create a new subscription plan.  
🔒 Only callable by the **contract owner**.

### `update-subscription-plan(plan-id, plan-name, duration, price)`
Update the metadata of a given plan.  
🔒 Only callable by the **contract owner**.

### `delete-subscription-plan(plan-id)`
Remove an existing plan.  
🔒 Only callable by the **contract owner**.

### `subscribe-to-plan(plan-id)`
Subscribe to a plan, deducting STX from the user’s wallet and logging the subscription duration.

### `cancel-user-subscription()`
Cancel the current user's subscription.

### `renew-user-subscription()`
Renew the subscription to the same plan (if still available).

### `withdraw-contract-funds(amount)`
Withdraw specified STX tokens from the contract to the owner's wallet.  
🔒 Only callable by the **contract owner**.

---

## ⚠️ Error Codes

| Code        | Description                       |
|-------------|-----------------------------------|
| `u100`      | Owner-only access violation       |
| `u101`      | Resource not found                |
| `u102`      | Already exists                    |
| `u103`      | Insufficient STX balance          |
| `u104`      | Subscription has expired          |
| `u105`      | Invalid input                     |

---

## 🛡️ Access Control

The contract owner is initialized as `tx-sender` via the `CONTRACT-OWNER` constant, granting them elevated permissions to:

- Manage plans
- Withdraw contract funds

All other operations are available to any `principal` (user).

---

## 📈 Example Usage

```clarity
;; Add a new plan (admin)
(add-subscription-plan "Basic" u1000 u10)

;; Subscribe to a plan (user)
(subscribe-to-plan u1)

;; Check if the user’s subscription is active
(is-subscription-active 'ST123...user)

;; Withdraw funds from the contract (admin)
(withdraw-contract-funds u100)
```

---

## 📌 Deployment Notes

- Make sure to deploy this contract from the address that should act as the contract owner.
- Ensure all STX balances are sufficient for both the user and the contract during subscription/withdrawal calls.
- Integrate with a frontend interface to allow seamless UX for selecting and managing plans.

---

## 🧠 Improvements To Consider

- Add support for pausing/resuming subscriptions
- Enable multi-plan subscriptions
- Emit events for subscription state changes
- Allow price discounting or promotional periods

---

## 📄 License

This project is provided under the MIT License.

---

Let me know if you want a version formatted for GitHub or StackDocs!

---
