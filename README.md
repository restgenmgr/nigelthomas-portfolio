# Nigel Thomas — Private Accounting Dashboard V1

This is Version 1 of the private personal accounting dashboard for `nigelthomas.live`.

## Current V1
- Canara Bank
- IDBI Bank
- Cash on Hand
- Paytm
- GPay
- PhonePe
- Live total balance
- Income / Expense / Transfer
- Expense-category dropdown
- Quick expense entry
- Transaction history
- Daily / monthly summary
- Local demo persistence
- Supabase-ready schema and integration notes

## Important
The supplied V1 runs in **Demo Mode** using browser local storage so the interface can be tested immediately. It does **not** connect to GPay, PhonePe, Paytm, Canara Bank or IDBI and it does not request banking credentials.

For real private cloud synchronization between phone and laptop, configure Supabase using `supabase/schema.sql` and then connect the frontend using the values in `accounting/config.example.js`.

Do not put a Supabase service-role key in browser code. Only use the public anon/publishable key with Row Level Security enabled.

## Install in existing site

Copy the `accounting` folder into the root of the NigelThomas.live repository:

    /accounting/index.html
    /accounting/app.js
    /accounting/styles.css
    /accounting/config.js

The dashboard can then be reached at:

    https://www.nigelthomas.live/accounting/

Protect the route with your chosen authentication/rewrite mechanism before putting real financial data into it.

## Supabase setup

1. Create a Supabase project.
2. Run `supabase/schema.sql` in the Supabase SQL editor.
3. Enable Email/Password authentication.
4. Copy `accounting/config.example.js` to `accounting/config.js`.
5. Put only the Supabase project URL and public anon/publishable key in `config.js`.
6. Set `USE_SUPABASE = true`.
7. Test authentication and Row Level Security.
8. Never commit secrets or service-role keys.

## Accounting rules

- Income increases an account.
- Expense decreases an account.
- Transfer decreases one account and increases another by the same amount.
- Transfers do not change total available money.
- An online payment is an expense, not revenue.
- Future credit-card support is inactive in V1.
