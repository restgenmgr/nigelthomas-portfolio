(() => {
    "use strict";

    /*
     * Nigel Thomas Accounting Dashboard
     * Clean UTF-8 version
     *
     * CHANGE (Aug 2026): UPI Payments is NO LONGER a spendable
     * account with its own balance. Paytm/GPay/PhonePe/UPI never
     * held their own money - they were always just a rail on top
     * of Canara/IDBI. Treating "UPI Payments" as an account meant
     * a two-step Transfer -> Expense flow, and the "Monthly Expense
     * (UPI)" report card was accidentally just duplicating the
     * overall "Monthly Expense" number (see old setText calls for
     * todayExpense2 / monthExpense2 - they reused fmt(todayExpense)
     * and fmt(monthExpense) instead of filtering by UPI).
     *
     * NEW MODEL:
     * - Real spendable accounts: Canara Bank, IDBI Bank, Cash on Hand.
     * - Every expense/income is logged directly against one of those.
     * - A transaction can optionally be tagged payment_method: "upi"
     *   when it was paid/received via Paytm/GPay/PhonePe. The rupees
     *   still move on the real account immediately - "UPI" is only
     *   a label used for the UPI report cards.
     *
     * Accounts:
     * 1. Canara Bank
     * 2. IDBI Bank
     * 3. Cash on Hand
     */

    const ACCOUNTS = [
        { id: "canara", name: "Canara Bank", icon: "BANK" },
        { id: "idbi", name: "IDBI Bank", icon: "BANK" },
        { id: "cash", name: "Cash on Hand", icon: "CASH" }
    ];

    // Names for old account ids that no longer exist as real
    // accounts, so transaction history still displays sensibly.
    const LEGACY_ACCOUNT_NAMES = {
        upi: "UPI Payments (legacy)",
        paytm: "Paytm (legacy)",
        gpay: "GPay (legacy)",
        phonepe: "PhonePe (legacy)"
    };

    const KEY = "nigel_accounting_v1";

    const fmt = (number) =>
        new Intl.NumberFormat("en-IN", {
            style: "currency",
            currency: "INR",
            maximumFractionDigits: 2
        }).format(Number(number) || 0);

    const nowISO = () => new Date().toISOString();

    const todayKey = () =>
        new Date().toLocaleDateString("en-CA");

    const monthKey = () =>
        todayKey().slice(0, 7);

    let state = loadState();
    let currentType = "expense";

    // Set during load if there's a leftover UPI balance from the
    // old model that needs a human decision about which real
    // account it actually belongs to.
    let pendingUPIMigrationAmount = null;


    /* =========================================================
       DEFAULT STATE
       ========================================================= */

    function defaultState() {
        const accounts = {};

        ACCOUNTS.forEach(account => {
            accounts[account.id] = {
                ...account,
                balance: 0
            };
        });

        return {
            accounts,
            transactions: []
        };
    }


    /* =========================================================
       LOAD / MIGRATE DATA
       ========================================================= */

    function loadState() {
        try {
            const saved = JSON.parse(
                localStorage.getItem(KEY)
            );

            if (
                saved &&
                saved.accounts &&
                Array.isArray(saved.transactions)
            ) {

                const oldAccounts = saved.accounts;

                // Any leftover balance sitting in a legacy UPI-type
                // account (upi / paytm / gpay / phonepe) can't be
                // safely folded into Canara vs IDBI vs Cash
                // automatically - only you know which one it really
                // belongs to. Surface it instead of guessing.
                const legacyIds = [
                    "upi",
                    "paytm",
                    "gpay",
                    "phonepe"
                ];

                const legacyLeftover =
                    legacyIds.reduce(
                        (sum, id) =>
                            sum +
                            Number(
                                oldAccounts[id]?.balance || 0
                            ),
                        0
                    );

                if (legacyLeftover !== 0) {
                    pendingUPIMigrationAmount = legacyLeftover;
                }

                const accounts = {};

                ACCOUNTS.forEach(account => {

                    accounts[account.id] = {
                        ...account,
                        balance: Number(
                            oldAccounts[account.id]?.balance || 0
                        )
                    };
                });


                /*
                 * Convert old transactions. Legacy account ids are
                 * kept as-is (not remapped to a real account) so
                 * history stays accurate - they display via
                 * LEGACY_ACCOUNT_NAMES instead of being editable.
                 * If a legacy transaction didn't already carry a
                 * payment_method, tag it "upi" so it still counts
                 * toward historical UPI reporting.
                 */

                const transactions =
                    saved.transactions.map(transaction => {

                        const converted = {
                            ...transaction
                        };

                        if (
                            legacyIds.includes(
                                converted.account_id
                            ) &&
                            !converted.payment_method
                        ) {
                            converted.payment_method = "upi";
                        }

                        if (!converted.payment_method) {
                            converted.payment_method = null;
                        }

                        return converted;
                    });


                return {
                    accounts,
                    transactions
                };
            }

        } catch (error) {
            console.warn(
                "Could not load accounting data.",
                error
            );
        }

        return defaultState();
    }


    /* =========================================================
       SAVE
       ========================================================= */

    function saveState() {
        localStorage.setItem(
            KEY,
            JSON.stringify(state)
        );
    }


    /* =========================================================
       ACCOUNT HELPERS
       ========================================================= */

    function accountName(id) {

        return (
            state.accounts[id]?.name ||
            LEGACY_ACCOUNT_NAMES[id] ||
            id ||
            ""
        );
    }


    function totalBalance() {

        return Object.values(
            state.accounts
        ).reduce(
            (sum, account) =>
                sum +
                Number(account.balance || 0),
            0
        );
    }


    /* =========================================================
       RENDER ACCOUNT CARDS
       ========================================================= */

    function renderAccounts() {

        const grid =
            document.getElementById(
                "accountsGrid"
            );

        if (!grid) {
            return;
        }

        grid.innerHTML = "";

        Object.values(
            state.accounts
        ).forEach(account => {

            const card =
                document.createElement(
                    "article"
                );

            card.className =
                "account-card";

            card.innerHTML = `
                <div class="account-name">
                    <span class="account-icon">
                        ${escapeHTML(account.icon)}
                    </span>
                    ${escapeHTML(account.name)}
                </div>

                <div class="account-balance">
                    ${fmt(account.balance)}
                </div>
            `;

            grid.appendChild(card);
        });


        // Derived, read-only UPI card - NOT a real balance, NOT
        // included in totalBalance(). It just shows this month's
        // spend that was tagged as paid via UPI, for visibility.
        const upiCard =
            document.createElement(
                "article"
            );

        upiCard.className =
            "account-card account-card-derived";

        upiCard.innerHTML = `
            <div class="account-name">
                <span class="account-icon">UPI</span>
                UPI Payments (this month, informational)
            </div>

            <div class="account-balance">
                ${fmt(upiMonthExpenseTotal())}
            </div>
        `;

        grid.appendChild(upiCard);


        const total =
            document.getElementById(
                "totalBalance"
            );

        if (total) {
            total.textContent =
                fmt(totalBalance());
        }


        const updated =
            document.getElementById(
                "balanceUpdated"
            );

        if (updated) {
            updated.textContent =
                "Updated " +
                new Date().toLocaleTimeString(
                    "en-IN",
                    {
                        hour: "2-digit",
                        minute: "2-digit"
                    }
                );
        }
    }


    /* =========================================================
       ACCOUNT SELECTS
       ========================================================= */

    function populateAccountSelects() {

        const selects = [
            document.getElementById(
                "accountSelect"
            ),

            document.getElementById(
                "toAccountSelect"
            ),

            document.getElementById(
                "filterAccount"
            )
        ];


        selects.forEach(select => {

            if (!select) {
                return;
            }

            const isFilter =
                select.id === "filterAccount";

            const firstOption =
                isFilter
                    ? `<option value="">All accounts</option>`
                    : "";

            select.innerHTML =
                firstOption +
                Object.values(
                    state.accounts
                )
                    .map(account => `
                        <option value="${account.id}">
                            ${escapeHTML(account.name)}
                        </option>
                    `)
                    .join("");
        });
    }


    /* =========================================================
       TRANSACTION TYPE
       ========================================================= */

    function setType(type) {

        currentType = type;

        const hiddenType =
            document.getElementById(
                "transactionType"
            );

        if (hiddenType) {
            hiddenType.value = type;
        }


        document
            .querySelectorAll(".tab")
            .forEach(button => {

                button.classList.toggle(
                    "active",
                    button.dataset.type === type
                );
            });


        const categoryWrap =
            document.getElementById(
                "categoryWrap"
            );

        const toWrap =
            document.getElementById(
                "toAccountWrap"
            );

        const upiWrap =
            document.getElementById(
                "upiTagWrap"
            );

        const saveButton =
            document.getElementById(
                "saveBtn"
            );


        if (categoryWrap) {
            categoryWrap.classList.toggle(
                "hidden",
                type !== "expense"
            );
        }


        if (toWrap) {
            toWrap.classList.toggle(
                "hidden",
                type !== "transfer"
            );
        }


        // The "Paid via UPI" tag only makes sense for expense
        // and income - a transfer between your own accounts
        // isn't a UPI payment.
        if (upiWrap) {
            upiWrap.classList.toggle(
                "hidden",
                type === "transfer"
            );
        }


        if (saveButton) {

            if (type === "expense") {
                saveButton.textContent =
                    "SAVE EXPENSE";
            }

            else if (type === "income") {
                saveButton.textContent =
                    "SAVE REVENUE";
            }

            else {
                saveButton.textContent =
                    "SAVE TRANSFER";
            }
        }
    }


    /* =========================================================
       RESET ENTRY FORM
       ========================================================= */

    function resetEntry() {

        const rupees =
            document.getElementById(
                "rupees"
            );

        const paisa =
            document.getElementById(
                "paisa"
            );

        const description =
            document.getElementById(
                "description"
            );

        const message =
            document.getElementById(
                "formMessage"
            );

        const upiCheckbox =
            document.getElementById(
                "paidViaUPI"
            );


        if (rupees) {
            rupees.value = "";
        }

        if (paisa) {
            paisa.value = "";
        }

        if (description) {
            description.value = "";
        }

        if (message) {
            message.textContent = "";
        }

        if (upiCheckbox) {
            upiCheckbox.checked = false;
        }

        if (rupees) {
            rupees.focus();
        }
    }


    /* =========================================================
       ADD TRANSACTION
       ========================================================= */

    function addTransaction(event) {

        event.preventDefault();

        const type =
            currentType;

        const accountSelect =
            document.getElementById(
                "accountSelect"
            );

        const toAccountSelect =
            document.getElementById(
                "toAccountSelect"
            );

        const rupeesInput =
            document.getElementById(
                "rupees"
            );

        const paisaInput =
            document.getElementById(
                "paisa"
            );

        const descriptionInput =
            document.getElementById(
                "description"
            );

        const upiCheckbox =
            document.getElementById(
                "paidViaUPI"
            );


        const accountId =
            accountSelect?.value;

        const toAccountId =
            toAccountSelect?.value;

        const rupees =
            Number(
                rupeesInput?.value || 0
            );

        const paisa =
            Number(
                paisaInput?.value || 0
            );

        // Only meaningful for expense/income - forced false for
        // transfers regardless of checkbox state.
        const paymentMethod =
            type !== "transfer" &&
            upiCheckbox?.checked
                ? "upi"
                : null;


        if (
            !Number.isInteger(rupees) ||
            rupees < 0
        ) {
            showMessage(
                "Enter valid Rupees.",
                true
            );

            return;
        }


        if (
            !Number.isInteger(paisa) ||
            paisa < 0 ||
            paisa > 99
        ) {
            showMessage(
                "Paisa must be between 00 and 99.",
                true
            );

            return;
        }


        const amount =
            rupees +
            paisa / 100;


        const category =
            type === "expense"
                ? document.getElementById(
                    "category"
                  )?.value || "General"

                : type === "income"
                    ? "Revenue"
                    : "Transfer";


        const description =
            descriptionInput?.value
                ?.trim() || "";


        if (
            !Number.isFinite(amount) ||
            amount <= 0
        ) {
            showMessage(
                "Enter a valid amount.",
                true
            );

            return;
        }


        if (!state.accounts[accountId]) {

            showMessage(
                "Select an account.",
                true
            );

            return;
        }


        if (type === "transfer") {

            if (
                !state.accounts[toAccountId]
            ) {
                showMessage(
                    "Select the receiving account.",
                    true
                );

                return;
            }


            if (
                accountId === toAccountId
            ) {
                showMessage(
                    "Choose two different accounts.",
                    true
                );

                return;
            }


            if (
                state.accounts[accountId]
                    .balance < amount
            ) {
                showMessage(
                    "Insufficient balance for this transfer.",
                    true
                );

                return;
            }
        }


        if (
            type === "expense" &&
            state.accounts[accountId]
                .balance < amount
        ) {
            showMessage(
                "Insufficient balance for this expense.",
                true
            );

            return;
        }


        if (type === "expense") {

            state.accounts[
                accountId
            ].balance -= amount;
        }


        if (type === "income") {

            state.accounts[
                accountId
            ].balance += amount;
        }


        if (type === "transfer") {

            state.accounts[
                accountId
            ].balance -= amount;

            state.accounts[
                toAccountId
            ].balance += amount;
        }


        const transactionId =
            window.crypto &&
            typeof window.crypto.randomUUID ===
                "function"

                ? window.crypto.randomUUID()

                : String(Date.now()) +
                  Math.random();


        state.transactions.unshift({

            id: transactionId,

            created_at:
                nowISO(),

            transaction_date:
                nowISO(),

            account_id:
                accountId,

            to_account_id:
                type === "transfer"
                    ? toAccountId
                    : null,

            transaction_type:
                type,

            payment_method:
                paymentMethod,

            amount:
                amount,

            category:
                category,

            description:
                description
        });


        saveState();

        renderAll();


        if (type === "expense") {

            showMessage(
                fmt(amount) +
                " expense saved." +
                (paymentMethod === "upi"
                    ? " (tagged UPI)"
                    : "")
            );
        }

        else if (type === "income") {

            showMessage(
                fmt(amount) +
                " revenue saved." +
                (paymentMethod === "upi"
                    ? " (tagged UPI)"
                    : "")
            );
        }

        else {

            showMessage(
                fmt(amount) +
                " transfer saved."
            );
        }


        resetEntry();
    }


    /* =========================================================
       MESSAGE
       ========================================================= */

    function showMessage(
        text,
        error = false
    ) {

        const element =
            document.getElementById(
                "formMessage"
            );

        if (!element) {
            return;
        }

        element.textContent =
            text;

        element.classList.toggle(
            "error",
            error
        );
    }


    /* =========================================================
       FILTER TRANSACTIONS
       ========================================================= */

    function filteredTransactions() {

        const accountFilter =
            document.getElementById(
                "filterAccount"
            )?.value || "";

        const typeFilter =
            document.getElementById(
                "filterType"
            )?.value || "";


        return state.transactions.filter(
            transaction => {

                const accountMatches =
                    !accountFilter ||
                    transaction.account_id ===
                        accountFilter ||
                    transaction.to_account_id ===
                        accountFilter;


                const typeMatches =
                    !typeFilter ||
                    transaction.transaction_type ===
                        typeFilter;


                return (
                    accountMatches &&
                    typeMatches
                );
            }
        );
    }


    /* =========================================================
       RENDER TRANSACTIONS
       ========================================================= */

    function renderTransactions() {

        const body =
            document.getElementById(
                "transactionsBody"
            );

        if (!body) {
            return;
        }


        const rows =
            filteredTransactions()
                .slice(0, 100);


        body.innerHTML = "";


        const empty =
            document.getElementById(
                "emptyState"
            );

        if (empty) {

            empty.classList.toggle(
                "hidden",
                rows.length > 0
            );
        }


        rows.forEach(transaction => {

            const tr =
                document.createElement(
                    "tr"
                );


            const date =
                new Date(
                    transaction.transaction_date
                );


            let typeLabel;

            if (
                transaction.transaction_type ===
                "income"
            ) {
                typeLabel = "Revenue";
            }

            else {
                typeLabel =
                    transaction
                        .transaction_type
                        .charAt(0)
                        .toUpperCase() +
                    transaction
                        .transaction_type
                        .slice(1);
            }

            if (transaction.payment_method === "upi") {
                typeLabel += " (UPI)";
            }


            let amountSign = "";

            if (
                transaction.transaction_type ===
                "expense"
            ) {
                amountSign = "-";
            }

            else if (
                transaction.transaction_type ===
                "income"
            ) {
                amountSign = "+";
            }

            else {
                amountSign = "TRANSFER";
            }


            let accountLabel;

            if (
                transaction.transaction_type ===
                "transfer"
            ) {

                accountLabel =
                    accountName(
                        transaction.account_id
                    ) +
                    " -> " +
                    accountName(
                        transaction.to_account_id
                    );
            }

            else {

                accountLabel =
                    accountName(
                        transaction.account_id
                    );
            }


            tr.innerHTML = `

                <td>
                    ${date.toLocaleDateString("en-IN")}
                    ${date.toLocaleTimeString(
                        "en-IN",
                        {
                            hour: "2-digit",
                            minute: "2-digit"
                        }
                    )}
                </td>

                <td>
                    ${escapeHTML(accountLabel)}
                </td>

                <td>
                    ${escapeHTML(typeLabel)}
                </td>

                <td class="amount-${escapeHTML(
                    transaction.transaction_type
                )}">
                    ${amountSign}
                    ${fmt(transaction.amount)}
                </td>

                <td>
                    ${escapeHTML(
                        transaction.category || ""
                    )}
                </td>

                <td>
                    ${escapeHTML(
                        transaction.description ||
                        "No description"
                    )}
                </td>

                <td>
                    <button
                        class="delete-btn"
                        data-id="${escapeHTML(
                            transaction.id
                        )}"
                        type="button"
                        title="Delete transaction"
                    >
                        Delete
                    </button>
                </td>

            `;


            body.appendChild(tr);
        });
    }


    /* =========================================================
       DELETE TRANSACTION
       ========================================================= */

    function deleteTransaction(id) {

        const transaction =
            state.transactions.find(
                item => item.id === id
            );


        if (!transaction) {
            return;
        }


        if (
            !confirm(
                "Delete this transaction? The affected balances will be reversed."
            )
        ) {
            return;
        }


        // Legacy transactions may reference an account id that no
        // longer exists (e.g. old "upi" account) - only reverse
        // the balance if that account still exists today.

        if (
            transaction.transaction_type ===
            "expense" &&
            state.accounts[transaction.account_id]
        ) {

            state.accounts[
                transaction.account_id
            ].balance +=
                transaction.amount;
        }


        if (
            transaction.transaction_type ===
            "income" &&
            state.accounts[transaction.account_id]
        ) {

            state.accounts[
                transaction.account_id
            ].balance -=
                transaction.amount;
        }


        if (
            transaction.transaction_type ===
            "transfer"
        ) {

            if (state.accounts[transaction.account_id]) {
                state.accounts[
                    transaction.account_id
                ].balance +=
                    transaction.amount;
            }

            if (state.accounts[transaction.to_account_id]) {
                state.accounts[
                    transaction.to_account_id
                ].balance -=
                    transaction.amount;
            }
        }


        state.transactions =
            state.transactions.filter(
                item => item.id !== id
            );


        saveState();

        renderAll();
    }


    /* =========================================================
       REPORTS
       ========================================================= */

    function sumByPeriod(
        type,
        period,
        upiOnly = false
    ) {

        const today =
            todayKey();

        const month =
            monthKey();

        const target =
            period === "day"
                ? today
                : month;


        return state.transactions
            .filter(transaction => {

                if (
                    transaction.transaction_type !==
                    type
                ) {
                    return false;
                }

                if (
                    upiOnly &&
                    transaction.payment_method !== "upi"
                ) {
                    return false;
                }


                const date =
                    transaction
                        .transaction_date
                        .slice(
                            0,
                            period === "day"
                                ? 10
                                : 7
                        );


                return date === target;
            })
            .reduce(
                (total, transaction) =>
                    total +
                    Number(
                        transaction.amount || 0
                    ),
                0
            );
    }


    function upiMonthExpenseTotal() {
        return sumByPeriod("expense", "month", true);
    }


    function renderReports() {

        const todayIncome =
            sumByPeriod("income", "day");

        const todayExpense =
            sumByPeriod("expense", "day");

        const monthIncome =
            sumByPeriod("income", "month");

        const monthExpense =
            sumByPeriod("expense", "month");

        // FIX: these two used to duplicate todayExpense /
        // monthExpense. Now they're genuinely UPI-only totals.
        const todayExpenseUPI =
            sumByPeriod("expense", "day", true);

        const monthExpenseUPI =
            sumByPeriod("expense", "month", true);


        setText(
            "todayIncome",
            fmt(todayIncome)
        );

        setText(
            "todayExpense",
            fmt(todayExpense)
        );

        setText(
            "todayExpense2",
            fmt(todayExpenseUPI)
        );

        setText(
            "monthIncome",
            fmt(monthIncome)
        );

        setText(
            "monthExpense",
            fmt(monthExpense)
        );

        setText(
            "monthExpense2",
            fmt(monthExpenseUPI)
        );
    }


    /* =========================================================
       BALANCE EDITOR
       ========================================================= */

    function openBalances() {

        const box =
            document.getElementById(
                "balanceInputs"
            );

        const dialog =
            document.getElementById(
                "balancesDialog"
            );


        if (!box || !dialog) {
            return;
        }


        box.innerHTML =
            Object.values(
                state.accounts
            )
                .map(account => `

                    <label class="balance-row">

                        <span>
                            ${escapeHTML(
                                account.icon
                            )}
                            ${escapeHTML(
                                account.name
                            )}
                        </span>

                        <input
                            type="number"
                            min="0"
                            step="0.01"
                            data-balance="${escapeHTML(
                                account.id
                            )}"
                            value="${Number(
                                account.balance
                            ).toFixed(2)}"
                        >

                    </label>

                `)
                .join("");


        dialog.showModal();


        if (pendingUPIMigrationAmount !== null) {

            alert(
                "Heads up: your old UPI Payments account had a " +
                "balance of " +
                fmt(pendingUPIMigrationAmount) +
                " left over from before this update. UPI is no " +
                "longer tracked as a separate account, so please " +
                "add that amount to whichever real account " +
                "(Canara, IDBI, or Cash) it actually belongs to, " +
                "right here in Edit Balances. This reminder will " +
                "not show again once you save."
            );

            pendingUPIMigrationAmount = null;
        }
    }


    /* =========================================================
       SAVE BALANCES
       ========================================================= */

    function saveBalances(event) {

        event.preventDefault();


        document
            .querySelectorAll(
                "[data-balance]"
            )
            .forEach(input => {

                const id =
                    input.dataset.balance;

                const value =
                    Number(input.value);


                if (
                    Number.isFinite(value) &&
                    value >= 0 &&
                    state.accounts[id]
                ) {

                    state.accounts[
                        id
                    ].balance = value;
                }
            });


        saveState();


        const dialog =
            document.getElementById(
                "balancesDialog"
            );

        if (dialog) {
            dialog.close();
        }


        renderAll();
    }


    /* =========================================================
       RESET
       ========================================================= */

    function resetDemo() {

        if (
            !confirm(
                "Reset all demo balances and transactions?"
            )
        ) {
            return;
        }


        state =
            defaultState();


        saveState();

        renderAll();

        openBalances();
    }


    /* =========================================================
       SAFE HTML
       ========================================================= */

    function escapeHTML(value) {

        return String(value)
            .replace(
                /[&<>"']/g,
                character => {

                    const replacements = {
                        "&": "&amp;",
                        "<": "&lt;",
                        ">": "&gt;",
                        '"': "&quot;",
                        "'": "&#039;"
                    };

                    return (
                        replacements[
                            character
                        ] || character
                    );
                }
            );
    }


    /* =========================================================
       SET TEXT
       ========================================================= */

    function setText(
        id,
        value
    ) {

        const element =
            document.getElementById(id);

        if (element) {
            element.textContent =
                value;
        }
    }


    /* =========================================================
       RENDER EVERYTHING
       ========================================================= */

    function renderAll() {

        renderAccounts();

        populateAccountSelects();

        renderTransactions();

        renderReports();


        const mode =
            document.getElementById(
                "dataMode"
            );

        if (mode) {

            mode.textContent =
                window.ACCOUNTING_CONFIG?.USE_SUPABASE
                    ? "Cloud"
                    : "Demo";
        }
    }


    /* =========================================================
       EVENT LISTENERS
       ========================================================= */

    document
        .querySelectorAll(".tab")
        .forEach(button => {

            button.addEventListener(
                "click",
                () => {
                    setType(
                        button.dataset.type
                    );
                }
            );
        });


    const transactionForm =
        document.getElementById(
            "transactionForm"
        );

    if (transactionForm) {

        transactionForm.addEventListener(
            "submit",
            addTransaction
        );
    }


    const transactionBody =
        document.getElementById(
            "transactionsBody"
        );

    if (transactionBody) {

        transactionBody.addEventListener(
            "click",
            event => {

                const button =
                    event.target.closest(
                        "[data-id]"
                    );

                if (button) {

                    deleteTransaction(
                        button.dataset.id
                    );
                }
            }
        );
    }


    const filterAccount =
        document.getElementById(
            "filterAccount"
        );

    if (filterAccount) {

        filterAccount.addEventListener(
            "change",
            renderTransactions
        );
    }


    const filterType =
        document.getElementById(
            "filterType"
        );

    if (filterType) {

        filterType.addEventListener(
            "change",
            renderTransactions
        );
    }


    const editBalances =
        document.getElementById(
            "editBalancesBtn"
        );

    if (editBalances) {

        editBalances.addEventListener(
            "click",
            openBalances
        );
    }


    const balancesForm =
        document.getElementById(
            "balancesForm"
        );

    if (balancesForm) {

        balancesForm.addEventListener(
            "submit",
            saveBalances
        );
    }


    const cancelBalances =
        document.getElementById(
            "cancelBalances"
        );

    if (cancelBalances) {

        cancelBalances.addEventListener(
            "click",
            () => {

                const dialog =
                    document.getElementById(
                        "balancesDialog"
                    );

                if (dialog) {
                    dialog.close();
                }
            }
        );
    }


    const resetDemoButton =
        document.getElementById(
            "resetDemoBtn"
        );

    if (resetDemoButton) {

        resetDemoButton.addEventListener(
            "click",
            resetDemo
        );
    }


    /* =========================================================
       START
       ========================================================= */

    renderAll();

    setType("expense");


    /*
     * First run:
     * ask for the starting balances.
     */

    if (
        !localStorage.getItem(KEY)
    ) {

        setTimeout(
            openBalances,
            250
        );
    }

    else if (pendingUPIMigrationAmount !== null) {

        // Existing user upgrading from the old UPI-as-account
        // model - prompt them to fold the leftover balance in.
        setTimeout(
            openBalances,
            250
        );
    }

})();
