'use strict';

/**
 * Marketing-site waitlist. Posts an email to the Cloudflare Worker,
 * then keeps a local flag so a return visit still shows the joined state.
 */
const WAITLIST_STORAGE_KEY = 'brickandbrew.waitlist.joined';
const WAITLIST_TIMEOUT_MS = 12000;

const WAITLIST_COPY = Object.freeze({
  loading: 'Saving your seat…',
  success: "You're on the list. We'll ping you when the next round opens.",
  already: "You're already on the list. We'll ping you when the next round opens.",
  invalid: "That email doesn't look right. Try again.",
  empty: 'Enter an email so we know where to send the invite.',
  timeout: "That took too long. Check your connection and try again.",
  network: "We couldn't reach the waitlist. Check your connection and try again.",
  server: "We couldn't save that just now. Try again in a bit.",
  rate: 'Slow down — try again in a moment.',
});

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function isValidEmail(value) {
  const email = value.trim();
  return email.length > 0 && email.length <= 254 && EMAIL_PATTERN.test(email);
}

function waitlistElements() {
  const form = document.getElementById('waitlist-form');
  if (!form) {
    return null;
  }
  return {
    form,
    email: document.getElementById('waitlist-email'),
    company: document.getElementById('waitlist-company'),
    submit: document.getElementById('waitlist-submit'),
    label: form.querySelector('.btn-label'),
    spinner: form.querySelector('.btn-spinner'),
    status: document.getElementById('waitlist-status'),
    success: document.getElementById('waitlist-success'),
  };
}

function setStatus(nodes, message, kind) {
  if (!nodes.status) {
    return;
  }
  nodes.status.textContent = message;
  nodes.status.classList.remove('is-error', 'is-success', 'is-loading');
  if (kind) {
    nodes.status.classList.add(`is-${kind}`);
  }
}

function setEmailInvalid(nodes, isInvalid) {
  if (!nodes.email) {
    return;
  }
  nodes.email.classList.toggle('is-invalid', isInvalid);
  nodes.email.setAttribute('aria-invalid', isInvalid ? 'true' : 'false');
}

function setLoading(nodes, isLoading) {
  nodes.form.setAttribute('aria-busy', isLoading ? 'true' : 'false');
  if (nodes.submit) {
    nodes.submit.disabled = isLoading;
    nodes.submit.classList.toggle('is-loading', isLoading);
  }
  if (nodes.email) {
    nodes.email.disabled = isLoading;
  }
  if (nodes.spinner) {
    nodes.spinner.hidden = !isLoading;
  }
  if (nodes.label) {
    nodes.label.textContent = isLoading ? 'Joining…' : 'Join the waitlist →';
  }
}

function showJoined(nodes, message) {
  nodes.form.classList.add('is-joined');
  if (nodes.success) {
    nodes.success.hidden = false;
  }
  setStatus(nodes, message, 'success');
  setEmailInvalid(nodes, false);
  setLoading(nodes, false);
}

function persistJoined() {
  try {
    window.localStorage.setItem(WAITLIST_STORAGE_KEY, '1');
  } catch {
    // Private mode can block storage; the server still has the email.
  }
}

function hasJoinedLocally() {
  try {
    return window.localStorage.getItem(WAITLIST_STORAGE_KEY) === '1';
  } catch {
    return false;
  }
}

function waitlistEndpoint(form) {
  return form.getAttribute('action') || '';
}

async function submitWaitlist(nodes) {
  const email = nodes.email ? nodes.email.value : '';
  if (!email.trim()) {
    setEmailInvalid(nodes, true);
    setStatus(nodes, WAITLIST_COPY.empty, 'error');
    return;
  }
  if (!isValidEmail(email)) {
    setEmailInvalid(nodes, true);
    setStatus(nodes, WAITLIST_COPY.invalid, 'error');
    if (nodes.email) {
      nodes.email.focus();
    }
    return;
  }

  const endpoint = waitlistEndpoint(nodes.form);
  if (!endpoint) {
    setStatus(nodes, WAITLIST_COPY.server, 'error');
    return;
  }

  setEmailInvalid(nodes, false);
  setLoading(nodes, true);
  setStatus(nodes, WAITLIST_COPY.loading, 'loading');

  const controller = new AbortController();
  const timer = window.setTimeout(() => controller.abort(), WAITLIST_TIMEOUT_MS);

  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      signal: controller.signal,
      body: JSON.stringify({
        email: email.trim(),
        company: nodes.company ? nodes.company.value : '',
      }),
    });

    let payload = {};
    try {
      payload = await response.json();
    } catch {
      payload = {};
    }

    if (response.status === 429) {
      setStatus(nodes, WAITLIST_COPY.rate, 'error');
      return;
    }

    if (!response.ok) {
      if (response.status === 400) {
        setEmailInvalid(nodes, true);
        setStatus(nodes, WAITLIST_COPY.invalid, 'error');
        return;
      }
      setStatus(nodes, WAITLIST_COPY.server, 'error');
      return;
    }

    persistJoined();
    const copy = payload.alreadyJoined ? WAITLIST_COPY.already : WAITLIST_COPY.success;
    showJoined(nodes, copy);
  } catch (error) {
    const isAbort = error instanceof DOMException && error.name === 'AbortError';
    setStatus(nodes, isAbort ? WAITLIST_COPY.timeout : WAITLIST_COPY.network, 'error');
  } finally {
    window.clearTimeout(timer);
    if (!nodes.form.classList.contains('is-joined')) {
      setLoading(nodes, false);
    }
  }
}

function handleWaitlistSubmit(event) {
  event.preventDefault();
  const nodes = waitlistElements();
  if (!nodes) {
    return;
  }
  submitWaitlist(nodes);
}

function handleEmailInput() {
  const nodes = waitlistElements();
  if (!nodes || !nodes.email) {
    return;
  }
  if (nodes.email.classList.contains('is-invalid') && isValidEmail(nodes.email.value)) {
    setEmailInvalid(nodes, false);
  }
}

function initWaitlist() {
  const nodes = waitlistElements();
  if (!nodes) {
    return;
  }

  nodes.form.addEventListener('submit', handleWaitlistSubmit);
  if (nodes.email) {
    nodes.email.addEventListener('input', handleEmailInput);
  }

  if (hasJoinedLocally()) {
    showJoined(nodes, WAITLIST_COPY.success);
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initWaitlist);
} else {
  initWaitlist();
}
