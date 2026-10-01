'use strict';

/**
 * Marketing site for Brick & Brew.
 * Scoring matches BrickAndBrew/Models/Scoring.swift so the demo board
 * uses the same Total Index the iPhone app computes.
 */
const WEIGHTS = Object.freeze({
  swim: 26,
  run: 4,
  ride: 1,
  scoredPint: 12,
});

const CREW = Object.freeze([
  { id: 'nico', name: 'Nico', swimKm: 9.6, rideKm: 224, runKm: 36.2, scoredPint: true },
  { id: 'mara', name: 'Mara', swimKm: 14.1, rideKm: 168, runKm: 29, scoredPint: true },
  { id: 'you', name: 'You', swimKm: 6.4, rideKm: 191, runKm: 33.8, scoredPint: false, isYou: true },
  { id: 'jules', name: 'Jules', swimKm: 3.2, rideKm: 156, runKm: 22, scoredPint: true },
  { id: 'rafa', name: 'Rafa', swimKm: 5, rideKm: 88, runKm: 18, scoredPint: false },
]);

const BOARDS = Object.freeze(['overall', 'swim', 'ride', 'run']);

let activeBoard = 'overall';

function pointsFor(entry) {
  return {
    swim: entry.swimKm * WEIGHTS.swim,
    ride: entry.rideKm * WEIGHTS.ride,
    run: entry.runKm * WEIGHTS.run,
  };
}

function trainingLoad(entry) {
  const pts = pointsFor(entry);
  return pts.swim + pts.ride + pts.run;
}

function pintBonus(entry) {
  if (!entry.scoredPint || trainingLoad(entry) <= 0) {
    return 0;
  }
  return WEIGHTS.scoredPint;
}

function totalIndex(entry) {
  return trainingLoad(entry) + pintBonus(entry);
}

function boardPoints(entry, board) {
  if (board === 'overall') {
    return totalIndex(entry);
  }
  return pointsFor(entry)[board];
}

function formatPoints(value) {
  if (Number.isInteger(value)) {
    return `${value} pts`;
  }
  return `${value.toFixed(1)} pts`;
}

function formatKilometers(km) {
  return `${km.toFixed(1)} km`;
}

function boardDetail(entry, board) {
  switch (board) {
    case 'swim':
      return formatKilometers(entry.swimKm);
    case 'ride':
      return formatKilometers(entry.rideKm);
    case 'run':
      return formatKilometers(entry.runKm);
    default:
      return formatPoints(totalIndex(entry));
  }
}

function rankedCrew(board) {
  return CREW.slice().sort((left, right) => {
    const delta = boardPoints(right, board) - boardPoints(left, board);
    if (delta !== 0) {
      return delta;
    }
    return left.name.localeCompare(right.name);
  });
}

function renderRankList(target, board, compact) {
  if (!target) {
    return;
  }

  const ranked = rankedCrew(board);
  target.replaceChildren();

  ranked.forEach((entry, index) => {
    const rank = index + 1;
    const row = document.createElement('article');
    row.className = 'rank-row';
    if (entry.isYou) {
      row.classList.add('is-you');
    }
    if (rank === 1) {
      row.classList.add('is-lead');
    }
    row.setAttribute('aria-label', `Rank ${rank}, ${entry.name}, ${boardDetail(entry, board)}`);

    const rankEl = document.createElement('span');
    rankEl.className = 'rank-num';
    rankEl.textContent = String(rank);

    const meta = document.createElement('div');
    meta.className = 'rank-meta';

    const nameEl = document.createElement('strong');
    nameEl.className = 'rank-name';
    nameEl.textContent = entry.name;

    const detailEl = document.createElement('span');
    detailEl.className = 'rank-detail';
    detailEl.textContent = compact
      ? boardDetail(entry, board)
      : `${boardDetail(entry, 'swim')} swim · ${boardDetail(entry, 'ride')} bike · ${boardDetail(entry, 'run')} run`;

    meta.append(nameEl, detailEl);

    const pts = document.createElement('span');
    pts.className = 'rank-pts';
    pts.textContent = formatPoints(boardPoints(entry, board));

    row.append(rankEl, meta, pts);
    target.append(row);
  });
}

function setActiveBoard(board) {
  if (!BOARDS.includes(board)) {
    return;
  }
  activeBoard = board;

  document.querySelectorAll('[data-board]').forEach((button) => {
    const isActive = button.getAttribute('data-board') === board;
    button.classList.toggle('is-active', isActive);
    button.setAttribute('aria-pressed', isActive ? 'true' : 'false');
  });

  renderRankList(document.getElementById('hero-board'), board, true);
  renderRankList(document.getElementById('crew-board'), board, false);
}

function handleBoardClick(event) {
  const button = event.currentTarget;
  const board = button.getAttribute('data-board');
  setActiveBoard(board);
}

function calculatorState() {
  const swimInput = document.getElementById('swim-km');
  const rideInput = document.getElementById('ride-km');
  const runInput = document.getElementById('run-km');
  const pintInput = document.getElementById('scored-pint');
  if (!swimInput || !rideInput || !runInput || !pintInput) {
    return null;
  }
  return {
    swimKm: Number(swimInput.value),
    rideKm: Number(rideInput.value),
    runKm: Number(runInput.value),
    scoredPint: pintInput.checked,
  };
}

function updateCalculator() {
  const state = calculatorState();
  if (!state) {
    return;
  }
  const pts = pointsFor(state);
  const bonus = pintBonus(state);
  const total = totalIndex(state);

  setText('swim-km-value', formatKilometers(state.swimKm));
  setText('ride-km-value', formatKilometers(state.rideKm));
  setText('run-km-value', formatKilometers(state.runKm));

  setText('receipt-swim', formatPoints(pts.swim));
  setText('receipt-ride', formatPoints(pts.ride));
  setText('receipt-run', formatPoints(pts.run));
  setText('receipt-beer', formatPoints(bonus));
  setText('receipt-total', formatPoints(total));
  setText('index-hero', total.toFixed(total % 1 === 0 ? 0 : 1));
}

function setText(id, value) {
  const node = document.getElementById(id);
  if (node) {
    node.textContent = value;
  }
}

function handleRangeInput() {
  updateCalculator();
}

function syncHeader() {
  const header = document.querySelector('.site-header');
  if (!header) {
    return;
  }
  header.classList.toggle('is-scrolled', window.scrollY > 12);
}

function closeMobileNav() {
  const toggle = document.getElementById('nav-toggle');
  if (toggle) {
    toggle.checked = false;
  }
}

function handleNavLinkClick() {
  closeMobileNav();
}

function initYear() {
  setText('year', String(new Date().getFullYear()));
}

function prefersReducedMotion() {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

// Reveals stay visible without JS; motion only runs when the observer can unobserve.

function isInViewport(node) {
  const rect = node.getBoundingClientRect();
  return rect.bottom > 0 && rect.top < window.innerHeight;
}

function revealNode(node) {
  node.classList.add('is-in');
}

function initReveals() {
  const nodes = document.querySelectorAll('[data-reveal]');
  if (!nodes.length) {
    return;
  }
  if (prefersReducedMotion()) {
    nodes.forEach(revealNode);
    return;
  }

  // Hash jumps (#formula, #how) can land on a section before the observer fires.
  // Reveal anything already on screen so content is never left blank.
  nodes.forEach((node) => {
    if (isInViewport(node)) {
      revealNode(node);
    }
  });

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        revealNode(entry.target);
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.01, rootMargin: '0px 0px -4% 0px' });

  nodes.forEach((node) => {
    if (!node.classList.contains('is-in')) {
      observer.observe(node);
    }
  });

  window.addEventListener('hashchange', () => {
    document.querySelectorAll('[data-reveal]:not(.is-in)').forEach((node) => {
      if (isInViewport(node)) {
        revealNode(node);
      }
    });
  });
}

let parallaxFrame = 0;

function syncParallax() {
  if (prefersReducedMotion()) {
    return;
  }
  document.querySelectorAll('[data-parallax]').forEach((el) => {
    const rect = el.getBoundingClientRect();
    const viewH = window.innerHeight;
    if (rect.bottom < 0 || rect.top > viewH) {
      return;
    }
    const progress = (viewH - rect.top) / (viewH + rect.height);
    const shift = (progress - 0.5) * 36;
    el.style.transform = `translate3d(0, ${shift}px, 0) scale(1.08)`;
  });
}

function requestParallax() {
  if (parallaxFrame) {
    return;
  }
  parallaxFrame = window.requestAnimationFrame(() => {
    parallaxFrame = 0;
    syncParallax();
  });
}

function init() {
  document.querySelectorAll('[data-board]').forEach((button) => {
    button.addEventListener('click', handleBoardClick);
  });

  if (calculatorState()) {
    document.querySelectorAll('.calc-range').forEach((input) => {
      input.addEventListener('input', handleRangeInput);
    });
    const pintInput = document.getElementById('scored-pint');
    if (pintInput) {
      pintInput.addEventListener('change', handleRangeInput);
    }
  }

  document.querySelectorAll('.nav-links a').forEach((link) => {
    link.addEventListener('click', handleNavLinkClick);
  });

  window.addEventListener('scroll', syncHeader, { passive: true });
  window.addEventListener('scroll', requestParallax, { passive: true });
  window.addEventListener('resize', requestParallax);

  initYear();
  setActiveBoard('overall');
  updateCalculator();
  syncHeader();
  initReveals();
  syncParallax();
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
