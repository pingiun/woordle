// Jellespelletjes account integration: SSO callback handling and verified
// result submission to api.jellespelletjes.nl. Playing stays fully anonymous
// without a token; login happens via jellespelletjes.nl (link in settings).
//
// Local development overrides:
//   localStorage["jsp:api-base"] = "http://127.0.0.1:8931"

const API = () => localStorage.getItem("jsp:api-base") || "https://api.jellespelletjes.nl";
const TOKEN_KEY = "jsp:auth-token";
const EMAIL_KEY = "jsp:auth-email";
const QUEUE_KEY = "jsp:sync-queue";
const IMPORTED_PREFIX = "jsp:stats-imported:";

async function api(method, path, body) {
  const token = localStorage.getItem(TOKEN_KEY);
  const response = await fetch(API() + path, {
    method,
    headers: {
      ...(body !== undefined ? { "content-type": "application/json" } : {}),
      ...(token ? { authorization: "Bearer " + token } : {}),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  return response;
}

// Consume the SSO code on /auth/callback (any variant page can handle it,
// the token is shared origin-wide).
export async function handleAuthCallback() {
  if (window.location.pathname !== "/auth/callback") return false;
  const code = new URLSearchParams(window.location.hash.slice(1)).get("code");
  window.history.replaceState(null, "", "/");
  if (!code) return false;
  const response = await fetch(API() + "/auth/sso-code/consume", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ code }),
  });
  if (!response.ok) return false;
  const data = await response.json();
  localStorage.setItem(TOKEN_KEY, data.token);
  localStorage.setItem(EMAIL_KEY, data.user.email);
  return true;
}

function readQueue() {
  try {
    return JSON.parse(localStorage.getItem(QUEUE_KEY) || "[]");
  } catch {
    return [];
  }
}

async function tryDeliver(item) {
  try {
    const response = await api("PUT", `/results/${item.game}/${item.day}`, item.submission);
    // 4xx is terminal: the same payload will never be accepted later.
    return response.ok || (response.status >= 400 && response.status < 500);
  } catch {
    return false;
  }
}

export async function flushQueue() {
  if (!localStorage.getItem(TOKEN_KEY)) return;
  const queue = readQueue();
  if (queue.length === 0) return;
  const remaining = [];
  for (const item of queue) {
    if (!(await tryDeliver(item))) remaining.push(item);
  }
  localStorage.setItem(QUEUE_KEY, JSON.stringify(remaining));
}

async function importStatsOnce(game, suffix) {
  if (localStorage.getItem(IMPORTED_PREFIX + game)) return;
  let stats = null;
  try {
    stats = JSON.parse(localStorage.getItem("statistics" + suffix));
  } catch {
    // ignore
  }
  if (!stats || !stats.gamesPlayed) {
    localStorage.setItem(IMPORTED_PREFIX + game, "1");
    return;
  }
  try {
    const response = await api("POST", "/import/" + game, stats);
    if (response.ok || response.status === 409) {
      localStorage.setItem(IMPORTED_PREFIX + game, "1");
    }
  } catch {
    // retried next visit
  }
}

/**
 * Wire account sync into an Elm app instance.
 * `game`: API game id (woordle | woordle6 | wordle | wordle6)
 * `suffix`: localStorage suffix for this variant ("", "6", "-en", "6-en")
 * `offset`: today's day offset as computed by the page
 */
export function setupAccount(app, { game, suffix, offset }) {
  handleAuthCallback().then(() => {
    if (!localStorage.getItem(TOKEN_KEY)) return;
    flushQueue();
    importStatsOnce(game, suffix);
  });

  // finishEvent fires when a game ends; the authoritative state is what the
  // save port just wrote to localStorage.
  app.ports.finishEvent.subscribe(function () {
    if (!localStorage.getItem(TOKEN_KEY)) return;
    let state = null;
    try {
      state = JSON.parse(localStorage.getItem("gameState" + suffix));
    } catch {
      return;
    }
    if (!state || (state.gameStatus !== "WIN" && state.gameStatus !== "FAIL")) return;
    const submission = {
      guesses: (state.boardState || []).filter((row) => row && row.length > 0),
      won: state.gameStatus === "WIN",
    };
    const item = { game, day: offset, submission };
    tryDeliver(item).then((delivered) => {
      if (!delivered) {
        const queue = readQueue().filter((q) => !(q.game === game && q.day === offset));
        queue.push(item);
        localStorage.setItem(QUEUE_KEY, JSON.stringify(queue));
      }
    });
  });
}
