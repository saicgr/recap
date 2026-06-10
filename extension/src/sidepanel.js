// Live captions side panel — receives 'caption' messages relayed by
// background.js from the desktop Recap install (via WebSocket).

const $captions = document.getElementById('captions');
const $empty = document.getElementById('empty');

function fmtTs(ms) {
  const total = Math.floor(ms / 1000);
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  const pad = (n) => n.toString().padStart(2, '0');
  return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`;
}

chrome.runtime.onMessage.addListener((msg) => {
  if (msg?.type !== 'caption') return;
  if ($empty) $empty.style.display = 'none';
  const div = document.createElement('div');
  div.className = 'caption';
  const ts = document.createElement('div');
  ts.className = 'ts';
  ts.textContent = `${fmtTs(msg.startMs || 0)} — ${fmtTs(msg.endMs || 0)}`;
  const text = document.createElement('div');
  text.textContent = msg.text || '';
  div.appendChild(ts);
  div.appendChild(text);
  $captions.appendChild(div);
  div.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
});
