import searchIndex from "./search-index.js";

export class Search {
  constructor(inputEl, outputEl, resultRenderer) {
    Object.assign(this, { inputEl, outputEl, resultRenderer });

    this.inputEl.addEventListener("input", event => this.search());
    this.inputEl.addEventListener("focusin", event => this.handleFocusIn(event));
    this.inputEl.addEventListener("focusout", event => this.handleFocusOut(event));
    this.outputEl.addEventListener("focusout", event => this.handleFocusOut(event));
    document.addEventListener("keydown", event => this.handleKey(event));

    // TODO add tabindex to outputEl
  }

  search() {
    const bitPositions = this.compileQuery(this.inputEl.value);
    let worst;
    this.clearResults();

    for (const entry of searchIndex.entries) {
      const score = this.computeScore(bitPositions, entry[0], entry[1]);
      worst ??= this.worstResult;
      if (score > worst.score) {
        worst.score = score;
        worst.entry = entry;
        worst = null;
      }
    }

    this.renderResults();
  }

  compileQuery(query) {
    const bitPositions = [];

    for (let i = 0, len = query.length; i < len; i += 1) {
      const bigram = i === 0 ? (" " + query[0]) : query.substring(i - 1, i + 1);
      const position = searchIndex.bigrams[bigram];
      if (position) {
        bitPositions.push(position);
      }
    }

    return bitPositions;
  }

  computeScore(bitPositions, bytes, tiebreakerBonus) {
    let score = 0;

    for (let i = 0, len = bitPositions.length; i < len; i += 1) {
      const position = bitPositions[i] | 0;
      const byte = bytes[position / 8 | 0] | 0;
      const mask = 1 << (position % 8) | 0;

      if (byte & mask) {
        score += searchIndex.weights[position] + tiebreakerBonus;
      }
    }

    return score;
  }

  static maxResults = 20;
  results = Array(Search.maxResults).fill().map(() => ({}));

  clearResults() {
    for (const result of this.results) {
      result.score = 0;
      result.entry = null;
    }
  }

  get worstResult() {
    return this.results.reduce((worst, result) => result.score < worst.score ? result : worst);
  }

  renderResults() {
    this.results.sort((a, b) => b.score - a.score);

    let html = "";

    for (const { score, entry } of this.results) {
      if (score > 0) {
        html += this.resultRenderer(entry[2], entry[3], entry[4], entry[5], score);
      }
    }

    this.outputEl.innerHTML = html;
    this.cursorEl = this.outputEl.firstElementChild;
  }

  feelingLucky(query) {
    this.inputEl.value = query;
    this.search();
    this.clickCursor();
  }

  focus() {
    this.inputEl.focus();
  }

  blur() {
    this.inputEl.blur();
  }

  get active() {
    return this.inputEl.classList.contains("active");
  }

  set active(value) {
    this.inputEl.classList.toggle("active", value);
    this.outputEl.classList.toggle("active", value);
  }

  get cursorEl() {
    return this._cursorEl;
  }

  set cursorEl(el) {
    this._cursorEl?.classList?.remove("cursor");
    el?.classList?.add("cursor");
    el?.scrollIntoView({ block: "nearest" });
    this._cursorEl = el;
  }

  incrementCursor() {
    if (this.cursorEl?.nextElementSibling) {
      this.cursorEl = this.cursorEl.nextElementSibling;
    }
  }

  decrementCursor() {
    if (this.cursorEl?.previousElementSibling) {
      this.cursorEl = this.cursorEl.previousElementSibling;
    }
  }

  clickCursor() {
    this.active = false;
    this.cursorEl?.querySelector("a[href]")?.click();
  }

  handleFocusIn() {
    this.active = true;
  }

  handleFocusOut({ relatedTarget }) {
    this.active = this.inputEl === relatedTarget || this.outputEl.contains(relatedTarget);
  }

  static activeKeyMap = {
    "ArrowDown": "incrementCursor",
    "ArrowUp": "decrementCursor",
    "Enter": "clickCursor",
    "Escape": "blur"
  };

  static idleKeyMap = {
    "/": "focus"
  };

  handleKey(event) {
    const handler = (this.active ? Search.activeKeyMap : Search.idleKeyMap)[event.key];
    if (handler) {
      this[handler]();
      event.preventDefault();
    }
  }
}
