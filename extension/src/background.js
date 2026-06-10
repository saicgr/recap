// Recap browser extension — background service worker.
//
// Responsibilities:
//   1. Capture audio from the active tab via chrome.tabCapture.
//   2. Buffer 5-second chunks; post them via WebSocket to the user's desktop
//      Recap install at ws://localhost:7474 (configurable).
//   3. Fall back to writing .wav files to chrome.storage.local if the
//      desktop app isn't reachable; sync them when the user pairs.
//   4. Surface a side-panel UI for live captions (rendered via a small
//      Whisper-tiny WASM build).
//
// Privacy: this script makes ZERO network calls to anything outside
// localhost or a user-explicit destination. No analytics. No telemetry. The
// manifest's host_permissions are scoped to the meeting hosts (Meet/Zoom/
// Teams) so we can show context-aware "Record this meeting?" prompts —
// nothing is sent to those hosts.

const DESKTOP_WS_URL_KEY = 'desktopWsUrl';
const DEFAULT_WS_URL = 'ws://localhost:7474/recap';

let activeStream = null;
let activeTabId = null;
let activeRecorder = null;
let chunkBuffer = [];
let wsClient = null;
let connectAttempt = 0;

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  switch (msg?.type) {
    case 'start_recording':
      startRecording(msg.tabId ?? sender.tab?.id)
        .then(() => sendResponse({ ok: true }))
        .catch((e) => sendResponse({ ok: false, error: String(e) }));
      return true;
    case 'stop_recording':
      stopRecording()
        .then(() => sendResponse({ ok: true }))
        .catch((e) => sendResponse({ ok: false, error: String(e) }));
      return true;
    case 'recording_status':
      sendResponse({ recording: !!activeRecorder, tabId: activeTabId });
      return;
    default:
      return;
  }
});

async function startRecording(tabId) {
  if (!tabId) throw new Error('No tabId');
  if (activeRecorder) throw new Error('Already recording');

  const stream = await new Promise((resolve, reject) => {
    chrome.tabCapture.capture(
      { audio: true, video: false },
      (s) => {
        if (chrome.runtime.lastError || !s) {
          reject(new Error(
            chrome.runtime.lastError?.message ||
            'tabCapture returned null (DRM-protected, or no audio?)'
          ));
          return;
        }
        resolve(s);
      }
    );
  });

  activeStream = stream;
  activeTabId = tabId;

  // MediaRecorder → 5s WebM/Opus chunks. Desktop Recap takes care of
  // demuxing + transcoding to 16 kHz mono WAV for Whisper.
  const mimeType = MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
    ? 'audio/webm;codecs=opus'
    : 'audio/webm';
  const rec = new MediaRecorder(stream, { mimeType, audioBitsPerSecond: 64_000 });
  rec.ondataavailable = (e) => {
    if (e.data && e.data.size > 0) {
      chunkBuffer.push(e.data);
      flushChunk(e.data);
    }
  };
  rec.onerror = (e) => console.error('Recap recorder error', e);
  rec.start(5000);
  activeRecorder = rec;

  await ensureWebSocket();
  chrome.action.setBadgeText({ text: 'REC' });
  chrome.action.setBadgeBackgroundColor({ color: '#ef4444' });
  chrome.notifications?.create('recap-recording', {
    type: 'basic',
    iconUrl: 'icons/icon-128.png',
    title: 'Recap',
    message: 'Recording the active tab — captions appear in the side panel.',
    priority: 1,
  });
}

async function stopRecording() {
  if (!activeRecorder) return;
  activeRecorder.stop();
  activeStream?.getTracks().forEach((t) => t.stop());
  activeRecorder = null;
  activeStream = null;
  activeTabId = null;
  chrome.action.setBadgeText({ text: '' });
  if (wsClient && wsClient.readyState === WebSocket.OPEN) {
    wsClient.send(JSON.stringify({ type: 'end' }));
  }
}

async function flushChunk(blob) {
  // Try WebSocket first; fall back to chrome.storage.local.
  if (wsClient && wsClient.readyState === WebSocket.OPEN) {
    const buf = await blob.arrayBuffer();
    wsClient.send(buf);
    return;
  }
  // Fallback: buffer in chrome.storage.local. The user can later pair with
  // desktop to drain the buffer.
  const id = `chunk_${Date.now()}_${Math.random().toString(36).slice(2)}`;
  const data = await blob.arrayBuffer().then((b) => Array.from(new Uint8Array(b)));
  await chrome.storage.local.set({ [id]: { ts: Date.now(), data } });
}

async function ensureWebSocket() {
  const url = await getWsUrl();
  if (wsClient && (wsClient.readyState === WebSocket.OPEN ||
                   wsClient.readyState === WebSocket.CONNECTING)) {
    return;
  }
  try {
    wsClient = new WebSocket(url);
    wsClient.binaryType = 'arraybuffer';
    wsClient.onopen = () => {
      connectAttempt = 0;
      wsClient.send(JSON.stringify({
        type: 'hello',
        client: 'recap-extension',
        version: '0.1.0',
      }));
    };
    wsClient.onclose = () => {
      wsClient = null;
      // Back off retry: 1s, 2s, 4s, 8s, then every 30s.
      const delay = Math.min(30_000, 1000 * Math.pow(2, connectAttempt));
      connectAttempt += 1;
      setTimeout(() => activeRecorder && ensureWebSocket(), delay);
    };
    wsClient.onmessage = (ev) => {
      // Desktop sends back live caption text; relay to side panel.
      try {
        const msg = JSON.parse(ev.data);
        chrome.runtime.sendMessage({ type: 'caption', ...msg });
      } catch (_) {/* ignore non-JSON */}
    };
    wsClient.onerror = () => {/* onclose will handle reconnect */};
  } catch (e) {
    console.warn('Recap: WS init failed', e);
    wsClient = null;
  }
}

async function getWsUrl() {
  const stored = await chrome.storage.local.get(DESKTOP_WS_URL_KEY);
  return stored[DESKTOP_WS_URL_KEY] || DEFAULT_WS_URL;
}

// On install, open the side panel automatically when the user clicks the icon.
chrome.runtime.onInstalled.addListener(() => {
  chrome.sidePanel?.setPanelBehavior?.({ openPanelOnActionClick: true });
});
