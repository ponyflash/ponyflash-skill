# Account API Reference

## Methods

### `client.account.credits() -> CreditBalance`

Get current credit balance.

### `client.account.recharge(*, amount=NOT_GIVEN, redirect_url=NOT_GIVEN) -> RechargeResponse`

Get a recharge payment link.

## Parameters

### recharge()

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `amount` | `int` | No | — | Amount of credits to recharge |
| `redirect_url` | `str` | No | — | URL to redirect after payment |

## Return types

### CreditBalance

| Field | Type | Description |
|---|---|---|
| `balance` | `int` | Current credit balance |
| `currency` | `str` | Currency unit (default `"credits"`) |
| `updated_at` | `str \| None` | Last update timestamp |

### RechargeResponse

| Field | Type | Description |
|---|---|---|
| `recharge_url` | `str` | Payment page URL |
| `expires_at` | `str \| None` | Link expiration |

## Example

```python
bal = client.account.credits()
print(f"Balance: {bal.balance} {bal.currency}")

if bal.balance < 50:
    resp = client.account.recharge(amount=100)
    print(f"Recharge at: {resp.recharge_url}")
```
