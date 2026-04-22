/**
 * RetailPro Analytics — Shared Utilities v3
 * script.js
 */

const API_BASE = "http://localhost:5000/api";

/* ── FORMATTERS ──────────────────────────────────────────────────────────── */
function formatCurrency(v) {
  const n = parseFloat(v) || 0;
  return "$" + n.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}
function formatNumber(v) { return (parseInt(v) || 0).toLocaleString("en-US"); }
function formatDate(s) {
  if (!s) return "—";
  return new Date(s).toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" });
}
function formatDateTime(s) {
  if (!s) return "—";
  return new Date(s).toLocaleString("en-US", { year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
}
function formatPercent(v, d = 1) { return (parseFloat(v) || 0).toFixed(d) + "%"; }

/* ── API FETCH ───────────────────────────────────────────────────────────── */
async function apiFetch(endpoint, options = {}) {
  const url = API_BASE + endpoint;
  const res = await fetch(url, {
    headers: { "Content-Type": "application/json" },
    ...options
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || body.message || `HTTP ${res.status}`);
  }
  return res.json();
}

/* ── TOAST NOTIFICATIONS ─────────────────────────────────────────────────── */
function showToast(message, type = "info") {
  let container = document.getElementById("toast-container");
  if (!container) {
    container = document.createElement("div");
    container.id = "toast-container";
    document.body.appendChild(container);
  }
  const icons = { success: "✓", error: "✕", warning: "⚠", info: "ℹ" };
  const toast = document.createElement("div");
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `<span class="toast-icon">${icons[type] || "ℹ"}</span><span>${message}</span>`;
  container.appendChild(toast);
  setTimeout(() => { toast.style.animation = "fadeOut 0.3s ease forwards"; setTimeout(() => toast.remove(), 300); }, 3800);
}
// Alias for backward compat
const showNotification = showToast;

/* ── MODAL ───────────────────────────────────────────────────────────────── */
function openModal(html) {
  closeModal();
  const backdrop = document.createElement("div");
  backdrop.className = "modal-backdrop";
  backdrop.id = "active-modal";
  backdrop.innerHTML = html;
  backdrop.addEventListener("click", e => { if (e.target === backdrop) closeModal(); });
  document.body.appendChild(backdrop);
  document.addEventListener("keydown", _escClose);
}
function closeModal() {
  const m = document.getElementById("active-modal");
  if (m) m.remove();
  document.removeEventListener("keydown", _escClose);
}
function _escClose(e) { if (e.key === "Escape") closeModal(); }

/* ── CONFIRM DIALOG ──────────────────────────────────────────────────────── */
function confirmDialog(message, title = "Confirm Action") {
  return new Promise(resolve => {
    const html = `
      <div class="confirm-dialog">
        <h3>${title}</h3>
        <p>${message}</p>
        <div class="confirm-actions">
          <button class="btn btn-ghost" id="confirm-no">Cancel</button>
          <button class="btn btn-danger" id="confirm-yes">Confirm</button>
        </div>
      </div>`;
    openModal(html);
    document.getElementById("confirm-yes").onclick = () => { closeModal(); resolve(true); };
    document.getElementById("confirm-no").onclick  = () => { closeModal(); resolve(false); };
  });
}

/* ── SKELETON LOADING ────────────────────────────────────────────────────── */
function showSkeleton(tbodyId, cols, rows = 5) {
  const tbody = document.getElementById(tbodyId);
  if (!tbody) return;
  const cells = Array(cols).fill(0).map((_, i) => {
    const w = [60, 80, 100, 70, 90, 50][i % 6];
    return `<td class="skeleton-row"><div class="skeleton skeleton-cell" style="width:${w}%"></div></td>`;
  }).join("");
  tbody.innerHTML = Array(rows).fill(`<tr class="skeleton-row">${cells}</tr>`).join("");
}
function hideSkeleton(tbodyId) {
  // Content replacement handles this — no-op
}

/* ── TABLE SORT ──────────────────────────────────────────────────────────── */
function makeSortable(tableId) {
  const table = document.getElementById(tableId);
  if (!table) return;
  const headers = table.querySelectorAll("thead th");
  let sortCol = -1, sortAsc = true;
  headers.forEach((th, idx) => {
    th.style.cursor = "pointer";
    th.addEventListener("click", () => {
      if (sortCol === idx) sortAsc = !sortAsc;
      else { sortCol = idx; sortAsc = true; }
      headers.forEach(h => { h.classList.remove("sort-asc", "sort-desc"); });
      th.classList.add(sortAsc ? "sort-asc" : "sort-desc");
      const tbody = table.querySelector("tbody");
      const rows = Array.from(tbody.querySelectorAll("tr:not(.skeleton-row)"));
      rows.sort((a, b) => {
        const av = a.cells[idx]?.textContent.trim() || "";
        const bv = b.cells[idx]?.textContent.trim() || "";
        const an = parseFloat(av.replace(/[$,%\s]/g, ""));
        const bn = parseFloat(bv.replace(/[$,%\s]/g, ""));
        const cmp = isNaN(an) || isNaN(bn) ? av.localeCompare(bv) : an - bn;
        return sortAsc ? cmp : -cmp;
      });
      rows.forEach(r => tbody.appendChild(r));
    });
  });
}

/* ── POPULATE SELECT ─────────────────────────────────────────────────────── */
async function populateSelect(selectId, endpoint, valueKey, labelKey, placeholder = "All") {
  const sel = document.getElementById(selectId);
  if (!sel) return;
  try {
    const data = await apiFetch(endpoint);
    sel.innerHTML = `<option value="">${placeholder}</option>`;
    (Array.isArray(data) ? data : []).forEach(item => {
      const opt = document.createElement("option");
      opt.value = item[valueKey];
      opt.textContent = item[labelKey];
      sel.appendChild(opt);
    });
  } catch (_) {}
}

/* ── BADGES ──────────────────────────────────────────────────────────────── */
function severityBadge(s) {
  const v = (s || "").toLowerCase();
  return `<span class="badge badge-${v}">${v || "—"}</span>`;
}
function statusBadge(s) {
  const v = (s || "").toLowerCase();
  const map = { completed: "success", pending: "pending", refunded: "refunded", cancelled: "cancelled" };
  return `<span class="badge badge-${map[v] || "info"}">${v || "—"}</span>`;
}
function paymentBadge(s) {
  const v = (s || "").toLowerCase().replace("_", " ");
  const cls = s === "cash" ? "cash" : s === "credit_card" ? "credit" : s === "debit_card" ? "debit" : "online";
  return `<span class="badge badge-${cls}">${v}</span>`;
}

/* ── DB HEALTH CHECK ─────────────────────────────────────────────────────── */
async function checkDbHealth() {
  const dot  = document.getElementById("db-dot");
  const text = document.getElementById("db-text");
  try {
    const data = await apiFetch("/health");
    const ok = data.status === "ok" || data.database === "connected";
    if (dot)  { dot.className  = "db-dot " + (ok ? "connected" : "disconnected"); }
    if (text) { text.textContent = ok ? "DB Connected" : "DB Error"; }
  } catch (_) {
    if (dot)  dot.className  = "db-dot disconnected";
    if (text) text.textContent = "DB Offline";
  }
}

/* ── CHART DEFAULTS ──────────────────────────────────────────────────────── */
function applyChartDefaults() {
  if (typeof Chart === "undefined") return;
  Chart.defaults.color = "#94a3b8";
  Chart.defaults.borderColor = "rgba(51,65,85,0.8)";
  Chart.defaults.font.family = "Inter, system-ui, sans-serif";
  Chart.defaults.font.size = 12;
  Chart.defaults.plugins.legend.labels.color = "#cbd5e1";
  Chart.defaults.plugins.legend.labels.padding = 16;
  Chart.defaults.plugins.tooltip.backgroundColor = "#1e293b";
  Chart.defaults.plugins.tooltip.borderColor = "#334155";
  Chart.defaults.plugins.tooltip.borderWidth = 1;
  Chart.defaults.plugins.tooltip.titleColor = "#f1f5f9";
  Chart.defaults.plugins.tooltip.bodyColor = "#94a3b8";
  Chart.defaults.plugins.tooltip.padding = 10;
  Chart.defaults.plugins.tooltip.cornerRadius = 6;
}

/* ── SIDEBAR MOBILE TOGGLE ───────────────────────────────────────────────── */
function initSidebar() {
  const hamburger = document.getElementById("hamburger");
  const sidebar   = document.getElementById("sidebar");
  if (!hamburger || !sidebar) return;

  let overlay = document.getElementById("sidebar-overlay");
  if (!overlay) {
    overlay = document.createElement("div");
    overlay.id = "sidebar-overlay";
    overlay.className = "sidebar-overlay";
    overlay.style.display = "none";
    document.body.appendChild(overlay);
  }

  hamburger.addEventListener("click", () => {
    sidebar.classList.toggle("open");
    overlay.style.display = sidebar.classList.contains("open") ? "block" : "none";
  });
  overlay.addEventListener("click", () => {
    sidebar.classList.remove("open");
    overlay.style.display = "none";
  });
}

/* ── ACTIVE NAV ──────────────────────────────────────────────────────────── */
function markActiveNav() {
  const page = window.location.pathname.split("/").pop() || "index.html";
  document.querySelectorAll(".nav-link").forEach(a => {
    const href = a.getAttribute("href") || "";
    if (href === page || (page === "" && href === "index.html")) {
      a.classList.add("active");
    } else {
      a.classList.remove("active");
    }
  });
}

/* ── DOM READY ───────────────────────────────────────────────────────────── */
document.addEventListener("DOMContentLoaded", () => {
  applyChartDefaults();
  markActiveNav();
  initSidebar();
  checkDbHealth();
});
