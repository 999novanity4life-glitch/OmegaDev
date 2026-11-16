#!/usr/bin/env python3
"""Creator HUD: a tiny local server for the dashboard. Python 3 standard library only.

    python3 server.py          -> http://localhost:8787

Data it merges, every few minutes:
  data/content.json   ideas, rendered videos, queue (built from project files by Claude)
  data/metricool.json Metricool analytics snapshot (refreshed by Claude via the Metricool connector)
  live, from this Mac: YouTube public feed (views per Short) and public TikTok/YouTube
  profile counters. Anything that fails just falls back to the snapshot or "not connected".
  Buffer (optional): with a personal API key saved in data/buffer_key (this Mac only), per-post
  views/likes/comments/shares for the channels Buffer posts to.

Live updates: the page holds an open /api/stream connection (Server-Sent Events). The server pushes
new state the moment a scan finishes or any data file changes, and tells the page to reload itself
when the web files change. No manual refresh needed.
"""
import json, os, re, sys, threading, time, datetime, urllib.request, urllib.error, webbrowser
import xml.etree.ElementTree as ET
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "data")
WEB = os.path.join(HERE, "web")
UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36"

LIVE = {"at": None, "accounts": {}, "log": []}
LOCK = threading.Lock()
VER = {"state": 0, "web": ""}          # bumps when anything the page shows changes
VER_COND = threading.Condition()
LAST = {"tt_videos": 0, "buffer": 0, "yta": 0}
GM_ERR = []  # slower tiers
BUFFER_KEY = os.path.join(DATA, "buffer_key")
BUFFER_KEYS = os.path.join(DATA, "buffer_keys.json")
BUFFER_API = "https://api.buffer.com"


def bump():
    with VER_COND:
        VER["state"] += 1
        VER_COND.notify_all()


def now_iso():
    return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")


def load(name, default):
    try:
        with open(os.path.join(HERE, name) if name.endswith("config.json") else os.path.join(DATA, name)) as f:
            return json.load(f)
    except Exception:
        return default


def fetch(url, timeout=12):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", "replace")


def num(s):
    """'1.2K' -> 1200, '3,401' -> 3401"""
    if s is None:
        return None
    s = str(s).replace(",", "").strip()
    m = re.match(r"([\d.]+)\s*([KkMmBb]?)", s)
    if not m:
        return None
    mult = {"": 1, "k": 1e3, "m": 1e6, "b": 1e9}[m.group(2).lower()]
    return int(float(m.group(1)) * mult)


# ---------- live sources (all optional, all best-effort) ----------

def yt_feed(channel_id):
    xml = fetch(f"https://www.youtube.com/feeds/videos.xml?channel_id={channel_id}")
    ns = {"a": "http://www.w3.org/2005/Atom", "yt": "http://www.youtube.com/xml/schemas/2015",
          "m": "http://search.yahoo.com/mrss/"}
    root = ET.fromstring(xml)
    vids = []
    for e in root.findall("a:entry", ns):
        vid = e.findtext("yt:videoId", default="", namespaces=ns)
        stats = e.find("m:group/m:community/m:statistics", ns)
        rating = e.find("m:group/m:community/m:starRating", ns)
        vids.append({
            "id": vid,
            "title": e.findtext("a:title", default="", namespaces=ns),
            "published": e.findtext("a:published", default="", namespaces=ns),
            "url": f"https://www.youtube.com/shorts/{vid}",
            "views": int(stats.get("views")) if stats is not None else None,
            "likes": int(rating.get("count")) if rating is not None else None,
        })
    return vids


def yt_subs(handle):
    html = fetch(f"https://www.youtube.com/@{handle}")
    m = re.search(r'"([\d.,]+[KMB]?) subscribers?"', html)
    return num(m.group(1)) if m else None


def tt_profile(handle):
    html = fetch(f"https://www.tiktok.com/@{handle}")
    out = {}
    for key, name in (("followerCount", "followers"), ("heartCount", "likes"), ("videoCount", "video_count")):
        m = re.search(r'"%s":(\d+)' % key, html)
        if m:
            out[name] = int(m.group(1))
    return out


def tt_video(handle, vid):
    html = fetch(f"https://www.tiktok.com/@{handle}/video/{vid}")
    i = html.find('"id":"%s"' % vid)
    chunk = html[i:i + 20000] if i >= 0 else html
    out = {}
    for key, name in (("playCount", "views"), ("diggCount", "likes"), ("commentCount", "comments"), ("shareCount", "shares")):
        m = re.search(r'"%s":(\d+)' % key, chunk)
        if m:
            out[name] = int(m.group(1))
    return out


def yt_channel_id(handle):
    html = fetch(f"https://www.youtube.com/@{handle}")
    m = re.search(r'"(?:channelId|externalId)":"(UC[\w-]{20,})"', html) or re.search(r'channel/(UC[\w-]{20,})', html)
    return m.group(1) if m else None


# ---------- Buffer (personal API key, GraphQL) ----------

def buffer_keys():
    """{label: key}. Several Buffer accounts can be connected (data/buffer_keys.json, this Mac only)."""
    out = {}
    try:
        with open(BUFFER_KEY) as f:
            k = f.read().strip()
            if k:
                out["Buffer 1"] = k
    except Exception:
        pass
    try:
        with open(BUFFER_KEYS) as f:
            out.update({str(a): str(b) for a, b in json.load(f).items() if b})
    except Exception:
        pass
    return out


def buffer_key():
    return next(iter(buffer_keys().values()), None)


def gql(key, query, variables=None):
    body = json.dumps({"query": query, "variables": variables or {}}).encode()
    req = urllib.request.Request(BUFFER_API, data=body, method="POST", headers={
        "Content-Type": "application/json", "Authorization": f"Bearer {key}", "User-Agent": "creator-hud/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            out = json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        raise RuntimeError("key rejected" if e.code in (401, 403) else f"HTTP {e.code}")
    if out.get("errors"):
        raise RuntimeError("; ".join(x.get("message", "?") for x in out["errors"])[:200])
    return out.get("data") or {}


POSTS_Q = """query Posts($org: OrganizationId!, $ch: [ChannelId!], $after: String) {
  posts(first: 50, after: $after, input: { organizationId: $org, filter: { status: [sent], channelIds: $ch } }) {
    edges { node { id text dueAt channelId metricsUpdatedAt metrics { type name value unit } } }
    pageInfo { endCursor hasNextPage } } }"""


def _metric(ms, *words):
    for m in ms or []:
        k = f"{m.get('type','')} {m.get('name','')}".lower()
        if any(w in k for w in words):
            try:
                return int(float(m.get("value") or 0))
            except Exception:
                return None
    return None


def _nk(s):
    return re.sub(r"[^a-z0-9]", "", (s or "").lower())


def buffer_match(cfg, ch):
    """Which HUD account/network a Buffer channel belongs to: explicit buffer_channel id first, then handle."""
    svc = (ch.get("service") or "").lower()
    net = "youtube" if "youtube" in svc else "tiktok" if "tiktok" in svc else "instagram" if "instagram" in svc else None
    for a in cfg.get("accounts", []):
        for n, c in a.get("networks", {}).items():
            if c.get("buffer_channel") == ch.get("id"):
                return a["id"], n
    if not net:
        return None, None
    names = {_nk(ch.get("name")), _nk(ch.get("displayName"))} - {""}
    for a in cfg.get("accounts", []):
        h = _nk(a.get("networks", {}).get(net, {}).get("handle"))
        if h and any(x == h or (len(x) > 5 and (x in h or h in x)) for x in names):
            return a["id"], net
    return None, net


def refresh_buffer():
    keys = buffer_keys()
    if not keys:
        return {"connected": False, "reason": "no key"}
    cfg = load("config.json", {})
    old = load("buffer.json", {})
    out = {"connected": True, "at": now_iso(), "channels": [], "error": None, "accounts": {}}
    for label, key in keys.items():
        one = _buffer_one(cfg, key)
        for c in one["channels"]:
            c["buffer"] = label
        if one["error"]:  # keep this Buffer's last good numbers
            one["channels"] = [c for c in old.get("channels", []) if c.get("buffer", "Buffer 1") == label]
            out["error"] = f"{label}: {one['error']}"
        out["accounts"][label] = {"error": one["error"], "channels": len(one["channels"])}
        out["channels"] += one["channels"]
    with open(os.path.join(DATA, "buffer.json"), "w") as fh:
        json.dump(out, fh, indent=1, ensure_ascii=False)
    return out


def _buffer_one(cfg, key):
    out = {"channels": [], "error": None}
    try:
        orgs = gql(key, "query { account { organizations { id name } } }").get("account", {}).get("organizations", [])
        for o in orgs:
            chs = gql(key, "query C($org: OrganizationId!) { channels(input: { organizationId: $org }) { id name displayName service avatar } }",
                      {"org": o["id"]}).get("channels", [])
            posts, after = [], None
            for _ in range(6):  # up to 300 sent posts
                d = gql(key, POSTS_Q, {"org": o["id"], "ch": [c["id"] for c in chs], "after": after}).get("posts", {})
                posts += [e["node"] for e in d.get("edges", [])]
                if not d.get("pageInfo", {}).get("hasNextPage"):
                    break
                after = d["pageInfo"].get("endCursor")
            for c in chs:
                acc, net = buffer_match(cfg, c)
                vids = []
                for p in posts:
                    if p.get("channelId") != c["id"]:
                        continue
                    ms = p.get("metrics") or []
                    first = (p.get("text") or "").strip().split("\n")[0]
                    vids.append({"id": "buf-" + p["id"], "title": (first[:80] or "Untitled post"), "published": p.get("dueAt"),
                                 "views": _metric(ms, "view", "play", "impression"), "likes": _metric(ms, "like", "reaction"),
                                 "comments": _metric(ms, "comment"), "shares": _metric(ms, "share", "repost"),
                                 "metrics_at": p.get("metricsUpdatedAt"), "via": "buffer"})
                out["channels"].append({"id": c["id"], "name": c.get("displayName") or c.get("name"), "service": c.get("service"),
                                        "avatar": c.get("avatar"), "account": acc, "network": net, "videos": vids})
    except Exception as e:
        out["error"] = str(e)
    return out


# ---------- YouTube Analytics (free, OAuth once per channel, tokens stay on this Mac) ----------
G_CLIENT = os.path.join(DATA, "google_client.json")   # {"client_id": ..., "client_secret": ...} (Desktop OAuth client)
G_TOKENS = os.path.join(DATA, "google_tokens.json")   # {channel_id: {"refresh_token": ..., "title": ...}}
G_SCOPES = "https://www.googleapis.com/auth/yt-analytics.readonly https://www.googleapis.com/auth/youtube.readonly"
OAUTH_STATE = {}
YT_METRICS = ["views", "engagedViews", "estimatedMinutesWatched", "averageViewDuration", "averageViewPercentage",
              "likes", "comments", "shares", "subscribersGained"]


def _secret_write(path, obj):
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as fh:
        json.dump(obj, fh, indent=1)


def _post_form(url, fields):
    import urllib.parse
    req = urllib.request.Request(url, data=urllib.parse.urlencode(fields).encode(), method="POST",
                                 headers={"Content-Type": "application/x-www-form-urlencoded"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.loads(r.read().decode())


def _gget(url, token):
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.loads(r.read().decode())


def g_access(refresh_token):
    c = load("google_client.json", {})
    return _post_form("https://oauth2.googleapis.com/token", {"client_id": c["client_id"], "client_secret": c.get("client_secret", ""),
                      "refresh_token": refresh_token, "grant_type": "refresh_token"})["access_token"]


def yt_analytics_one(cid, tok):
    import urllib.parse
    at = g_access(tok["refresh_token"])
    out = {"at": now_iso(), "title": tok.get("title"), "videos": {}}
    ch = _gget(f"https://www.googleapis.com/youtube/v3/channels?part=statistics,contentDetails&id={cid}", at).get("items", [])
    if ch:
        st = ch[0]["statistics"]
        out["subscribers"] = int(st.get("subscriberCount", 0))
        out["channel_views"] = int(st.get("viewCount", 0))
        uploads = ch[0]["contentDetails"]["relatedPlaylists"]["uploads"]
        pl = _gget(f"https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&maxResults=50&playlistId={uploads}", at).get("items", [])
        ids = [x["contentDetails"]["videoId"] for x in pl]
        if ids:  # real-time public counters + titles
            for v in _gget(f"https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics,contentDetails&id={','.join(ids)}", at).get("items", []):
                s = v.get("statistics", {})
                out["videos"][v["id"]] = {"id": v["id"], "title": v["snippet"]["title"], "published": v["snippet"]["publishedAt"],
                                          "url": f"https://www.youtube.com/shorts/{v['id']}", "views": int(s.get("viewCount", 0)),
                                          "likes": int(s.get("likeCount", 0)), "comments": int(s.get("commentCount", 0)),
                                          "length": v.get("contentDetails", {}).get("duration")}
    today = datetime.date.today().isoformat()
    metrics = list(YT_METRICS)
    for attempt in range(2):
        q = urllib.parse.urlencode({"ids": "channel==MINE", "startDate": "2020-01-01", "endDate": today, "dimensions": "video",
                                    "metrics": ",".join(metrics), "sort": "-views", "maxResults": 200})
        try:
            rep = _gget("https://youtubeanalytics.googleapis.com/v2/reports?" + q, at)
            break
        except urllib.error.HTTPError as e:
            if attempt == 0 and "engagedViews" in metrics:
                metrics.remove("engagedViews")  # older API combos reject it; drop and retry
                continue
            raise
    names = [h["name"] for h in rep.get("columnHeaders", [])]
    keymap = {"views": "a_views", "engagedViews": "engaged_views", "estimatedMinutesWatched": "watch_min", "averageViewDuration": "avg_view_s",
              "averageViewPercentage": "avg_pct", "likes": "a_likes", "comments": "a_comments", "shares": "shares", "subscribersGained": "subs_gained"}
    for row in rep.get("rows", []):
        r = dict(zip(names, row))
        v = out["videos"].setdefault(r["video"], {"id": r["video"], "url": f"https://www.youtube.com/shorts/{r['video']}"})
        for k, val in r.items():
            if k in keymap:
                v[keymap[k]] = val
    out["analytics_note"] = "YouTube Analytics (deep stats) lags minutes to hours; view/like counts are real time."
    return out


def refresh_yt_analytics():
    toks = load("google_tokens.json", {})
    if not toks or not os.path.exists(G_CLIENT):
        return []
    res, errs = load("yt_analytics.json", {}), []
    for cid, tok in toks.items():
        try:
            res[cid] = yt_analytics_one(cid, tok)
        except Exception as e:
            msg = f"YouTube Analytics ({tok.get('title') or cid}): {getattr(e, 'code', '')} {e.__class__.__name__}".strip()
            errs.append(msg)
            if cid in res:
                res[cid]["error"] = msg
    with open(os.path.join(DATA, "yt_analytics.json"), "w") as fh:
        json.dump(res, fh, indent=1, ensure_ascii=False)
    return errs


# ---------- reply inbox + notifications ----------
GM_TOKENS = os.path.join(DATA, "gmail_tokens.json")   # {email: {"refresh_token": ...}} read-only scope, this Mac only
GM_SCOPE = "https://www.googleapis.com/auth/gmail.readonly"
REPLY_LOCK = threading.Lock()
SOURCES = [("fiverr.com", "Fiverr"), ("ko-fi.com", "Ko-fi"), ("contra.com", "Contra"), ("discord.com", "Discord"),
           ("x.com", "X"), ("twitter.com", "X"), ("whop.com", "Content Rewards"), ("contentrewards", "Content Rewards"),
           ("vyro", "Vyro"), ("kick.com", "Kick")]
PLATFORM_WORDS = re.compile(r"message|repl|order|inquir|request|mention|sent you|offer|paid|payout|payment|commission|"
                            r"approved|rejected|accepted|earn|tip|bought|purchase|invite|review", re.I)


def notify(title, body):
    """Desktop banner on this Mac, plus a phone push through ntfy if a topic is set on the Links page."""
    title, body = str(title)[:80], str(body)[:160]
    if sys.platform == "darwin":
        try:
            import subprocess
            q = lambda x: x.replace("\\", "").replace('"', "'")
            subprocess.run(["osascript", "-e", f'display notification "{q(body)}" with title "{q(title)}" sound name "Glass"'], timeout=5)
        except Exception:
            pass
    topic = load("config.json", {}).get("ntfy_topic")
    if topic:
        try:
            req = urllib.request.Request(f"https://ntfy.sh/{topic}", data=body.encode(), method="POST",
                                         headers={"Title": title.encode("ascii", "ignore").decode(), "Tags": "incoming_envelope", "Priority": "high"})
            urllib.request.urlopen(req, timeout=10).read()
            return True
        except Exception as e:
            print("ntfy:", e)
            return False
    return None


def add_reply(item, ping=True):
    """item: {source, from, subject, snippet, url, at, id?}. Returns False if it was already there."""
    with REPLY_LOCK:
        items = load("replies.json", [])
        rid = str(item.get("id") or f"m{int(time.time() * 1000)}")
        if any(x.get("id") == rid for x in items):
            return False
        row = {"id": rid, "source": str(item.get("source") or "Reply")[:30], "from": str(item.get("from") or "")[:80],
               "subject": str(item.get("subject") or "")[:160], "snippet": str(item.get("snippet") or "")[:300],
               "url": str(item.get("url") or "")[:400], "at": item.get("at") or now_iso(), "read": not ping and bool(item.get("read"))}
        items.insert(0, row)
        with open(os.path.join(DATA, "replies.json"), "w") as fh:
            json.dump(items[:300], fh, indent=1, ensure_ascii=False)
    if ping:
        notify(f"New reply · {row['source']}", f"{row['from']}: {row['subject']}" if row["from"] else row["subject"])
    return True


def _classify(sender, subject):
    low = sender.lower()
    for dom, name in SOURCES:
        if dom in low:
            return name if PLATFORM_WORDS.search(subject) else None
    if re.match(r"\s*re:", subject, re.I) and not re.search(r"no-?reply|mailer-daemon|notification", low):
        return "Email reply"
    return None


def refresh_gmail():
    toks = load("gmail_tokens.json", {})
    if not toks or not os.path.exists(G_CLIENT):
        return []
    import urllib.parse, email.utils
    seen = load("gmail_seen.json", {})
    errs = []
    for addr, tok in toks.items():
        first = addr not in seen
        ids = set(seen.get(addr, []))
        try:
            at = g_access(tok["refresh_token"])
            q = urllib.parse.urlencode({"q": "in:inbox newer_than:7d -from:me", "maxResults": 40})
            msgs = _gget(f"https://gmail.googleapis.com/gmail/v1/users/me/messages?{q}", at).get("messages", [])
            for m in reversed(msgs):
                if m["id"] in ids:
                    continue
                ids.add(m["id"])
                d = _gget(f"https://gmail.googleapis.com/gmail/v1/users/me/messages/{m['id']}?format=metadata"
                          "&metadataHeaders=From&metadataHeaders=Subject", at)
                h = {x["name"].lower(): x["value"] for x in d.get("payload", {}).get("headers", [])}
                src = _classify(h.get("from", ""), h.get("subject", ""))
                if not src:
                    continue
                name = email.utils.parseaddr(h.get("from", ""))[0] or h.get("from", "")
                when = datetime.datetime.fromtimestamp(int(d.get("internalDate", "0")) / 1000, datetime.timezone.utc).isoformat(timespec="seconds")
                add_reply({"id": "gm-" + m["id"], "source": src, "from": name, "subject": h.get("subject", ""), "snippet": d.get("snippet", ""),
                           "url": f"https://mail.google.com/mail/u/?authuser={addr}#inbox/{d.get('threadId', m['id'])}", "at": when},
                          ping=not first)  # the first scan fills the inbox quietly
            seen[addr] = list(ids)[-500:]
        except Exception as e:
            errs.append(f"Gmail ({addr}): {getattr(e, 'code', '')} {e.__class__.__name__}".strip())
    with open(os.path.join(DATA, "gmail_seen.json"), "w") as fh:
        json.dump(seen, fh)
    return errs


def refresh_live(force=False):
    cfg = load("config.json", {})
    t = time.time()
    do_ttv = force or t - LAST["tt_videos"] > 600       # per-video TikTok pages: every 10 min
    do_buf = force or t - LAST["buffer"] > 900          # Buffer: every 15 min (Buffer itself updates ~daily)
    do_yta = force or t - LAST["yta"] > 120             # YouTube API: every 2 min (quota is plenty)
    cfg_dirty = False
    prev = LIVE["accounts"]
    snap = load("metricool.json", {})
    result, log = {}, []
    for a in cfg.get("accounts", []):
        acc = {}
        for net, n in a.get("networks", {}).items():
            if n.get("status") not in ("connected", "public"):
                continue
            live = {}
            try:
                if net == "youtube" and n.get("handle") and not n.get("channel_id"):
                    try:
                        cid = yt_channel_id(n["handle"])
                        if cid:
                            n["channel_id"], cfg_dirty = cid, True
                    except Exception:
                        log.append(f"{a['name']} youtube: couldn't find the channel id for @{n['handle']} yet")
                if net == "youtube" and n.get("channel_id"):
                    live["videos"] = yt_feed(n["channel_id"])
                    if n.get("handle"):
                        try:
                            s = yt_subs(n["handle"])
                            if s is not None:
                                live["followers"] = s
                        except Exception as e:
                            log.append(f"{a['name']} youtube: subscriber count unavailable")
                elif net == "tiktok" and n.get("handle"):
                    live.update(tt_profile(n["handle"]))
                    old_v = prev.get(a["id"], {}).get(net, {}).get("videos")
                    if not do_ttv and old_v:
                        live["videos"] = old_v
                        raise StopIteration
                    brand = snap.get("brands", {}).get(str(a.get("metricool_brand")), {})
                    vids = []
                    for v in brand.get("networks", {}).get("tiktok", {}).get("videos", [])[:30]:
                        try:
                            s = tt_video(n["handle"], v["id"])
                            if s:
                                vids.append({"id": v["id"], **s})
                        except Exception:
                            pass
                    if vids:
                        live["videos"] = vids
            except StopIteration:
                pass
            except Exception as e:
                log.append(f"{a['name']} {net}: couldn't reach {net} right now ({e.__class__.__name__}), showing the Metricool snapshot")
            if live:
                live["at"] = now_iso()
                acc[net] = live
        result[a["id"]] = acc
    if cfg_dirty:
        save_config_ids(cfg)
    if do_ttv:
        LAST["tt_videos"] = t
    if do_buf:
        LAST["buffer"] = t
        try:
            b = refresh_buffer()
            if b.get("error"):
                log.append(f"Buffer: {b['error']} (showing last good numbers)")
        except Exception as e:
            log.append(f"Buffer: {e.__class__.__name__}")
    if do_yta:
        LAST["yta"] = t
        try:
            log += refresh_yt_analytics()
        except Exception as e:
            log.append(f"YouTube Analytics: {e.__class__.__name__}")
    with LOCK:
        LIVE["accounts"], LIVE["log"], LIVE["at"] = result, log, now_iso()
    record_history()
    bump()


def save_config_ids(cfg_new):
    """Write back resolved channel ids without clobbering edits made meanwhile."""
    cfg = load("config.json", {})
    for a in cfg.get("accounts", []):
        an = next((x for x in cfg_new.get("accounts", []) if x["id"] == a["id"]), None)
        for net, n in a.get("networks", {}).items():
            cid = an and an.get("networks", {}).get(net, {}).get("channel_id")
            if cid and not n.get("channel_id") and n.get("handle") == an["networks"][net].get("handle"):
                n["channel_id"] = cid
    with open(os.path.join(HERE, "config.json"), "w") as fh:
        json.dump(cfg, fh, indent=2)


# ---------- merge ----------

def merged_state():
    cfg = load("config.json", {})
    snap = load("metricool.json", {})
    content = load("content.json", {"ideas": [], "videos": [], "queue": []})
    with LOCK:
        live = json.loads(json.dumps(LIVE))
    buf = load("buffer.json", {}) if buffer_key() else {}
    yta = load("yt_analytics.json", {}) if os.path.exists(G_TOKENS) else {}
    bufmap = {}
    for c in buf.get("channels", []):
        if c.get("account") and c.get("network"):
            bufmap.setdefault((c["account"], c["network"]), []).extend(c.get("videos", []))
    accounts = []
    scheduled = []
    for a in cfg.get("accounts", []):
        brand = snap.get("brands", {}).get(str(a.get("metricool_brand")), {}) if a.get("metricool_brand") else {}
        nets = {}
        for net, n in a.get("networks", {}).items():
            s = brand.get("networks", {}).get(net) if n.get("status") == "connected" else None
            l = live["accounts"].get(a["id"], {}).get(net)
            d = {"status": n.get("status", "off"), "handle": n.get("handle", ""), "todo": n.get("todo"),
                 "via": n.get("via"), "source": None, "followers": None, "views": None, "likes": None,
                 "comments": None, "shares": None, "videos": []}
            if s:
                d["source"] = "metricool"
                for k in ("followers", "views", "likes", "comments", "shares"):
                    d[k] = s.get(k)
                d["videos"] = [dict(v) for v in s.get("videos", [])]
            if l:
                d["source"] = "live" if not s else "live+metricool"
                for k in ("followers", "likes"):
                    if l.get(k) is not None:
                        d[k] = max(l[k], d[k] or 0)
                byid = {v.get("id"): v for v in d["videos"]}
                for lv in l.get("videos", []):
                    if lv.get("id") in byid:
                        for k, val in lv.items():
                            if val is not None and k not in ("title", "url", "published"):
                                byid[lv["id"]][k] = max(val, byid[lv["id"]].get(k) or 0) if isinstance(val, int) else val
                    elif lv.get("title"):
                        d["videos"].append(lv)
                vsum = sum(v.get("views") or 0 for v in d["videos"])
                d["views"] = max(vsum, d["views"] or 0)
            ya = yta.get(n.get("channel_id")) if net == "youtube" else None
            if ya:
                d["analytics_at"], d["source"] = ya.get("at"), ((d["source"] or "") + "+youtube-api").lstrip("+")
                if ya.get("subscribers") is not None:
                    d["followers"] = ya["subscribers"]
                byid = {v.get("id"): v for v in d["videos"]}
                for vid, yv in ya.get("videos", {}).items():
                    tgt = byid.get(vid)
                    if not tgt:
                        if not yv.get("title"):
                            continue
                        tgt = {"id": vid}
                        d["videos"].append(tgt)
                        byid[vid] = tgt
                    for k, val in yv.items():
                        if k in ("views", "likes", "comments"):
                            tgt[k] = max(val or 0, tgt.get(k) or 0, yv.get("a_" + k) or 0)
                        elif not k.startswith("a_") and val is not None:
                            tgt[k] = val
                    tgt["stats_at"] = ya.get("at")
                for k in ("likes", "comments", "shares"):
                    d[k] = sum(v.get(k) or 0 for v in d["videos"]) or d[k]
                d["views"] = max(sum(v.get("views") or 0 for v in d["videos"]), d["views"] or 0)
                ev = [v for v in d["videos"] if v.get("engaged_views") is not None]
                d["engaged_views"] = sum(v["engaged_views"] for v in ev) if ev else None
                wv = [v for v in d["videos"] if v.get("avg_view_s") is not None and v.get("views")]
                if wv:
                    tv = sum(v["views"] for v in wv)
                    d["avg_view_s"] = round(sum(v["avg_view_s"] * v["views"] for v in wv) / tv, 1)
                    d["avg_pct"] = round(sum((v.get("avg_pct") or 0) * v["views"] for v in wv) / tv, 1)
                d["subs_gained"] = sum(v.get("subs_gained") or 0 for v in d["videos"])
            bv = bufmap.get((a["id"], net))
            if bv is not None:
                d["buffer"] = True
                d["source"] = (d["source"] + "+buffer") if d["source"] else "buffer"
                for b in bv:
                    twin = next((v for v in d["videos"] if _same_post(v, b)), None)
                    if twin:
                        for k in ("views", "likes", "comments", "shares"):
                            if b.get(k) is not None:
                                twin[k] = max(b[k], twin.get(k) or 0)
                        twin["via_buffer"] = True
                    else:
                        d["videos"].append(dict(b))
                for k in ("views", "likes", "comments", "shares"):
                    tot = sum(v.get(k) or 0 for v in d["videos"])
                    if tot:
                        d[k] = max(tot, d[k] or 0)
            d["videos"].sort(key=lambda v: v.get("published") or "", reverse=True)
            nets[net] = d
        for p in brand.get("scheduled", []):
            scheduled.append({"account": a["id"], **p})
        accounts.append({k: a.get(k) for k in ("id", "name", "tagline", "color")} | {"networks": nets,
                         "posts_used": brand.get("posts_used_this_month"), "posts_limit": brand.get("posts_limit_month")})
    # queue = Metricool schedule (authoritative) + queue-file items not already scheduled
    seen = {(q["account"], q["network"], q["when"][:13]) for q in scheduled}
    for q in content.get("queue", []):
        if (q["account"], q["network"], q["when"][:13]) not in seen:
            scheduled.append(q)
    upcoming = sorted([q for q in scheduled if _ts(q["when"]) > time.time() - 600], key=lambda q: _ts(q["when"]))
    return {
        "now": now_iso(),
        "metricool_synced": snap.get("synced_at"),
        "live_at": live.get("at"),
        "live_log": live.get("log", []),
        "refresh_minutes": cfg.get("refresh_minutes", 5),
        "accounts": accounts,
        "queue": upcoming,
        "ideas": content.get("ideas", []),
        "videos": content.get("videos", []),
        "content_built": content.get("built_at"),
        "history": load("history.json", []),
        "briefing": snap.get("briefing"),
        "best_times": snap.get("best_times"),
        "inbox": load("inbox.json", []),
        "buffer": {"connected": bool(buffer_key()), "at": buf.get("at"), "error": buf.get("error"),
                   "accounts": [{"label": k, **(buf.get("accounts", {}).get(k) or {})} for k in buffer_keys()],
                   "channels": [{k: c.get(k) for k in ("id", "name", "service", "account", "network", "buffer")} | {"posts": len(c.get("videos", []))}
                                for c in buf.get("channels", [])]},
        "web_version": VER["web"],
        "ops": load("ops.json", {}),
        "replies": load("replies.json", [])[:120],
        "gmail": {"boxes": list(load("gmail_tokens.json", {}).keys()), "errors": list(GM_ERR)},
        "notify": {"topic": cfg.get("ntfy_topic") or "", "desktop": sys.platform == "darwin"},
        "google": {"client": os.path.exists(G_CLIENT), "channels": [{"id": k, "title": v.get("title")} for k, v in load("google_tokens.json", {}).items()]},
    }


def _same_post(v, b):
    """Same video seen by two sources? Matching title start, or published within 15 minutes."""
    a1, b1 = _nk(v.get("title"))[:24], _nk(b.get("title"))[:24]
    if a1 and b1 and (a1.startswith(b1[:16]) or b1.startswith(a1[:16])):
        return True
    return bool(v.get("published") and b.get("published") and abs(_ts(v["published"]) - _ts(b["published"])) < 900)


def _ts(s):
    try:
        if len(s) == 16:  # 2026-11-13T10:00 (Central, from queue file)
            s += ":00-06:00"
        return datetime.datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()
    except Exception:
        return 0


def record_history():
    try:
        st = merged_state()
        pt = {"t": st["now"]}
        for a in st["accounts"]:
            f = sum(n["followers"] or 0 for n in a["networks"].values())
            v = sum(n["views"] or 0 for n in a["networks"].values())
            pt[a["id"]] = [f, v]
        hist = load("history.json", [])
        if hist and _ts(st["now"]) - _ts(hist[-1].get("t", "")) < 600:
            hist[-1] = pt  # keep one point per 10 minutes
        else:
            hist.append(pt)
        with open(os.path.join(DATA, "history.json"), "w") as fh:
            json.dump(hist[-3000:], fh)
    except Exception as e:
        print("history:", e)


def loop():
    while True:
        try:
            refresh_live()
        except Exception as e:
            print("refresh failed:", e)
        secs = load("config.json", {}).get("refresh_seconds", 90)
        time.sleep(max(30, secs))


def gmail_loop():
    while True:
        try:
            errs = refresh_gmail()
            if errs != GM_ERR:
                GM_ERR[:] = errs
                bump()
        except Exception as e:
            print("gmail:", e)
        time.sleep(60)


def _mtimes(folder, exts):
    out = {}
    for root, _, files in os.walk(folder):
        for f in files:
            if f.endswith(exts):
                try:
                    out[os.path.join(root, f)] = os.path.getmtime(os.path.join(root, f))
                except OSError:
                    pass
    return out


def watch_files():
    """Push to open pages when data/config change; ask them to reload when the web files change."""
    last_d, last_w = None, None
    while True:
        d = _mtimes(DATA, (".json", "buffer_key"))
        d[os.path.join(HERE, "config.json")] = os.path.getmtime(os.path.join(HERE, "config.json")) if os.path.exists(os.path.join(HERE, "config.json")) else 0
        d.pop(os.path.join(DATA, "history.json"), None)
        d.pop(os.path.join(DATA, "gmail_seen.json"), None)
        w = _mtimes(WEB, (".js", ".css", ".html", ".png", ".svg"))
        wv = str(hash(tuple(sorted(w.items()))))
        if last_d is not None and d != last_d:
            bump()
        if last_w is not None and wv != last_w:
            VER["web"] = wv
            bump()
        if not VER["web"]:
            VER["web"] = wv
        last_d, last_w = d, wv
        time.sleep(2)


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=WEB, **kw)

    def log_message(self, *a):
        pass

    def _json(self, obj):
        b = json.dumps(obj).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def do_GET(self):
        if self.path.startswith("/api/state"):
            return self._json(merged_state())
        if self.path.startswith("/api/stream"):
            return self._stream()
        if self.path.startswith("/oauth/google"):
            return self._oauth_start()
        if self.path.startswith("/oauth/callback"):
            return self._oauth_cb()
        return super().do_GET()

    def end_headers(self):
        if not self.path.startswith("/api/"):
            self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def _redirect(self, url):
        self.send_response(302)
        self.send_header("Location", url)
        self.end_headers()

    def _origin(self):
        return f"http://{self.headers.get('Host', 'localhost:8787')}"

    def _oauth_start(self):
        import urllib.parse, secrets
        c = load("google_client.json", {})
        if not c.get("client_id"):
            return self._redirect("/#/connections")
        st = secrets.token_urlsafe(16)
        kind = "gmail" if "kind=gmail" in self.path else "youtube"
        OAUTH_STATE[st] = kind
        q = urllib.parse.urlencode({"client_id": c["client_id"], "redirect_uri": self._origin() + "/oauth/callback", "response_type": "code",
                                    "scope": GM_SCOPE if kind == "gmail" else G_SCOPES, "access_type": "offline",
                                    "prompt": "consent select_account", "state": st})
        self._redirect("https://accounts.google.com/o/oauth2/v2/auth?" + q)

    def _oauth_cb(self):
        import urllib.parse
        qs = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        st, code = (qs.get("state") or [""])[0], (qs.get("code") or [""])[0]
        kind = OAUTH_STATE.pop(st, None)
        if not code or kind is None:
            return self._redirect("/#/connections")
        c = load("google_client.json", {})
        try:
            tok = _post_form("https://oauth2.googleapis.com/token", {"client_id": c["client_id"], "client_secret": c.get("client_secret", ""),
                             "code": code, "grant_type": "authorization_code", "redirect_uri": self._origin() + "/oauth/callback"})
            if kind == "gmail":
                addr = _gget("https://gmail.googleapis.com/gmail/v1/users/me/profile", tok["access_token"])["emailAddress"]
                boxes = load("gmail_tokens.json", {})
                boxes[addr] = {"refresh_token": tok.get("refresh_token") or boxes.get(addr, {}).get("refresh_token")}
                _secret_write(GM_TOKENS, boxes)
                threading.Thread(target=refresh_gmail, daemon=True).start()
                bump()
                return self._redirect("/#/inbox")
            chs = _gget("https://www.googleapis.com/youtube/v3/channels?part=snippet&mine=true", tok["access_token"]).get("items", [])
            toks = load("google_tokens.json", {})
            for ch in chs:
                old = toks.get(ch["id"], {})
                toks[ch["id"]] = {"refresh_token": tok.get("refresh_token") or old.get("refresh_token"), "title": ch["snippet"]["title"]}
            _secret_write(G_TOKENS, toks)
            LAST["yta"] = 0
            threading.Thread(target=refresh_live, daemon=True).start()
        except Exception as e:
            print("oauth:", e)
        self._redirect("/#/connections")

    def _stream(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Accel-Buffering", "no")
        self.end_headers()
        seen, web = -1, VER["web"]
        try:
            self.wfile.write(b"retry: 3000\n\n")
            while True:
                with VER_COND:
                    if VER["state"] == seen:
                        VER_COND.wait(timeout=15)
                    cur = VER["state"]
                if VER["web"] and VER["web"] != web:
                    self.wfile.write(b"event: reload\ndata: {}\n\n")
                    self.wfile.flush()
                    return
                if cur != seen:
                    seen = cur
                    self.wfile.write(b"event: state\ndata: " + json.dumps(merged_state()).encode() + b"\n\n")
                else:
                    self.wfile.write(b": ping\n\n")  # keep-alive
                self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError, OSError):
            return

    def do_POST(self):
        if self.path.startswith("/api/config"):
            n = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(n) or b"{}")
            cfg = load("config.json", {})
            for a in cfg.get("accounts", []):
                if a["id"] == body.get("account"):
                    net = a["networks"].setdefault(body.get("network"), {})
                    net["handle"] = str(body.get("handle", "")).strip().lstrip("@")
                    if body.get("status") in ("connected", "public", "pending", "off"):
                        net["status"] = body["status"]
            with open(os.path.join(HERE, "config.json"), "w") as fh:
                json.dump(cfg, fh, indent=2)
            threading.Thread(target=refresh_live, kwargs={"force": True}, daemon=True).start()
            return self._json({"ok": True})
        if self.path.startswith("/api/idea"):
            n = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(n) or b"{}")
            inbox = load("inbox.json", [])
            if body.get("delete") is not None:
                inbox = [i for i in inbox if i.get("id") != body["delete"]]
            elif str(body.get("title", "")).strip():
                inbox.append({"id": str(int(time.time() * 1000)), "account": body.get("account"),
                              "title": str(body["title"]).strip()[:200], "hook": str(body.get("hook", "")).strip()[:300],
                              "category": "New (from HUD)", "status": "new", "added": now_iso()})
            with open(os.path.join(DATA, "inbox.json"), "w") as fh:
                json.dump(inbox, fh, indent=1, ensure_ascii=False)
            return self._json({"ok": True, "inbox": inbox})
        if self.path.startswith("/api/refresh"):
            refresh_live(force=True)
            return self._json(merged_state())
        if self.path.startswith("/api/reply"):
            n = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(n) or b"{}")
            if self.path.startswith("/api/reply-read"):
                with REPLY_LOCK:
                    items = load("replies.json", [])
                    for x in items:
                        if body.get("all") or x.get("id") == body.get("id"):
                            x["read"] = not body.get("unread")
                    with open(os.path.join(DATA, "replies.json"), "w") as fh:
                        json.dump(items, fh, indent=1, ensure_ascii=False)
                return self._json({"ok": True})
            if not str(body.get("subject") or body.get("snippet") or "").strip():
                return self._json({"ok": False, "error": "subject or snippet needed"})
            return self._json({"ok": add_reply(body, ping=not body.get("quiet"))})
        if self.path.startswith("/api/notify"):
            n = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(n) or b"{}")
            if "topic" in body:
                topic = re.sub(r"[^A-Za-z0-9_-]", "", str(body["topic"]))[:64]
                cfg = load("config.json", {})
                cfg["ntfy_topic"] = topic
                with open(os.path.join(HERE, "config.json"), "w") as fh:
                    json.dump(cfg, fh, indent=2)
            if body.get("gmail_remove"):
                boxes = load("gmail_tokens.json", {})
                boxes.pop(body["gmail_remove"], None)
                _secret_write(GM_TOKENS, boxes)
                bump()
            sent = notify("Creator Core test", "Reply alerts are working.") if body.get("test") else None
            return self._json({"ok": True, "phone": sent})
        if self.path.startswith("/api/google-client"):
            n = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(n) or b"{}")
            if body.get("remove"):
                for f in (G_TOKENS, os.path.join(DATA, "yt_analytics.json")):
                    try:
                        os.remove(f)
                    except OSError:
                        pass
                bump()
                return self._json({"ok": True})
            cid, sec = str(body.get("client_id", "")).strip(), str(body.get("client_secret", "")).strip()
            if not cid.endswith(".apps.googleusercontent.com"):
                return self._json({"ok": False, "error": "Client ID should end in .apps.googleusercontent.com"})
            _secret_write(G_CLIENT, {"client_id": cid, "client_secret": sec})
            bump()
            return self._json({"ok": True})
        if self.path.startswith("/api/buffer-key"):
            n = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(n) or b"{}")
            key = str(body.get("key", "")).strip()
            keys = buffer_keys()
            if body.get("remove"):
                keys.pop(str(body["remove"]), None) if body["remove"] is not True else keys.clear()
                try:
                    os.remove(BUFFER_KEY)
                except OSError:
                    pass
                _secret_write(BUFFER_KEYS, keys)
                LAST["buffer"] = 0
                threading.Thread(target=refresh_live, daemon=True).start()
                return self._json({"ok": True})
            if not re.fullmatch(r"[\w.\-:=+/]{12,400}", key):
                return self._json({"ok": False, "error": "That doesn't look like a Buffer API key."})
            try:
                gql(key, "query { account { organizations { id } } }")
            except Exception as e:
                return self._json({"ok": False, "error": f"Buffer said: {e}"})
            if key in keys.values():
                return self._json({"ok": False, "error": "That Buffer is already connected."})
            label = re.sub(r"[^\w #.-]", "", str(body.get("label", "")))[:24].strip() or f"Buffer {len(keys) + 1}"
            keys[label] = key
            try:
                os.remove(BUFFER_KEY)  # legacy single-key file, now folded into buffer_keys.json
            except OSError:
                pass
            _secret_write(BUFFER_KEYS, keys)
            LAST["buffer"] = 0
            threading.Thread(target=refresh_live, daemon=True).start()
            return self._json({"ok": True})
        self.send_error(404)


def main():
    cfg = load("config.json", {})
    port = int(os.environ.get("PORT", cfg.get("port", 8787)))
    os.makedirs(DATA, exist_ok=True)
    srv = None
    for p in range(port, port + 10):
        try:
            srv = ThreadingHTTPServer(("127.0.0.1", p), Handler)
            port = p
            break
        except OSError:
            continue
    threading.Thread(target=loop, daemon=True).start()
    threading.Thread(target=watch_files, daemon=True).start()
    threading.Thread(target=gmail_loop, daemon=True).start()
    url = f"http://localhost:{port}"
    print(f"\n  CREATOR HUD online  ->  {url}\n  (leave this window open; Ctrl+C to stop)\n")
    if "--no-open" not in sys.argv:
        threading.Timer(1.0, lambda: webbrowser.open(url)).start()
    srv.serve_forever()


if __name__ == "__main__":
    main()
