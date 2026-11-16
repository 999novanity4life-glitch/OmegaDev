// Creator HUD front end. Live: holds an open /api/stream (SSE); the server pushes new numbers the moment they change.
const NETS = { tiktok: "TikTok", instagram: "Instagram", youtube: "YouTube Shorts" };
const STATUS = { connected: "Metricool + live", public: "Live public counters", pending: "Action needed", off: "Not connected" };
let S = null, ideaFilter = "all";

const $ = (s) => document.querySelector(s);
const esc = (s) => String(s ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
const fmt = (n) => n == null ? "—" : n >= 1e6 ? (n / 1e6).toFixed(n >= 1e7 ? 0 : 1) + "M" : n >= 1e4 ? (n / 1e3).toFixed(n >= 1e5 ? 0 : 1) + "K" : n.toLocaleString();
const ts = (s) => { if (!s) return 0; if (s.length === 16) s += ":00-06:00"; return new Date(s).getTime(); };
function ago(s) { const d = (Date.now() - ts(s)) / 1000; if (!s || isNaN(d)) return "never"; if (d < 60) return "just now"; if (d < 3600) return Math.round(d / 60) + "m ago"; if (d < 86400) return Math.round(d / 3600) + "h ago"; return Math.round(d / 86400) + "d ago"; }
function until(s) { let d = (ts(s) - Date.now()) / 1000; if (d < 0) return "posting…"; const h = Math.floor(d / 3600), m = Math.floor((d % 3600) / 60); return h >= 24 ? `${Math.floor(h / 24)}d ${h % 24}h` : h ? `${h}h ${m}m` : `${m}m ${Math.floor(d % 60)}s`; }
const when = (s) => new Date(ts(s)).toLocaleString([], { weekday: "short", hour: "numeric", minute: "2-digit" });
const acct = (id) => S.accounts.find((a) => a.id === id);
const sum = (arr, f) => arr.reduce((t, x) => t + (f(x) || 0), 0);
const allVideos = (a) => Object.entries(a.networks).flatMap(([net, n]) => n.videos.map((v) => ({ ...v, net, account: a.id })));

// ---------- data ----------
let gotAt = 0, streamOK = false;
function apply(st) { S = st; gotAt = Date.now(); render(); watchChanges(); }
async function load() {
  try {
    const r = await fetch("/api/state", { cache: "no-store" });
    apply(await r.json());
  } catch (e) {
    $("#sync").innerHTML = `<span class="pulse stale"></span>server offline`;
  }
}
function stream() {
  if (!window.EventSource) return;
  const es = new EventSource("/api/stream");
  es.addEventListener("state", (e) => { streamOK = true; try { apply(JSON.parse(e.data)); } catch (x) {} });
  es.addEventListener("reload", () => location.reload());
  es.onerror = () => { streamOK = false; }; // browser reconnects by itself
}
async function refreshNow() {
  $("#sync").innerHTML = `<span class="pulse"></span>scanning…`;
  const r = await fetch("/api/refresh", { method: "POST" });
  apply(await r.json()); toast("Live scan complete");
}

// ---------- chrome ----------
function nav() {
  const h = location.hash || "#/overview";
  const links = [["#/overview", "Overview"], ...S.accounts.map((a) => [`#/a/${a.id}`, a.name]), ["#/ideas", "Ideas + Queue"], ["#/connections", "Connections"]];
  $("#nav").innerHTML = links.map(([href, t]) => `<a href="${href}" class="${h === href ? "on" : ""}">${esc(t)}</a>`).join("");
}
function agoS(s) { if (!s) return "never"; const d = Math.max(0, Math.round((Date.now() - ts(s)) / 1000)); return d < 60 ? d + "s ago" : d < 3600 ? Math.floor(d / 60) + "m " + String(d % 60).padStart(2, "0") + "s ago" : ago(s); }
function statusLine() {
  if (!S) return;
  const stale = !S.live_at || Date.now() - ts(S.live_at) > 600000;
  $("#sync").innerHTML = `<span class="pulse ${stale || !streamOK ? "stale" : ""}"></span>${streamOK ? "LIVE" : "reconnecting"} · stats ${agoS(S.live_at)}`;
  $("#sync").title = `Live link: ${streamOK ? "open, numbers push in by themselves" : "reconnecting"}\nLast scan: ${S.live_at || "pending"}\nMetricool snapshot: ${ago(S.metricool_synced)}${S.buffer && S.buffer.connected ? "\nBuffer: " + ago(S.buffer.at) : ""}`;
}
setInterval(() => {
  statusLine();
  document.querySelectorAll("[data-ago]").forEach((el) => (el.textContent = agoS(el.dataset.ago)));
  $("#clock").textContent = new Date().toLocaleTimeString([], { hour12: false });
  document.querySelectorAll("[data-until]").forEach((el) => (el.textContent = until(el.dataset.until)));
}, 1000);

// ---------- pieces ----------
function spark(points, color = "#5ce1ff") {
  if (!points || points.length < 2) return `<svg viewBox="0 0 100 34" preserveAspectRatio="none"><line x1="0" y1="30" x2="100" y2="30" stroke="rgba(92,225,255,.2)" stroke-dasharray="2 3"/></svg>`;
  const max = Math.max(...points), min = Math.min(...points), rng = max - min || 1;
  const p = points.map((v, i) => `${(i / (points.length - 1)) * 100},${30 - ((v - min) / rng) * 26}`).join(" ");
  return `<svg viewBox="0 0 100 34" preserveAspectRatio="none"><polyline points="${p}" fill="none" stroke="${color}" stroke-width="1.2" vector-effect="non-scaling-stroke" style="filter:drop-shadow(0 0 3px ${color})"/></svg>`;
}
function series(idx, accountId) {
  return (S.history || []).slice(-200).map((h) => accountId ? (h[accountId] || [0, 0])[idx] : sum(S.accounts, (a) => (h[a.id] || [0, 0])[idx]));
}
const chip = (net, n) => `<span class="chip"><span class="dot ${n.status}"></span>${NETS[net].split(" ")[0]}</span>`;
function queueRows(items, limit = 6) {
  if (!items.length) return `<div class="empty">// nothing scheduled</div>`;
  return `<div class="rows">${items.slice(0, limit).map((q) => {
    const a = acct(q.account);
    return `<div class="row"><span class="net ${q.network}">${q.network === "youtube" ? "YT" : q.network === "tiktok" ? "TT" : "IG"}</span>
      <div><div class="t">${esc(q.title)}</div><div class="m">${esc(a ? a.name : q.account)} · ${when(q.when)}</div></div>
      <div class="r cd" data-until="${q.when}">${until(q.when)}</div></div>`;
  }).join("")}</div>`;
}
const dur = (s) => s == null ? "—" : `${Math.floor(s / 60)}:${String(Math.round(s % 60)).padStart(2, "0")}`;
const VCOLS = [
  ["views", "Views", (v) => fmt(v.views)],
  ["engaged_views", "Engaged", (v) => fmt(v.engaged_views), "Engaged views: people who watched past the first seconds (YouTube)"],
  ["avg_view_s", "Avg watch", (v) => dur(v.avg_view_s), "Average view duration"],
  ["avg_pct", "% viewed", (v) => v.avg_pct != null ? Math.round(v.avg_pct) + "%" : "—", "Average percentage of the video watched (over 100% = replays)"],
  ["full_watch_rate", "Watched full", (v) => v.full_watch_rate != null ? v.full_watch_rate + "%" : "—"],
  ["likes", "Likes", (v) => fmt(v.likes)], ["comments", "Comments", (v) => fmt(v.comments)], ["shares", "Shares", (v) => fmt(v.shares)],
  ["subs_gained", "Follows", (v) => v.subs_gained != null ? "+" + v.subs_gained : "—", "Subscribers gained from this video"],
];
function videoTable(vids) {
  if (!vids.length) return `<div class="empty">// no published videos tracked yet. They appear here as soon as the first post goes live.</div>`;
  const cols = VCOLS.filter(([k]) => k === "views" || k === "likes" || vids.some((v) => v[k] != null));
  const stamp = vids.map((v) => v.stats_at).filter(Boolean).sort().pop() || S.live_at;
  const srcTag = (v) => v.via === "buffer" || v.via_buffer ? `<i class="src" title="Numbers from Buffer">BUF</i>` : v.stats_at ? `<i class="src" title="Numbers from the YouTube API">API</i>` : "";
  return `<div class="tablewrap"><table><tr><th>Video</th><th>Net</th><th>Posted</th>${cols.map(([, t, , tip]) => `<th class="n" ${tip ? `title="${tip}"` : ""}>${t}</th>`).join("")}</tr>
  ${vids.map((v) => `<tr><td>${v.url ? `<a href="${esc(v.url)}" target="_blank">${esc(v.title || v.id)}</a>` : esc(v.title)} ${srcTag(v)}</td>
    <td><span class="net ${v.net}">${netTag(v.net)}</span></td><td class="mono dim">${v.published ? ago(v.published) : "—"}</td>
    ${cols.map(([k, , f]) => `<td class="n">${f(v)}</td>`).join("")}</tr>`).join("")}</table></div>
  <div class="foot mono">numbers updated <span data-ago="${stamp || ""}">${agoS(stamp)}</span> · push in by themselves${vids.some((v) => v.avg_view_s != null) ? " · YouTube's watch-time stats run minutes to hours behind its view counts" : ""}${vids.some((v) => v.via === "buffer" || v.via_buffer) ? " · Buffer refreshes its numbers about once a day" : ""}</div>`;
}
const allIdeas = () => [...(S.inbox || []).map((i) => ({ ...i, status: "new" })), ...S.ideas];
function ideaDetail(i) {
  const sc = i.scores || {}, L = { proof: "Proof it performs", hook: "Hook", watch: "Watch-through", visual: "Showable", cost: "Cheap to make" };
  const row = (k, v) => (v ? `<div class="ix-r"><span>${k}</span><div>${v}</div></div>` : "");
  const shots = (b) => b.show ? `<div class="ix-sh">${b.show.map((x) => `<div><b>${esc(x.word)}</b><span>${esc(x.see)}</span></div>`).join("")}</div>${b.lens ? `<small class="ix-cam">${b.lens}mm · ${esc(b.move)}</small>` : ""}` : `<small>${esc(b.shot)}</small>`;
  const lines = i.script ? i.script.map((b, n) => `<div class="ix-l"><b>${n + 1}. ${esc(b.who)}</b> <i>${esc(b.emotion)}</i><p>${esc(b.line)}</p>${shots(b)}</div>`).join("")
    : (i.beats || []).map((b) => `<div class="ix-l"><p>${esc(b)}</p></div>`).join("");
  return `<div class="idea-x">
    ${i.scores ? `<div class="ix-sc">${Object.keys(L).map((k) => `<span>${L[k]} <b>${sc[k]}/5</b></span>`).join("")}</div>` : ""}
    ${row("Why", esc(i.why || ""))}${row("Proof", esc(i.proof || ""))}${row("Twist", esc(i.twist || ""))}${row("Length", esc(i.length || ""))}
    ${row("Source", i.source ? (i.source_url ? `<a href="${esc(i.source_url)}" target="_blank">${esc(i.source)}</a>` : esc(i.source)) : "")}
    ${row("Queue", i.queue_order ? `Number ${i.queue_order} in this account's production queue · ${esc(i.queue_status || "")}${i.deadline ? ` · ${esc(i.deadline)}` : ""}<br><span class="ix-tags">${esc(i.slots || "")}</span>` : "")}
    ${row("First frame", esc(i.hook_frame0 || ""))}${row("POV shift", esc(i.pov_shift || ""))}${row("Mood turn", esc(i.dark_turn || ""))}
    ${row("Hidden clues", (i.clues || []).map(esc).join("<br>"))}
    ${row("Caption", i.caption ? `${esc(i.caption)}<br><span class="ix-tags">${esc((i.hashtags || []).join(" "))}</span>` : "")}
    ${lines ? `<div class="ix-h">${i.script ? `Full script and shot table${i.lint ? ` · script check ${i.lint}/100` : ""} · amber word = the moment the picture must land` : "Story beats"}</div>${lines}` : ""}
    ${i.script_file ? `<div class="ix-f">${esc(i.script_file)}</div>` : ""}</div>`;
}
function prodQueue(id) {
  const accs = S.accounts.filter((a) => !id || a.id === id);
  const out = accs.map((a) => {
    const items = S.ideas.filter((i) => i.account === a.id && i.queue_order).sort((x, y) => x.queue_order - y.queue_order);
    if (!items.length) return "";
    return `<div class="cat pq"><h4>${esc(a.name)} <span class="faint">· ${items.length} in order</span></h4>
      ${items[0].queue_note ? `<div class="pq-n">${esc(items[0].queue_note)}</div>` : ""}<div class="pq-n">${esc((items.find((i) => i.slots) || {}).slots || "")}</div>
      ${items.map((i) => `<details class="idea-d"><summary class="idea"><div><div><span class="rk">${i.queue_order}</span>${esc(i.title)}</div>${i.hook ? `<div class="h">“${esc(i.hook)}”</div>` : ""}</div>
        <span class="pills">${i.deadline ? `<span class="pill new">${esc(i.deadline)}</span>` : ""}${i.score ? `<span class="pill sc">${i.score}</span>` : ""}<span class="pill ${/production/.test(i.queue_status || "") ? "prod" : ""}">${esc(i.queue_status || i.status)}</span></span></summary>${ideaDetail(i)}</details>`).join("")}</div>`; }).join("");
  return out || `<div class="empty">// production queue is empty</div>`;
}
function ideasBlock(list) {
  if (!list.length) return `<div class="empty">// no ideas logged yet</div>`;
  const cats = {};
  list.forEach((i) => (cats[i.category] ||= []).push(i));
  return Object.entries(cats).map(([c, items]) => `<div class="cat"><h4>${esc(c)} <span class="faint">· ${items.length}</span></h4>
    ${items.map((i) => { const rich = i.why || i.beats || i.script;
      const head = `<div><div>${i.rank ? `<span class="rk">${i.rank}</span>` : ""}${esc(i.title)}</div>${i.hook ? `<div class="h">“${esc(i.hook)}”</div>` : ""}</div>
      <span class="pills">${i.queue_order ? `<span class="pill q" title="Place in the production queue">Q${i.queue_order}</span>` : ""}${i.score ? `<span class="pill sc" title="Idea score out of 100">${i.score}</span>` : ""}${i.scripted && i.status !== "made" ? `<span class="pill prod">script</span>` : ""}<span class="pill ${i.status === "made" ? "made" : i.status === "in production" ? "prod" : i.status === "new" ? "new" : ""}">${esc(i.status)}</span>${i.status === "new" ? `<button class="x" title="Remove" onclick="delIdea('${i.id}')">×</button>` : ""}</span>`;
      return rich ? `<details class="idea-d"><summary class="idea">${head}</summary>${ideaDetail(i)}</details>` : `<div class="idea">${head}</div>`; }).join("")}</div>`).join("");
}
let heatNet = "tiktok";
const DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];


function heatTabs() {
  return ["tiktok", "youtube"].map((n) => `<button class="tab ${heatNet === n ? "on" : ""}" onclick="heatNet='${n}';render()">${n === "tiktok" ? "TikTok" : "YouTube"}</button>`).join("");
}
function heatmap(net) {
  const bt = S.best_times && S.best_times[net];
  if (!bt) return `<div class="empty">// no audience data yet</div>`;
  const all = Object.values(bt).flat(), max = Math.max(...all);
  const top = [...all].sort((a, b) => b - a).slice(0, 5); const thr = top[top.length - 1];
  const queued = new Set(S.queue.filter((q) => q.network === net).map((q) => { const d = new Date(ts(q.when)); return `${((d.getDay() + 6) % 7) + 1}-${d.getHours()}`; }));
  let best = null; // next upcoming top slot
  const now = new Date();
  for (let k = 1; k <= 7 * 24 && !best; k++) { const d = new Date(now.getTime() + k * 3600e3); const dow = ((d.getDay() + 6) % 7) + 1; if ((bt[dow] || [])[d.getHours()] >= thr) best = d; }
  const hrs = [0, 6, 12, 18];
  return `<div class="heat">${DAYS.map((dn, i) => `<div class="hd">${dn}</div>${(bt[i + 1] || []).map((v, h) => {
      const k = `${i + 1}-${h}`;
      return `<div class="hc ${v >= thr ? "top" : ""} ${queued.has(k) ? "q" : ""}" style="--a:${(v / max).toFixed(2)}" title="${dn} ${h}:00 · activity ${v}${queued.has(k) ? " · post queued" : ""}"></div>`;
    }).join("")}`).join("")}
    <div></div>${Array.from({ length: 24 }, (_, h) => `<div class="hh">${hrs.includes(h) ? (h === 0 ? "12a" : h === 12 ? "12p" : h > 12 ? h - 12 + "p" : h + "a") : ""}</div>`).join("")}</div>
    <div class="m mono dim" style="font-size:11px;margin-top:12px"><span class="lg top"></span> top 5 hours &nbsp; <span class="lg q"></span> post queued${best ? ` &nbsp;·&nbsp; next peak slot: <span class="cd">${best.toLocaleString([], { weekday: "short", hour: "numeric" })}</span>` : ""}</div>`;
}

const GOALS = { tiktok: [[1000, "TikTok LIVE unlocked"], [10000, "Creator Rewards (TikTok pays)"]], youtube: [[500, "YouTube Partner (fan funding)"], [1000, "YouTube ad revenue"]], instagram: [[1000, "IG monetisation tools"], [10000, "Link stickers + brand deals"]] };
function milestones(onlyId) {
  const rows = [];
  S.accounts.filter((a) => !onlyId || a.id === onlyId).forEach((a) => Object.entries(a.networks).forEach(([net, n]) => {
    if (n.status === "off" || n.status === "pending") return;
    const f = n.followers || 0; const g = GOALS[net].find(([t]) => f < t) || GOALS[net][GOALS[net].length - 1];
    rows.push(`<div class="ms"><div class="ms-h"><span>${onlyId ? "" : esc(a.name) + " · "}${NETS[net].split(" ")[0]}</span><span class="mono dim">${fmt(f)} / ${fmt(g[0])}</span></div>
      <div class="bar"><i style="width:${Math.max(1.5, Math.min(100, (f / g[0]) * 100))}%;background:${a.color};box-shadow:0 0 8px ${a.color}"></i></div><div class="ms-l">${g[1]}</div></div>`);
  }));
  return rows.length ? rows.join("") : `<div class="empty">// connect a network to track milestones</div>`;
}

function calendar() {
  const start = new Date(); start.setHours(0, 0, 0, 0);
  return `<div class="cal">${Array.from({ length: 7 }, (_, i) => {
    const d = new Date(start.getTime() + i * 864e5), e = d.getTime() + 864e5;
    const items = S.queue.filter((q) => ts(q.when) >= d.getTime() && ts(q.when) < e);
    return `<div class="day ${i === 0 ? "today" : ""}"><div class="dh">${i === 0 ? "Today" : d.toLocaleDateString([], { weekday: "short" })} <span class="faint">${d.getDate()}</span></div>
      ${items.map((q) => `<div class="ev ${q.network}" title="${esc(q.title)}"><div class="mono">${new Date(ts(q.when)).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })} · ${q.network === "youtube" ? "YT" : q.network === "tiktok" ? "TT" : "IG"}</div><div class="et">${esc(q.title)}</div><div class="faint mono" style="font-size:10px">${esc((acct(q.account) || {}).name || "")}</div></div>`).join("") || `<div class="faint mono" style="font-size:11px">—</div>`}</div>`;
  }).join("")}</div>`;
}

// ---- quick idea capture ----
function openCapture() {
  closeModal();
  const cur = (location.hash.match(/#\/a\/(.+)/) || [])[1] || "earth-sandbox";
  document.body.insertAdjacentHTML("beforeend", `<div class="modal" id="modal" onclick="if(event.target.id==='modal')closeModal()"><div class="panel mbox">
    <div class="ptitle">New video idea <span class="tag">esc to close</span></div>
    <select id="ci-acc">${S.accounts.map((a) => `<option value="${a.id}" ${a.id === cur ? "selected" : ""}>${esc(a.name)}</option>`).join("")}</select>
    <input id="ci-title" placeholder="What's the idea? e.g. What if the Sun turned off for 1 minute">
    <input id="ci-hook" placeholder="Hook (first line), optional">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-top:6px"><span class="faint mono" style="font-size:11px">Saved to your idea inbox. Claude picks it up on the next sync.</span><button class="btn on" onclick="saveIdea()">Save ↵</button></div></div></div>`);
  setTimeout(() => $("#ci-title").focus(), 30);
}
async function saveIdea() {
  const title = $("#ci-title").value.trim(); if (!title) { alertish("#ci-title"); return; }
  const r = await fetch("/api/idea", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ account: $("#ci-acc").value, title, hook: $("#ci-hook").value }) });
  const name = (acct($("#ci-acc").value) || {}).name || "inbox";
  S.inbox = (await r.json()).inbox; closeModal(); toast(`Idea saved to ${esc(name)}`); render();
}
async function delIdea(id) { const r = await fetch("/api/idea", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ delete: id }) }); S.inbox = (await r.json()).inbox; render(); }
function closeModal() { const m = $("#modal"); if (m) m.remove(); }

// ---- command palette ----
function commands() {
  const c = [["Overview", () => (location.hash = "#/overview"), "1"]];
  S.accounts.forEach((a, i) => c.push([a.name, () => (location.hash = `#/a/${a.id}`), String(i + 2)]));
  c.push(["Ideas + queue", () => (location.hash = "#/ideas"), String(S.accounts.length + 2)], ["Money: pay programs, services, outreach", () => (location.hash = "#/money"), "M"], ["Inbox: replies", () => (location.hash = "#/inbox"), "I"], ["Connections", () => (location.hash = "#/connections"), "L"],
    ["New video idea", openCapture, "N"], ["Scan live stats now", refreshNow, "R"], ["Open Metricool", () => window.open("https://app.metricool.com/"), ""]);
  S.accounts.forEach((a) => Object.entries(a.networks).forEach(([net, n]) => {
    if (!n.handle || n.status === "off") return;
    const url = net === "tiktok" ? `https://www.tiktok.com/@${n.handle}` : net === "youtube" ? `https://www.youtube.com/@${n.handle}/shorts` : `https://www.instagram.com/${n.handle}`;
    c.push([`Open ${a.name} on ${NETS[net].split(" ")[0]}`, () => window.open(url), ""]);
  }));
  return c;
}
let palSel = 0;
function openPalette() {
  closeModal();
  document.body.insertAdjacentHTML("beforeend", `<div class="modal" id="modal" onclick="if(event.target.id==='modal')closeModal()"><div class="panel mbox pal"><input id="pal-q" placeholder="Type a command or page…" autocomplete="off"><div id="pal-list"></div></div></div>`);
  palSel = 0; drawPal(); const q = $("#pal-q"); q.focus();
  q.addEventListener("input", () => { palSel = 0; drawPal(); });
}
function palItems() { const q = ($("#pal-q") || {}).value?.toLowerCase() || ""; return commands().filter(([t]) => q.split(" ").every((w) => t.toLowerCase().includes(w))); }
function drawPal() { $("#pal-list").innerHTML = palItems().map(([t, , k], i) => `<div class="pi ${i === palSel ? "on" : ""}" onmouseenter="palSel=${i};drawPal()" onclick="runPal(${i})"><span>${esc(t)}</span><span class="faint mono">${k}</span></div>`).join("") || `<div class="empty">// no match</div>`; }
function runPal(i) { const it = palItems()[i]; closeModal(); if (it) it[1](); }

document.addEventListener("keydown", (e) => {
  const inField = /INPUT|SELECT|TEXTAREA/.test(document.activeElement.tagName);
  if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") { e.preventDefault(); $("#modal") ? closeModal() : openPalette(); return; }
  if (e.key === "Escape") return closeModal();
  if ($("#pal-q")) {
    const n = palItems().length;
    if (e.key === "ArrowDown") { palSel = (palSel + 1) % n; drawPal(); e.preventDefault(); }
    if (e.key === "ArrowUp") { palSel = (palSel - 1 + n) % n; drawPal(); e.preventDefault(); }
    if (e.key === "Enter") runPal(palSel);
    return;
  }
  if (e.key === "Enter" && $("#ci-title")) return saveIdea();
  if (inField || !S || e.metaKey || e.ctrlKey || e.altKey) return;
  const cmd = commands().find(([, , k]) => k && k.toLowerCase() === e.key.toLowerCase());
  if (cmd) { e.preventDefault(); cmd[1](); }
});

// ---- live change toasts + tab title ----
let prevViews = null, prevReplies = null;
const unread = () => (S && S.replies ? S.replies.filter((r) => !r.read).length : 0);
function toast(msg) {
  let box = $("#toasts"); if (!box) { document.body.insertAdjacentHTML("beforeend", `<div id="toasts"></div>`); box = $("#toasts"); }
  const el = document.createElement("div"); el.className = "toast"; el.innerHTML = `<span class="cd">◆</span> ${msg}`; box.appendChild(el);
  setTimeout(() => el.classList.add("out"), 4500); setTimeout(() => el.remove(), 5200);
}
function watchChanges() {
  const cur = {}; S.accounts.forEach((a) => allVideos(a).forEach((v) => (cur[v.net + v.id] = { v: v.views || 0, t: v.title, a: a.name })));
  if (prevViews) Object.entries(cur).forEach(([k, x]) => { const d = x.v - ((prevViews[k] || {}).v || 0); if (d > 0) toast(`+${fmt(d)} views · ${esc(x.t)}`); });
  prevViews = cur;
  const total = sum(Object.values(cur), (x) => x.v);
  const ids = new Set((S.replies || []).map((r) => r.id));
  if (prevReplies) (S.replies || []).filter((r) => !prevReplies.has(r.id) && !r.read).slice(0, 3).forEach((r) => toast(`<a href="#/inbox">New reply · ${esc(r.source)}</a> · ${esc(r.from || r.subject)}`));
  prevReplies = ids;
  document.title = `${unread() ? `(${unread()}) ` : ""}${total ? fmt(total) + " views · " : ""}Creator Core`;
}


// ================= v3: Stark core =================
const REDUCED = window.matchMedia && matchMedia("(prefers-reduced-motion: reduce)").matches;
const TABS = (() => { try { return JSON.parse(localStorage.getItem("hud-tabs") || "{}"); } catch (e) { return {}; } })();
function setTab(group, id) { TABS[group] = id; try { localStorage.setItem("hud-tabs", JSON.stringify(TABS)); } catch (e) {} render(); }
function tabs(group, list, def) {
  const cur = list.find(([k]) => k === TABS[group]) ? TABS[group] : def;
  return { cur, bar: `<div class="tabs">${list.map(([k, t, n]) => `<button class="${k === cur ? "on" : ""}" onclick="setTab('${group}','${k}')">${t}${n != null ? `<sup>${n}</sup>` : ""}</button>`).join("")}</div>` };
}
const netTag = (n) => (n === "youtube" ? "YT" : n === "tiktok" ? "TT" : "IG");

// --- arc reactor (the core) ---
function reactor({ value, label, sub, progress = 0, color = "#4fd8ff", size = 420, img }) {
  const C = 200, coils = 10;
  const ticks = Array.from({ length: 72 }, (_, i) => { const a = (i / 72) * Math.PI * 2, r1 = 188, r2 = i % 6 ? 182 : 174;
    return `<line x1="${C + r1 * Math.cos(a)}" y1="${C + r1 * Math.sin(a)}" x2="${C + r2 * Math.cos(a)}" y2="${C + r2 * Math.sin(a)}"/>`; }).join("");
  const seg = (r, w, n, gap) => Array.from({ length: n }, (_, i) => { const a0 = (i / n) * 360 + gap / 2, a1 = ((i + 1) / n) * 360 - gap / 2;
    const p = (a) => [C + r * Math.cos((a - 90) * Math.PI / 180), C + r * Math.sin((a - 90) * Math.PI / 180)];
    const [x0, y0] = p(a0), [x1, y1] = p(a1); return `<path d="M${x0} ${y0} A${r} ${r} 0 0 1 ${x1} ${y1}" stroke-width="${w}"/>`; }).join("");
  const coil = Array.from({ length: coils }, (_, i) => `<rect x="${C - 9}" y="${C - 128}" width="18" height="34" rx="2" transform="rotate(${(i / coils) * 360} ${C} ${C})"/>`).join("");
  const R = 158, circ = 2 * Math.PI * R, prog = Math.max(0.004, Math.min(1, progress));
  return `<div class="reactor-core" style="--rc:${color};width:${size}px;max-width:100%">
    <svg viewBox="0 0 400 400" aria-hidden="true">
      <defs><radialGradient id="glow-${size}" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#eaffff"/><stop offset=".35" stop-color="${color}" stop-opacity=".85"/><stop offset=".7" stop-color="${color}" stop-opacity=".12"/><stop offset="1" stop-color="${color}" stop-opacity="0"/></radialGradient></defs>
      <g class="r-ticks spin-slow">${ticks}</g>
      <circle class="r-track" cx="200" cy="200" r="${R}"/>
      <circle class="r-prog" cx="200" cy="200" r="${R}" stroke-dasharray="${circ}" stroke-dashoffset="${circ * (1 - prog)}" transform="rotate(-90 200 200)"/>
      <g class="r-seg spin-rev">${seg(140, 3, 12, 8)}</g>
      <g class="r-coil">${coil}</g>
      <circle class="r-inner" cx="200" cy="200" r="88"/>
      <g class="r-seg2 spin-mid">${seg(80, 1.5, 3, 30)}</g>
      <circle class="r-glow" cx="200" cy="200" r="96" fill="url(#glow-${size})"/>
    </svg>
    <div class="r-center">${img ? `<img src="${img}" alt="">` : ""}<div class="r-val" data-count="${value}">${fmt(value)}</div><div class="r-lbl">${label}</div>${sub ? `<div class="r-sub">${sub}</div>` : ""}</div>
  </div>`;
}

// --- radial dial ---
function dial({ value, display, label, sub, frac = 0, color = "var(--cy)", count = true }) {
  const r = 44, c = 2 * Math.PI * r, f = Math.max(0, Math.min(1, frac));
  return `<div class="dial" style="--dc:${color}"><svg viewBox="0 0 110 110"><circle class="d-tr" cx="55" cy="55" r="${r}"/>
    <circle class="d-pr" cx="55" cy="55" r="${r}" stroke-dasharray="${c}" style="--off:${c * (1 - f)};--full:${c}" transform="rotate(-90 55 55)"/>
    <circle class="d-in" cx="55" cy="55" r="36"/></svg>
    <div class="d-c"><b ${count ? `data-count="${value}"` : ""}>${display ?? fmt(value)}</b></div>
    <div class="d-l">${label}</div>${sub ? `<div class="d-s">${sub}</div>` : ""}</div>`;
}
const nextGoal = (net, f) => (GOALS[net] || [[1000, ""]]).find(([t]) => f < t) || GOALS[net][GOALS[net].length - 1];

// --- console bodies ---
function briefBody() {
  const b = S.briefing, auto = [];
  const pending = S.accounts.flatMap((a) => Object.values(a.networks)).filter((n) => n.status === "pending").length;
  if (pending) auto.push(`${pending} connection${pending > 1 ? "s" : ""} waiting on you. <a href="#/connections">Open Links</a>`);
  const left = S.accounts.find((a) => a.posts_limit); if (left && left.posts_limit - left.posts_used <= 4) auto.push(`Only ${left.posts_limit - left.posts_used} Metricool posts left this month.`);
  const lines = [...(b ? b.lines : []), ...auto];
  return lines.length ? `<ol class="brief">${lines.map((l) => `<li>${l.includes("<a ") ? l : esc(l)}</li>`).join("")}</ol><div class="foot">${b ? "Written " + ago(b.written_at) : ""}</div>` : `<div class="empty">// no briefing yet</div>`;
}
function topBody() {
  const vids = S.accounts.flatMap(allVideos).sort((a, b) => (b.views || 0) - (a.views || 0)).slice(0, 8);
  return vids.length ? `<div class="rows">${vids.map((v, i) => `<div class="row"><span class="rank">${String(i + 1).padStart(2, "0")}</span><div><div class="t">${v.url ? `<a href="${esc(v.url)}" target="_blank">${esc(v.title)}</a>` : esc(v.title)}</div><div class="m">${netTag(v.net)} · ${esc(acct(v.account).name)} · ${ago(v.published)}</div></div><div class="r">${fmt(v.views)}<span class="dim"> views</span></div></div>`).join("")}</div>` : `<div class="empty">// waiting for first views</div>`;
}
function systemsBody() {
  return `<div class="log">
    <div><span class="ok">●</span> Metricool snapshot · synced ${ago(S.metricool_synced)}</div>
    <div><span class="${S.live_at ? "ok" : "w"}">●</span> Live public counters · ${S.live_at ? "last scan " + ago(S.live_at) : "first scan running"}</div>
    <div><span class="ok">●</span> Ideas + renders · built ${ago(S.content_built)}</div>
    <div><span class="${streamOK ? "ok" : "w"}">●</span> Live link to this page · ${streamOK ? "open (numbers push in by themselves)" : "reconnecting"}</div>
    <div><span class="${S.google && S.google.channels.length ? "ok" : "w"}">●</span> YouTube Analytics · ${S.google && S.google.channels.length ? S.google.channels.map((c) => esc(c.title)).join(", ") : "not connected yet"}</div>
    <div><span class="${S.buffer && S.buffer.connected && !S.buffer.error ? "ok" : "w"}">●</span> Buffer · ${S.buffer && S.buffer.connected ? (S.buffer.error ? esc(S.buffer.error) : `${(S.buffer.accounts || []).length} of 2 Buffers · ${S.buffer.channels.length} channels · ${ago(S.buffer.at)}`) : "add your API keys on Links"}</div>
    <div><span class="${(S.gmail || {}).boxes && S.gmail.boxes.length ? "ok" : "w"}">●</span> Reply alerts · ${(S.gmail || {}).boxes && S.gmail.boxes.length ? "watching " + S.gmail.boxes.length + " inbox, every minute" : "Gmail not connected yet"}</div>
    ${(S.live_log || []).map((l) => `<div><span class="w">●</span> ${esc(l)}</div>`).join("")}</div>
    <button class="btn" style="margin-top:14px" onclick="refreshNow()">Scan now <span class="faint">R</span></button>`;
}

const SRC = { metricool: "Metricool", live: "Live", buffer: "Buffer", "youtube-api": "YT API" };
const srcChips = (n) => (n.source || "").split("+").filter(Boolean).map((k) => `<i class="src">${SRC[k] || k}</i>`).join("");

// ---------- pages ----------
function overview() {
  const nets = S.accounts.flatMap((a) => Object.values(a.networks));
  const followers = sum(nets, (n) => n.followers), views = sum(nets, (n) => n.views), likes = sum(nets, (n) => n.likes);
  const vids = S.accounts.flatMap(allVideos);
  const live = nets.filter((n) => n.status === "connected" || n.status === "public").length;
  const nextQ = S.queue[0], goal = followers < 1000 ? 1000 : followers < 10000 ? 10000 : 100000;
  const tleft = nextQ ? Math.max(0, ts(nextQ.when) - Date.now()) : 0;
  const t = tabs("ov", [["brief", "Briefing"], ["next", "Up next", S.queue.length], ["top", "Top videos"], ["hours", "Audience hours"], ["goals", "Milestones"], ["sys", "Systems"]], "brief");
  const body = { brief: briefBody, next: () => queueRows(S.queue, 10), top: topBody, hours: () => `<div class="sub-tabs">${heatTabs()}</div>${heatmap(heatNet)}`, goals: () => milestones(), sys: systemsBody }[t.cur]();
  return `<section class="core">
    <div class="side">${dial({ value: followers, label: "Followers", sub: `goal ${fmt(goal)}`, frac: followers / goal })}${dial({ value: likes, label: "Likes", sub: "all networks", frac: views ? likes / views : 0 })}</div>
    <div class="mid">${reactor({ value: views, label: "Total views", sub: `${live}/${nets.length} online`, progress: followers / goal })}</div>
    <div class="side">${dial({ value: vids.length, label: "Videos live", sub: `${S.queue.length} queued`, frac: vids.length / Math.max(1, vids.length + S.queue.length) })}${dial({ value: 0, count: false, display: nextQ ? `<span data-until="${nextQ.when}">${until(nextQ.when)}</span>` : "—", label: "Next post", sub: nextQ ? esc(nextQ.title).slice(0, 26) + "…" : "queue empty", frac: 1 - Math.min(1, tleft / 864e5), color: "var(--amber)" })}</div>
  </section>
  <section class="pods">${S.accounts.map((a) => {
    const n = Object.values(a.networks), f = sum(n, (x) => x.followers), r = 30, c = 2 * Math.PI * r;
    return `<a class="pod" href="#/a/${a.id}" style="--ac:${a.color}"><div class="pod-ring"><svg viewBox="0 0 72 72"><circle cx="36" cy="36" r="${r}" class="pr-t"/><circle cx="36" cy="36" r="${r}" class="pr-p" stroke-dasharray="${c}" stroke-dashoffset="${c * (1 - Math.max(0.02, Math.min(1, f / 1000)))}" transform="rotate(-90 36 36)"/></svg><img src="assets/${a.id}.png" alt=""></div>
      <div class="pod-t"><div class="pod-n">${esc(a.name)}</div><div class="pod-f"><b data-count="${f}">${fmt(f)}</b> followers</div><div class="pod-d">${Object.entries(a.networks).map(([k, v]) => `<span class="dot ${v.status}" title="${NETS[k]}: ${STATUS[v.status]}"></span>`).join("")}</div></div></a>`;
  }).join("")}</section>
  ${opsStrip()}
  <section class="panel console">${t.bar}<div class="tab-body" key="${t.cur}">${body}</div></section>`;
}

function accountPage(id) {
  const a = acct(id); if (!a) return overview();
  const vids = allVideos(a).sort((x, y) => (y.published || "").localeCompare(x.published || ""));
  const ideas = allIdeas().filter((i) => i.account === id);
  const renders = S.videos.filter((v) => v.account === id);
  const q = S.queue.filter((x) => x.account === id);
  const nn = Object.values(a.networks), fol = sum(nn, (x) => x.followers), vw = sum(nn, (x) => x.views);
  const t = tabs("ac", [["videos", "Videos", vids.length], ["ideas", "Ideas", ideas.length], ["prod", "Production queue", ideas.filter((i) => i.queue_order).length], ["queue", "Scheduled", q.length], ["renders", "Rendered", renders.length], ["goals", "Milestones"]], "videos");
  const body = { videos: () => videoTable(vids), ideas: () => `<div class="cols2">${ideasBlock(ideas)}</div>`, queue: () => queueRows(q, 20), prod: () => prodQueue(id),
    renders: () => renders.length ? `<div class="rows">${renders.map((v) => `<div class="row"><span class="rank">${Math.round(v.seconds || 0)}s</span><div><div class="t">${esc(v.title)}</div><div class="m">rendered ${esc(v.date)}</div></div><div class="r dim">${esc(v.format || "")}</div></div>`).join("")}</div>` : `<div class="empty">// nothing rendered yet</div>`,
    goals: () => milestones(id) }[t.cur]();
  return `<section class="acc-core">
    <div class="acc-left">${reactor({ value: fol, label: "Followers", progress: fol / 1000, color: a.color, size: 320, img: `assets/${a.id}.png` })}
      <div class="acc-name"><h1>${esc(a.name)}</h1><div class="dim">${esc(a.tagline)}</div><div class="acc-stats mono"><span><b data-count="${vw}">${fmt(vw)}</b> views</span><span><b>${vids.length}</b> videos</span>${a.posts_limit ? `<span><b>${a.posts_used}/${a.posts_limit}</b> posts</span>` : ""}</div></div></div>
    <div class="acc-nets">${Object.entries(a.networks).map(([net, n]) => {
      const off = n.status === "off" || n.status === "pending", g = nextGoal(net, n.followers || 0);
      return `<div class="net-card ${n.status}">
        ${off ? `<div class="dial ghost"><svg viewBox="0 0 110 110"><circle class="d-tr" cx="55" cy="55" r="44" stroke-dasharray="3 5"/></svg><div class="d-c"><b>—</b></div><div class="d-l">${NETS[net]}</div></div>`
          : dial({ value: n.followers || 0, label: NETS[net], sub: `${fmt(n.views)} views · ${fmt(n.likes)} likes`, frac: (n.followers || 0) / g[0], color: a.color })}
        ${n.avg_view_s != null ? `<div class="nc-deep mono"><span title="Average view duration"><b>${dur(n.avg_view_s)}</b> avg</span><span title="Average % viewed"><b>${Math.round(n.avg_pct || 0)}%</b> viewed</span>${n.engaged_views != null ? `<span title="Engaged views"><b>${fmt(n.engaged_views)}</b> engaged</span>` : ""}</div>` : ""}
        <div class="nc-st"><span class="dot ${n.status}"></span>${STATUS[n.status]}</div>${n.source ? `<div class="nc-src">${srcChips(n)}</div>` : ""}
        ${n.todo ? `<div class="nc-todo">${esc(n.todo)}</div>` : off ? `<a class="nc-todo" href="#/connections">Connect →</a>` : `<div class="nc-h">@${esc(n.handle)}</div>`}
      </div>`; }).join("")}</div>
  </section>
  <section class="panel console">${t.bar}<div class="tab-body">${body}</div></section>`;
}

let ideaAcct = null;
function ideasPage() {
  const filt = (i) => ideaFilter === "all" || (ideaFilter === "todo" ? (i.status === "idea" || i.status === "new") : ideaFilter === "made" ? i.status === "made" : i.status === "in production");
  const t = tabs("id", [["ideas", "Idea bank", allIdeas().length], ["prod", "Production queue", S.ideas.filter((i) => i.queue_order).length], ["cal", "Next 7 days", S.queue.length]], "ideas");
  const cur = ideaAcct || S.accounts[0].id;
  const list = allIdeas().filter((i) => i.account === cur && filt(i));
  const body = t.cur === "cal" ? calendar() : t.cur === "prod" ? `<div class="cols2">${prodQueue()}</div>` : `
    <div class="idea-bar"><div class="seg">${S.accounts.map((a) => `<button class="${a.id === cur ? "on" : ""}" style="--ac:${a.color}" onclick="ideaAcct='${a.id}';render()"><img src="assets/${a.id}.png" alt="">${esc(a.name)}<sup>${allIdeas().filter((i) => i.account === a.id).length}</sup></button>`).join("")}</div>
      <div class="filters">${[["all", "All"], ["todo", "Not made"], ["prod", "In production"], ["made", "Made"]].map(([k, tt]) => `<button class="${ideaFilter === k ? "on" : ""}" onclick="ideaFilter='${k}';render()">${tt}</button>`).join("")}</div></div>
    <div class="cols2">${ideasBlock(list)}</div>`;
  return `<div class="page-h"><div><div class="kicker">Idea bank</div><h1>Ideas + queue</h1></div><button class="btn primary" onclick="openCapture()">+ New idea <span class="faint">N</span></button></div>
  <section class="panel console">${t.bar}<div class="tab-body">${body}</div></section>`;
}

const GUIDE = {
  tiktok: ["Open Metricool → brand menu (top left) → Connect", "Pick TikTok and log in with that account's TikTok", "Come back here: it turns green within 5 minutes"],
  instagram: ["In Instagram: Settings → Account type and tools → Switch to professional → Creator", "Metricool → Connect → Instagram → log in with Instagram", "Green here within 5 minutes"],
  youtube: ["Metricool → Connect → YouTube", "Pick the channel's Google account", "Green here within 5 minutes"],
};
let editCell = null;
function connectionsPage() {
  const b = S.accounts.find((a) => a.posts_limit);
  const all = S.accounts.flatMap((a) => Object.values(a.networks)), on = all.filter((n) => n.status === "connected" || n.status === "public").length;
  const t = tabs("cn", [["pending", "Your to-do"], ["yta", "YouTube stats"], ["buffer", "Buffer"], ["tiktok", "TikTok"], ["instagram", "Instagram"], ["youtube", "YouTube"], ["plan", "Metricool plan"]], "pending");
  const body = t.cur === "pending" ? `<ol class="brief">
      ${S.google && S.google.channels.length ? "" : `<li>YouTube deep stats (engaged views, watch time, % viewed): <a href="javascript:setTab('cn','yta')">connect each channel once</a>.</li>`}
      ${S.buffer && (S.buffer.accounts || []).length >= 2 ? "" : `<li>Buffer stats: ${(S.buffer.accounts || []).length} of 2 Buffers connected. <a href="javascript:setTab('cn','buffer')">Add a key</a>.</li>`}
      ${(S.gmail || {}).boxes && S.gmail.boxes.length ? "" : `<li>Reply alerts: <a href="#/inbox" onclick="TABS.ib='alerts'">connect Gmail</a> so buyer and streamer replies land in the Inbox.</li>`}
      <li>Earth Sandbox Instagram: switch to a Creator account, then Metricool → Connect → Instagram.</li>
      <li>Actually Happened + Tiny Disasters: click a grey cell, type the handle, press Track live.</li>
      ${opsAll().filter((c) => c.next).map((c) => `<li>${esc(c.name)}: ${esc(c.next)}</li>`).join("")}</ol>`
    : t.cur === "yta" ? ytaBody() : t.cur === "buffer" ? bufferBody()
    : t.cur === "plan" ? `<div class="log"><div>Brands: <b class="w">1 of 1</b> (Earth Sandbox)</div><div>Posts this month: <b class="w">${b ? b.posts_used : "?"} / ${b ? b.posts_limit : 20}</b> per network</div></div>${b ? `<div class="bar"><i style="width:${(b.posts_used / b.posts_limit) * 100}%"></i></div>` : ""}
      <p class="dim" style="line-height:1.6">Free Metricool holds one brand, so the other accounts use <b>Track live</b>: the HUD reads their public follower, like and view counters straight from TikTok and YouTube. No login, no cost.</p><a class="btn" href="https://app.metricool.com/" target="_blank">Open Metricool ↗</a>`
    : `<ol class="brief">${GUIDE[t.cur].map((s) => `<li>${s}</li>`).join("")}</ol>`;
  return `<div class="page-h"><div><div class="kicker">Uplinks · ${on} of ${all.length} online</div><h1>Links</h1></div></div>
  <section class="panel matrix"><div class="mx-head"><span></span>${Object.values(NETS).map((n) => `<span>${n}</span>`).join("")}</div>
    ${S.accounts.map((a) => `<div class="mx-row"><div class="mx-acc"><img src="assets/${a.id}.png" alt="">${esc(a.name)}</div>
      ${Object.keys(NETS).map((net) => { const n = a.networks[net] || { status: "off" }, key = `${a.id}-${net}`;
        if (editCell === key) return `<div class="mx-cell edit"><input id="h-${key}" placeholder="@handle" value="${esc(n.handle || "")}"><div class="act"><button class="btn primary" onclick="setConn('${a.id}','${net}','public')">Track live</button>${n.status !== "off" ? `<button class="btn" onclick="setConn('${a.id}','${net}','off')">Off</button>` : ""}<button class="btn" onclick="editCell=null;render()">×</button></div></div>`;
        return `<button class="mx-cell ${n.status}" ${n.status === "connected" ? "" : `onclick="editCell='${key}';render();setTimeout(()=>$('#h-${key}').focus(),20)"`} title="${esc(n.todo || "")}">
          <span class="dot ${n.status}"></span><span><i class="mx-net">${NETS[net]}</i><b>${STATUS[n.status]}</b><small>${n.handle ? "@" + esc(n.handle) : "click to add"}${n.todo ? " · action needed" : ""}</small></span></button>`; }).join("")}</div>`).join("")}
  </section>
  <section class="panel console">${t.bar}<div class="tab-body">${body}</div></section>`;
}
function ytaBody() {
  const g = S.google || { client: false, channels: [] };
  return `<p class="dim" style="line-height:1.6;margin-top:0">Free YouTube Analytics: engaged views, average watch time, % viewed, shares and follows per Short, refreshed every 2 minutes. Sign in once per channel; the sign-in stays on this Mac.</p>
    ${g.channels.length ? `<div class="log">${g.channels.map((c) => `<div><span class="ok">●</span> ${esc(c.title)} <span class="faint">connected</span></div>`).join("")}</div>` : ""}
    ${g.client ? `<div class="act-row"><a class="btn primary" href="/oauth/google">${g.channels.length ? "+ Connect another channel" : "Connect a YouTube channel"}</a>${g.channels.length ? `<button class="btn" onclick="gRemove()">Disconnect all</button>` : ""}</div>`
      : `<div class="keybox"><input id="g-id" placeholder="OAuth client ID (…apps.googleusercontent.com)" autocomplete="off"><input id="g-sec" type="password" placeholder="Client secret" autocomplete="off"><button class="btn primary" onclick="gSave()">Save</button></div><div class="faint mono" style="font-size:11px;margin-top:8px">From Google Cloud → APIs &amp; Services → Credentials → Desktop app client. Saved only on this Mac.</div>`}`;
}
async function gSave() {
  const r = await fetch("/api/google-client", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ client_id: $("#g-id").value, client_secret: $("#g-sec").value }) });
  const j = await r.json(); j.ok ? toast("Google client saved") : toast(esc(j.error)); load();
}
async function gRemove() { await fetch("/api/google-client", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ remove: true }) }); load(); }
function bufferBody() {
  const b = S.buffer || { connected: false, channels: [], accounts: [] };
  const where = (c) => c.account && acct(c.account) ? `${esc(acct(c.account).name)} · ${NETS[c.network] || c.network}` : `<span class="w">not matched to an account</span>`;
  const accs = (b.accounts || []).map((a) => `<div class="buf-acc"><div class="buf-h"><b>${esc(a.label)}</b>${a.error ? `<span class="w"> · ${esc(a.error)}</span>` : ""}<button class="x" title="Remove this key" onclick="bufKey('${esc(a.label)}')">×</button></div>
      <div class="log">${b.channels.filter((c) => (c.buffer || "Buffer 1") === a.label).map((c) => `<div><span class="ok">●</span> ${esc(c.name)} <span class="faint">(${esc(c.service)})</span> → ${where(c)} · ${c.posts} posts</div>`).join("") || `<div class="faint">pulling channels…</div>`}</div></div>`).join("");
  const n = (b.accounts || []).length;
  return `${n ? `<div class="cols2">${accs}</div><div class="faint mono" style="font-size:11px;margin:10px 0 16px">Last pull ${ago(b.at)}. Buffer refreshes its post numbers about once a day.</div>`
      : `<p class="dim" style="line-height:1.6;margin-top:0">Adds per-post views, likes, comments and shares for every channel Buffer posts to. You have two Buffers: one for Wildly Animated + Earth Sandbox, one for ClipHotwire. Each needs its own free API key (Buffer → Settings → API). Keys are saved only on this Mac.</p>`}
    <div class="keybox"><input id="buf-label" placeholder="Name, e.g. Buffer ${n + 1}" style="flex:0 1 160px" value="Buffer ${n + 1}"><input id="buf-key" type="password" placeholder="Buffer API key" autocomplete="off"><button class="btn primary" onclick="bufKey()">${n ? "Add another Buffer" : "Connect"}</button></div>
    <a class="btn" style="margin-top:12px" href="https://publish.buffer.com/settings/api" target="_blank">Open Buffer API settings ↗</a>`;
}
async function bufKey(remove) {
  const r = await fetch("/api/buffer-key", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(remove ? { remove } : { key: $("#buf-key").value, label: $("#buf-label").value }) });
  const j = await r.json(); toast(j.ok ? (remove ? "Buffer key removed" : "Buffer connected · pulling stats") : esc(j.error)); load();
}

// ================= command site: money, inbox, alerts =================
const ST = { live: ["ok", "Live"], waiting: ["w", "Waiting on you"], pending: ["w", "Not live yet"], off: ["off", "Not started"], test: ["w", "Test"], queued: ["ok", "Queued"], posted: ["ok", "Posted"], candidate: ["off", "Candidate"] };
const stv = (v) => { const m = /^@replies:(.*)$/.exec(String(v)); return m ? (S.replies || []).filter((r) => r.source === m[1]).length : esc(v); };
function opsCard(c) {
  const [cls, lab] = ST[c.status] || ST.off;
  return `<div class="op ${c.status}"><div class="op-h"><div><b>${esc(c.name)}</b>${c.tag ? `<span class="op-tag">${esc(c.tag)}</span>` : ""}</div><span class="op-st ${cls}"><i></i>${lab}</span></div>
    <div class="op-l">${esc(c.line || "")}</div>
    ${(c.stats || []).length ? `<div class="op-s">${c.stats.map(([k, v]) => `<span><b>${stv(v)}</b>${esc(k)}</span>`).join("")}</div>` : ""}
    ${(c.items || []).length ? `<div class="op-i">${c.items.map(([k, v]) => `<div><span>${esc(k)}</span><span class="faint">${esc(v)}</span></div>`).join("")}</div>` : ""}
    ${c.next ? `<div class="op-n">Your move: ${esc(c.next)}</div>` : ""}
    ${c.url ? `<a class="op-a" href="${esc(c.url)}" target="_blank">Open ↗</a>` : ""}</div>`;
}
const opsAll = () => { const o = S.ops || {}; return [...(o.programs || []), ...(o.services || []), ...(o.outreach || [])]; };
function pipeBody() {
  const p = (S.ops || {}).pipeline || {}, items = p.items || [];
  return `${p.launch ? `<div class="pipe-l"><span class="kicker">${esc(p.launch.label)}</span><b class="mono" data-until="${p.launch.when}">${until(p.launch.when)}</b></div>` : ""}
    ${p.note ? `<div class="pq-n">${esc(p.note)}</div>` : ""}
    ${items.length ? `<div class="rows">${items.map((c) => { const [cls, lab] = ST[c.status] || ST.candidate; return `<div class="row"><span class="rank">${c.secs ? c.secs + "s" : "—"}</span><div><div class="t">${esc(c.title)}</div><div class="m">${esc(c.who || "")}${c.note ? " · " + esc(c.note) : ""}</div></div><div class="r"><span class="op-st ${cls}"><i></i>${lab}</span></div></div>`; }).join("")}</div>` : `<div class="empty">// no clips in the pipeline yet</div>`}`;
}
function opsStrip() {
  const o = S.ops || {}, g = o.goal || { target: 30, earned: 0 }, all = opsAll();
  const moves = all.filter((c) => c.next).length, clips = ((o.pipeline || {}).items || []).length, live = all.filter((c) => c.status === "live").length;
  const tile = (href, big, lab, sub, hot) => `<a class="tile ${hot ? "hot" : ""}" href="${href}"><b class="mono">${big}</b><span>${lab}</span><small>${sub}</small></a>`;
  return `<section class="strip">
    ${tile("#/inbox", unread(), "New replies", `${(S.replies || []).length} in the inbox`, unread() > 0)}
    ${tile("#/money", "$" + fmt(g.earned || 0), "Earned", `goal $${g.target} · ${live} channels live`)}
    ${tile("#/money", moves, "Your moves", moves ? "things only you can click" : "nothing waiting on you", moves > 0)}
    ${tile("javascript:TABS.mn='pipe';location.hash='#/money'", clips, "Clip pipeline", (o.pipeline || {}).launch ? `launch in <i data-until="${o.pipeline.launch.when}">${until(o.pipeline.launch.when)}</i>` : "clips judged")}
  </section>`;
}
function moneyPage() {
  const o = S.ops || {}, g = o.goal || { target: 30, earned: 0, label: "Goal" }, all = opsAll();
  const moves = all.filter((c) => c.next);
  const t = tabs("mn", [["moves", "Your moves", moves.length], ["clip", "Clipping pay", (o.programs || []).length], ["svc", "Services", (o.services || []).length], ["out", "Outreach", (o.outreach || []).length], ["pipe", "Clip pipeline", ((o.pipeline || {}).items || []).length]], "moves");
  const grid = (l) => (l || []).length ? `<div class="ops">${l.map(opsCard).join("")}</div>` : `<div class="empty">// nothing here yet</div>`;
  const body = { moves: () => moves.length ? grid(moves) : `<div class="empty">// nothing is waiting on you</div>`, clip: () => grid(o.programs), svc: () => grid(o.services), out: () => grid(o.outreach), pipe: pipeBody }[t.cur]();
  return `<section class="core money">
    <div class="side">${dial({ value: all.filter((c) => c.status === "live").length, label: "Live channels", sub: `${all.length} set up`, frac: all.filter((c) => c.status === "live").length / Math.max(1, all.length), color: "var(--ok)" })}${dial({ value: moves.length, label: "Your moves", sub: "waiting on you", frac: moves.length / Math.max(1, all.length), color: "var(--amber)" })}</div>
    <div class="mid">${reactor({ value: g.earned || 0, label: "Earned · USD", sub: `${esc(g.label || "goal")} · $${g.target}`, progress: (g.earned || 0) / (g.target || 1), color: "#3ef0a1", size: 340 })}</div>
    <div class="side">${dial({ value: unread(), label: "New replies", sub: `${(S.replies || []).length} total`, frac: unread() ? 1 : 0 })}${dial({ value: ((o.pipeline || {}).items || []).length, label: "Clips judged", sub: "in the pipeline", frac: .5, color: "#ffd60a" })}</div>
  </section>
  <section class="panel console">${t.bar}<div class="tab-body">${body}</div><div class="foot">Sheet updated ${ago(o.updated_at)} · Claude keeps it current as things change</div></section>`;
}
const SRCGROUP = { buyers: ["Fiverr", "Ko-fi", "Contra", "X", "Discord"], streamers: ["Email reply"], pay: ["Content Rewards", "Vyro", "Kick"] };
function inboxPage() {
  const all = S.replies || [];
  const cnt = (k) => all.filter((r) => SRCGROUP[k].includes(r.source)).length;
  const t = tabs("ib", [["all", "All", all.length], ["buyers", "Buyers", cnt("buyers")], ["streamers", "Streamer emails", cnt("streamers")], ["pay", "Clipping pay", cnt("pay")], ["alerts", "Alerts setup"]], "all");
  const list = t.cur === "all" ? all : all.filter((r) => (SRCGROUP[t.cur] || []).includes(r.source));
  const rows = list.length ? `<div class="rows inbox">${list.map((r) => `<div class="row ${r.read ? "read" : "new"}"><span class="net">${esc(r.source)}</span>
      <div><div class="t">${r.url ? `<a href="${esc(r.url)}" target="_blank" onclick="readReply('${esc(r.id)}')">${esc(r.from || r.subject)}</a>` : esc(r.from || r.subject)}</div><div class="m">${r.from ? esc(r.subject) + " · " : ""}${esc(r.snippet).slice(0, 140)}</div></div>
      <div class="r"><span class="dim mono">${ago(r.at)}</span>${r.read ? "" : `<button class="x" title="Mark read" onclick="readReply('${esc(r.id)}')">✓</button>`}</div></div>`).join("")}</div>`
    : `<div class="empty">// no replies yet. ${(S.gmail || {}).boxes && S.gmail.boxes.length ? "Watching " + S.gmail.boxes.map(esc).join(", ") + " every minute." : `Connect Gmail under <a href="javascript:setTab('ib','alerts')">Alerts setup</a> to watch for them every minute.`}</div>`;
  return `<div class="page-h"><div><div class="kicker">Replies · ${unread()} new</div><h1>Inbox</h1></div>${unread() ? `<button class="btn" onclick="readReply()">Mark all read</button>` : ""}</div>
  <section class="panel console">${t.bar}<div class="tab-body">${t.cur === "alerts" ? alertsBody() : rows}</div></section>`;
}
async function readReply(id) {
  (S.replies || []).forEach((r) => { if (!id || r.id === id) r.read = true; }); render();
  await fetch("/api/reply-read", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(id ? { id } : { all: true }) });
}
const NT_SUG = "core-" + Math.random().toString(36).slice(2, 12);
function alertsBody() {
  const g = S.google || { client: false }, gm = S.gmail || { boxes: [], errors: [] }, nt = S.notify || {};
  const sug = NT_SUG;
  return `<div class="cols2">
    <div class="cat"><h4>1 · Where replies come from</h4>
      <p class="dim" style="line-height:1.6;margin-top:0">Fiverr, Ko-fi, Contra, Discord, X and the clipping programs all email you when someone writes. The Core reads that Gmail inbox every minute (read-only, stays on this Mac) and files anything from a buyer or streamer here.</p>
      <div class="log">${gm.boxes.map((b) => `<div><span class="ok">●</span> ${esc(b)} <button class="x" onclick="ntSave({gmail_remove:'${esc(b)}'})">×</button></div>`).join("")}${(gm.errors || []).map((e) => `<div><span class="w">●</span> ${esc(e)}</div>`).join("")}</div>
      ${g.client ? `<div class="act-row"><a class="btn primary" href="/oauth/google?kind=gmail">${gm.boxes.length ? "+ Watch another Gmail" : "Connect Gmail"}</a></div>` : `<div class="nc-todo" style="text-align:left">Needs the Google link first (Links → YouTube stats).</div>`}</div>
    <div class="cat"><h4>2 · Where the ping goes</h4>
      <div class="log"><div><span class="${nt.desktop ? "ok" : "off"}">●</span> This Mac: banner + sound</div><div><span class="ok">●</span> Claude app: hourly buyer check pushes to your phone</div><div><span class="${nt.topic ? "ok" : "w"}">●</span> Phone, instant: ${nt.topic ? "on, topic " + esc(nt.topic) : "off"}</div></div>
      <p class="dim" style="line-height:1.6">For an instant phone ping, install the free <b>ntfy</b> app, subscribe to the topic below, then press Save. The ping carries only the sender and subject line.</p>
      <div class="keybox"><input id="nt-topic" value="${esc(nt.topic || sug)}" placeholder="topic name"><button class="btn primary" onclick="ntSave({topic:$('#nt-topic').value})">Save</button><button class="btn" onclick="ntSave({test:true})">Send test</button>${nt.topic ? `<button class="btn" onclick="ntSave({topic:''})">Turn off</button>` : ""}</div></div></div>`;
}
async function ntSave(body) {
  const r = await fetch("/api/notify", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
  const j = await r.json(); toast(body.test ? (j.phone === false ? "Phone ping failed" : "Test sent") : "Saved"); load();
}
async function setConn(account, network, status) {
  const handle = ($(`#h-${account}-${network}`) || {}).value || "";
  if (status === "public" && !handle.trim()) { alertish(`#h-${account}-${network}`); return; }
  editCell = null;
  await fetch("/api/config", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ account, network, handle, status }) });
  toast(status === "off" ? "Tracking off" : `Tracking @${esc(handle.replace(/^@/, ""))} live`);
  setTimeout(load, 300); setTimeout(load, 8000);
}
function alertish(sel) { const el = $(sel); if (el) { el.style.borderColor = "var(--amber)"; el.focus(); } }

// ---------- router ----------
function nav() {
  const h = location.hash || "#/overview";
  const on = (x) => (h === x ? "on" : "");
  $("#nav").innerHTML = `<a href="#/overview" class="${on("#/overview")}">Core</a><span class="nsep"></span>
    ${S.accounts.map((a) => `<a href="#/a/${a.id}" class="acc ${on("#/a/" + a.id)}" style="--ac:${a.color}" title="${esc(a.name)}"><img src="assets/${a.id}.png" alt=""><span>${esc(a.name)}</span></a>`).join("")}
    <span class="nsep"></span><a href="#/ideas" class="${on("#/ideas")}">Ideas</a><a href="#/money" class="${on("#/money")}">Money</a>
    <a href="#/inbox" class="${on("#/inbox")}">Inbox${unread() ? `<sup class="badge">${unread()}</sup>` : ""}</a><a href="#/connections" class="${on("#/connections")}">Links</a>`;
}
function render() {
  if (!S) return;
  nav(); statusLine();
  const h = location.hash || "#/overview";
  const focusId = document.activeElement && document.activeElement.id;
  if (focusId && /^(h-|g-|buf-|nt-)/.test(focusId) && $("#view").dataset.page === h) return; // don't clobber typing
  const html = h.startsWith("#/a/") ? accountPage(h.slice(4)) : h === "#/ideas" ? ideasPage() : h === "#/money" ? moneyPage() : h === "#/inbox" ? inboxPage() : h === "#/connections" ? connectionsPage() : overview();
  const v = $("#view");
  const changed = v.dataset.page !== h;
  if (changed) { v.classList.remove("enter"); void v.offsetWidth; v.classList.add("enter"); v.dataset.page = h; scrollTo({ top: 0 }); }
  const openD = changed ? [] : [...v.querySelectorAll("details")].map((d) => d.open);
  const sy = scrollY;
  v.innerHTML = html;
  if (!changed) { v.querySelectorAll("details").forEach((d, i) => { if (openD[i]) d.open = true; }); if (scrollY !== sy) scrollTo({ top: sy }); }
  document.querySelectorAll("#view [data-count]").forEach((el, i) => countUp(el, +el.dataset.count || 0, h + i));
}
const shown = {};
function countUp(el, to, key) {
  const from = shown[key] ?? 0; shown[key] = to;
  if (REDUCED || from === to) { el.textContent = fmt(to); return; }
  const t0 = performance.now(), dur = 1200;
  const step = (t) => { const p = Math.min(1, (t - t0) / dur), e = 1 - Math.pow(1 - p, 4); el.textContent = fmt(Math.round(from + (to - from) * e)); if (p < 1) requestAnimationFrame(step); };
  requestAnimationFrame(step);
}
window.addEventListener("hashchange", render);
load();
stream();
setInterval(() => { if (!streamOK) load(); }, 30000); // fallback if the live link drops

// ---- boot: reactor powers up (once per session) ----
(function boot() {
  let seen = false; try { seen = sessionStorage.getItem("hud-boot"); sessionStorage.setItem("hud-boot", "1"); } catch (e) {}
  if (seen || REDUCED) return;
  document.body.insertAdjacentHTML("beforeend", `<div id="boot"><div class="boot-core"><i></i><i></i><i></i><b></b></div><div id="boot-l"></div></div>`);
  const lines = ["Powering core", "Linking Metricool · Buffer", "Scanning accounts · inbox · pay", "Online"];
  lines.forEach((l, i) => setTimeout(() => { const el = $("#boot-l"); if (el) el.textContent = l; }, i * 380));
  setTimeout(() => { const b = $("#boot"); if (b) { b.classList.add("out"); setTimeout(() => b.remove(), 700); } }, 1650);
})();
