(() => {
  "use strict";

  const ACCOUNTS = [
    { id: "canara", name: "Canara Bank", icon: "🏦" },
    { id: "idbi", name: "IDBI Bank", icon: "🏦" },
    { id: "cash", name: "Cash on Hand", icon: "💵" },
    { id: "paytm", name: "Paytm", icon: "📱" },
    { id: "gpay", name: "GPay", icon: "📱" },
    { id: "phonepe", name: "PhonePe", icon: "📱" }
  ];

  const KEY = "nigel_accounting_v1";
  const fmt = n => new Intl.NumberFormat("en-IN", { style:"currency", currency:"INR", maximumFractionDigits:2 }).format(Number(n)||0);
  const nowISO = () => new Date().toISOString();
  const todayKey = () => new Date().toLocaleDateString("en-CA");
  const monthKey = () => todayKey().slice(0,7);

  let state = loadState();
  let currentType = "expense";

  function defaultState() {
    const accounts = {};
    ACCOUNTS.forEach(a => accounts[a.id] = { ...a, balance: 0 });
    return { accounts, transactions: [] };
  }

  function loadState() {
    try {
      const saved = JSON.parse(localStorage.getItem(KEY));
      if (saved?.accounts && saved?.transactions) return saved;
    } catch(e) {}
    return defaultState();
  }

  function saveState() {
    localStorage.setItem(KEY, JSON.stringify(state));
  }

  function accountName(id) { return state.accounts[id]?.name || id; }

  function totalBalance() {
    return Object.values(state.accounts).reduce((s,a)=>s+Number(a.balance||0),0);
  }

  function renderAccounts() {
    const grid = document.getElementById("accountsGrid");
    grid.innerHTML = "";
    Object.values(state.accounts).forEach(a => {
      const el = document.createElement("article");
      el.className = "account-card";
      el.innerHTML = `<div class="account-name"><span class="account-icon">${a.icon}</span>${escapeHTML(a.name)}</div>
        <div class="account-balance">${fmt(a.balance)}</div>`;
      grid.appendChild(el);
    });
    document.getElementById("totalBalance").textContent = fmt(totalBalance());
    document.getElementById("balanceUpdated").textContent = "Updated " + new Date().toLocaleTimeString("en-IN",{hour:"2-digit",minute:"2-digit"});
  }

  function populateAccountSelects() {
    const selects = [document.getElementById("accountSelect"), document.getElementById("toAccountSelect"), document.getElementById("filterAccount")];
    selects.forEach(s => {
      if (!s) return;
      const first = s.id === "filterAccount" ? `<option value="">All accounts</option>` : "";
      s.innerHTML = first + Object.values(state.accounts).map(a => `<option value="${a.id}">${a.icon} ${escapeHTML(a.name)}</option>`).join("");
    });
  }

  function setType(type) {
    currentType = type;
    document.getElementById("transactionType").value = type;
    document.querySelectorAll(".tab").forEach(b => b.classList.toggle("active", b.dataset.type === type));
    const categoryWrap = document.getElementById("categoryWrap");
    const toWrap = document.getElementById("toAccountWrap");
    const saveBtn = document.getElementById("saveBtn");
    categoryWrap.classList.toggle("hidden", type !== "expense");
    toWrap.classList.toggle("hidden", type !== "transfer");
    saveBtn.textContent = type === "expense" ? "SAVE EXPENSE" : type === "income" ? "SAVE REVENUE" : "SAVE TRANSFER";
  }

  function resetEntry() {
    document.getElementById("amount").value = "";
    document.getElementById("description").value = "";
    document.getElementById("formMessage").textContent = "";
    document.getElementById("amount").focus();
  }

  function addTransaction(e) {
    e.preventDefault();
    const type = currentType;
    const accountId = document.getElementById("accountSelect").value;
    const toAccountId = document.getElementById("toAccountSelect").value;
    const amount = Number(document.getElementById("amount").value);
    const category = type === "expense" ? document.getElementById("category").value : (type === "income" ? "Revenue" : "Transfer");
    const description = document.getElementById("description").value.trim();

    if (!Number.isFinite(amount) || amount <= 0) return showMessage("Enter a valid amount.", true);
    if (!state.accounts[accountId]) return showMessage("Select an account.", true);
    if (type === "transfer") {
      if (accountId === toAccountId) return showMessage("Choose two different accounts.", true);
      if (state.accounts[accountId].balance < amount) return showMessage("Insufficient balance for this transfer.", true);
    }
    if (type === "expense" && state.accounts[accountId].balance < amount) {
      return showMessage("Insufficient balance for this expense.", true);
    }

    if (type === "expense") state.accounts[accountId].balance -= amount;
    if (type === "income") state.accounts[accountId].balance += amount;
    if (type === "transfer") {
      state.accounts[accountId].balance -= amount;
      state.accounts[toAccountId].balance += amount;
    }

    state.transactions.unshift({
      id: crypto.randomUUID ? crypto.randomUUID() : String(Date.now()) + Math.random(),
      created_at: nowISO(),
      transaction_date: nowISO(),
      account_id: accountId,
      to_account_id: type === "transfer" ? toAccountId : null,
      transaction_type: type,
      amount,
      category,
      description
    });

    saveState();
    renderAll();
    showMessage(type === "expense" ? `${fmt(amount)} expense saved.` : type === "income" ? `${fmt(amount)} revenue saved.` : `${fmt(amount)} transfer saved.`);
    resetEntry();
  }

  function showMessage(text, error=false) {
    const el = document.getElementById("formMessage");
    el.textContent = text;
    el.classList.toggle("error", error);
  }

  function filteredTransactions() {
    const a = document.getElementById("filterAccount").value;
    const t = document.getElementById("filterType").value;
    return state.transactions.filter(x => (!a || x.account_id === a || x.to_account_id === a) && (!t || x.transaction_type === t));
  }

  function renderTransactions() {
    const body = document.getElementById("transactionsBody");
    const rows = filteredTransactions().slice(0,100);
    body.innerHTML = "";
    document.getElementById("emptyState").classList.toggle("hidden", rows.length > 0);
    rows.forEach(x => {
      const tr = document.createElement("tr");
      const d = new Date(x.transaction_date);
      const typeLabel = x.transaction_type === "income" ? "Revenue" : x.transaction_type[0].toUpperCase()+x.transaction_type.slice(1);
      const amountSign = x.transaction_type === "expense" ? "−" : x.transaction_type === "income" ? "+" : "↔";
      const accountLabel = x.transaction_type === "transfer"
        ? `${accountName(x.account_id)} → ${accountName(x.to_account_id)}`
        : accountName(x.account_id);
      tr.innerHTML = `
        <td>${d.toLocaleDateString("en-IN")} ${d.toLocaleTimeString("en-IN",{hour:"2-digit",minute:"2-digit"})}</td>
        <td>${escapeHTML(accountLabel)}</td>
        <td>${typeLabel}</td>
        <td class="amount-${x.transaction_type}">${amountSign} ${fmt(x.amount)}</td>
        <td>${escapeHTML(x.category || "")}</td>
        <td>${escapeHTML(x.description || "—")}</td>
        <td><button class="delete-btn" data-id="${x.id}" type="button" title="Delete transaction">Delete</button></td>`;
      body.appendChild(tr);
    });
  }

  function deleteTransaction(id) {
    const x = state.transactions.find(t => t.id === id);
    if (!x) return;
    if (!confirm("Delete this transaction? The affected balances will be reversed.")) return;

    if (x.transaction_type === "expense") state.accounts[x.account_id].balance += x.amount;
    if (x.transaction_type === "income") state.accounts[x.account_id].balance -= x.amount;
    if (x.transaction_type === "transfer") {
      state.accounts[x.account_id].balance += x.amount;
      state.accounts[x.to_account_id].balance -= x.amount;
    }

    state.transactions = state.transactions.filter(t => t.id !== id);
    saveState();
    renderAll();
  }

  function renderReports() {
    const today = todayKey(), month = monthKey();
    const sum = (type, period) => state.transactions.filter(x => x.transaction_type === type && x.transaction_date.slice(0,period==="day"?10:7) === (period==="day"?today:month)).reduce((s,x)=>s+x.amount,0);
    const ti = sum("income","day"), te = sum("expense","day"), mi = sum("income","month"), me = sum("expense","month");
    document.getElementById("todayIncome").textContent = fmt(ti);
    document.getElementById("todayExpense").textContent = fmt(te);
    document.getElementById("todayExpense2").textContent = fmt(te);
    document.getElementById("monthIncome").textContent = fmt(mi);
    document.getElementById("monthExpense").textContent = fmt(me);
    document.getElementById("monthExpense2").textContent = fmt(me);
  }

  function openBalances() {
    const box = document.getElementById("balanceInputs");
    box.innerHTML = Object.values(state.accounts).map(a => `
      <label class="balance-row">
        <span>${a.icon} ${escapeHTML(a.name)}</span>
        <input type="number" min="0" step="0.01" data-balance="${a.id}" value="${Number(a.balance).toFixed(2)}">
      </label>`).join("");
    document.getElementById("balancesDialog").showModal();
  }

  function saveBalances(e) {
    e.preventDefault();
    document.querySelectorAll("[data-balance]").forEach(input => {
      const id = input.dataset.balance;
      const val = Number(input.value);
      if (Number.isFinite(val) && val >= 0) state.accounts[id].balance = val;
    });
    saveState();
    document.getElementById("balancesDialog").close();
    renderAll();
  }

  function resetDemo() {
    if (!confirm("Reset all demo balances and transactions?")) return;
    state = defaultState();
    saveState();
    renderAll();
    openBalances();
  }

  function escapeHTML(value) {
    return String(value).replace(/[&<>"']/g, c => ({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[c]));
  }

  function renderAll() {
    renderAccounts();
    populateAccountSelects();
    renderTransactions();
    renderReports();
    document.getElementById("dataMode").textContent = window.ACCOUNTING_CONFIG?.USE_SUPABASE ? "Cloud" : "Demo";
  }

  document.querySelectorAll(".tab").forEach(b => b.addEventListener("click", () => setType(b.dataset.type)));
  document.getElementById("transactionForm").addEventListener("submit", addTransaction);
  document.getElementById("transactionsBody").addEventListener("click", e => {
    const btn = e.target.closest("[data-id]");
    if (btn) deleteTransaction(btn.dataset.id);
  });
  document.getElementById("filterAccount").addEventListener("change", renderTransactions);
  document.getElementById("filterType").addEventListener("change", renderTransactions);
  document.getElementById("editBalancesBtn").addEventListener("click", openBalances);
  document.getElementById("balancesForm").addEventListener("submit", saveBalances);
  document.getElementById("cancelBalances").addEventListener("click", () => document.getElementById("balancesDialog").close());
  document.getElementById("resetDemoBtn").addEventListener("click", resetDemo);

  renderAll();

  // First-run prompt. This only sets demo starting balances locally.
  if (!localStorage.getItem(KEY)) {
    setTimeout(openBalances, 250);
  }
})();
