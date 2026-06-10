// Recap extension popup. Talks to the background service worker via
// chrome.runtime messages. Keeps no state of its own beyond reading the
// status when the popup opens.

const $status = document.getElementById('status');
const $toggle = document.getElementById('toggle');
const $openSidePanel = document.getElementById('openSidePanel');
const $openSettings = document.getElementById('openSettings');

async function refreshStatus() {
  const res = await chrome.runtime.sendMessage({ type: 'recording_status' });
  if (res?.recording) {
    $status.textContent = 'Recording…';
    $status.classList.add('live');
    $toggle.textContent = 'Stop';
    $toggle.classList.remove('primary');
    $toggle.classList.add('danger');
  } else {
    $status.textContent = 'Not recording';
    $status.classList.remove('live');
    $toggle.textContent = 'Record this tab';
    $toggle.classList.remove('danger');
    $toggle.classList.add('primary');
  }
}

$toggle.addEventListener('click', async () => {
  $toggle.disabled = true;
  try {
    const status = await chrome.runtime.sendMessage({ type: 'recording_status' });
    if (status?.recording) {
      await chrome.runtime.sendMessage({ type: 'stop_recording' });
    } else {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      const res = await chrome.runtime.sendMessage({
        type: 'start_recording',
        tabId: tab.id,
      });
      if (!res?.ok) {
        $status.textContent = `Failed: ${res?.error || 'unknown'}`;
      }
    }
  } finally {
    $toggle.disabled = false;
    await refreshStatus();
  }
});

$openSidePanel.addEventListener('click', async () => {
  const win = await chrome.windows.getCurrent();
  await chrome.sidePanel.open({ windowId: win.id });
});

$openSettings.addEventListener('click', () => {
  chrome.runtime.openOptionsPage?.();
});

refreshStatus();
