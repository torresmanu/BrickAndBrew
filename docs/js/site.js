'use strict';

/**
 * Marketing site for Brick & Brew.
 * Scoring matches BrickAndBrew/Models/Scoring.swift so the demo board
 * uses the same Total Index the iPhone app computes.
 */
const WEIGHTS = Object.freeze({
  swim: 10,
  run: 3,
  ride: 1,
  beer: 12,
  coveragePerBeer: 20,
  uncoveredPenaltyRate: 0.25,
});

const CREW = Object.freeze([
  { id: 'nico', name: 'Nico', swimKm: 9.6, rideKm: 224, runKm: 36.2, beers: 11 },
  { id: 'mara', name: 'Mara', swimKm: 14.1, rideKm: 168, runKm: 29, beers: 8 },
  { id: 'you', name: 'You', swimKm: 6.4, rideKm: 191, runKm: 33.8, beers: 16, isYou: true },
  { id: 'jules', name: 'Jules', swimKm: 3.2, rideKm: 156, runKm: 22, beers: 28 },
  { id: 'rafa', name: 'Rafa', swimKm: 5, rideKm: 88, runKm: 18, beers: 4 },
]);

const BOARDS = Object.freeze(['overall', 'swim', 'ride', 'run', 'beers']);

let activeBoard = 'overall';
let beerCount = 4;

function pointsFor(entry) {
  return {
    swim: entry.swimKm * WEIGHTS.swim,
    ride: entry.rideKm * WEIGHTS.ride,
    run: entry.runKm * WEIGHTS.run,
    beers: entry.beers * WEIGHTS.beer,
  };
}

function trainingLoad(entry) {
  const pts = pointsFor(entry);
  return pts.swim + pts.ride + pts.run;
}

function grindTax(entry) {
  const covered = Math.max(0, entry.beers) * WEIGHTS.coveragePerBeer;
  const uncovered = Math.max(0, trainingLoad(entry) - covered);
  return uncovered * (1 + WEIGHTS.uncoveredPenaltyRate);
}

function totalIndex(entry) {
  const pts = pointsFor(entry);
  return pts.swim + pts.ride + pts.run + pts.beers - grindTax(entry);
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

function formatTax(value) {
  if (value <= 0) {
    return formatPoints(0);
  }
  return `−${formatPoints(value)}`;
}

function formatKilometers(km) {
  return `${km.toFixed(1)} km`;
}

function formatBeers(count) {
  return count === 1 ? '1 beer' : `${count} beers`;
}

function boardDetail(entry, board) {
  switch (board) {
    case 'swim':
      return formatKilometers(entry.swimKm);
    case 'ride':
      return formatKilometers(entry.rideKm);
    case 'run':
      return formatKilometers(entry.runKm);
    case 'beers':
      return formatBeers(entry.beers);
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
    detailEl.textContent = compact ? boardDetail(entry, board) : `${boardDetail(entry, 'swim')} swim · ${boardDetail(entry, 'ride')} bike · ${boardDetail(entry, 'run')} run · ${formatBeers(entry.beers)}`;

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
  if (!swimInput || !rideInput || !runInput) {
    return null;
  }
  return {
    swimKm: Number(swimInput.value),
    rideKm: Number(rideInput.value),
    runKm: Number(runInput.value),
    beers: beerCount,
  };
}

function updateCalculator() {
  const state = calculatorState();
  if (!state) {
    return;
  }
  const pts = pointsFor(state);
  const tax = grindTax(state);
  const total = totalIndex(state);

  setText('swim-km-value', formatKilometers(state.swimKm));
  setText('ride-km-value', formatKilometers(state.rideKm));
  setText('run-km-value', formatKilometers(state.runKm));
  setText('beer-count-value', String(state.beers));

  setText('receipt-swim', formatPoints(pts.swim));
  setText('receipt-ride', formatPoints(pts.ride));
  setText('receipt-run', formatPoints(pts.run));
  setText('receipt-beer', formatPoints(pts.beers));
  setText('receipt-tax', formatTax(tax));
  setText('receipt-total', formatPoints(total));
  setText('index-hero', total.toFixed(total % 1 === 0 ? 0 : 1));

  const taxRow = document.querySelector('.receipt .tax');
  if (taxRow) {
    taxRow.classList.toggle('is-active', tax > 0);
  }
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

function incrementBeers() {
  beerCount = Math.min(40, beerCount + 1);
  updateCalculator();
}

function decrementBeers() {
  beerCount = Math.max(0, beerCount - 1);
  updateCalculator();
}

function handleKeyBeer(event) {
  if (event.key === 'ArrowUp') {
    event.preventDefault();
    incrementBeers();
  }
  if (event.key === 'ArrowDown') {
    event.preventDefault();
    decrementBeers();
  }
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

function init() {
  document.querySelectorAll('[data-board]').forEach((button) => {
    button.addEventListener('click', handleBoardClick);
  });

  if (calculatorState()) {
    document.querySelectorAll('.calc-range').forEach((input) => {
      input.addEventListener('input', handleRangeInput);
    });
  }

  const plus = document.getElementById('beer-plus');
  const minus = document.getElementById('beer-minus');
  const beerControl = document.getElementById('beer-stepper');
  if (plus) {
    plus.addEventListener('click', incrementBeers);
  }
  if (minus) {
    minus.addEventListener('click', decrementBeers);
  }
  if (beerControl) {
    beerControl.addEventListener('keydown', handleKeyBeer);
  }

  document.querySelectorAll('.nav-links a').forEach((link) => {
    link.addEventListener('click', handleNavLinkClick);
  });

  window.addEventListener('scroll', syncHeader, { passive: true });

  initYear();
  setActiveBoard('overall');
  updateCalculator();
  syncHeader();
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
