import searchIndex from "./search-index.js";

export class Search {
  constructor(inputEl, outputEl, resultRenderer) {
    Object.assign(this, { inputEl, outputEl, resultRenderer });

    this.inputEl.addEventListener("input", event => this.search());
    document.addEventListener("keydown", event => this.handleKey(event));
    this.inputEl.addEventListener("focus", event => this.show());
    this.inputEl.addEventListener("blur", event => this.handleBlur());
    this.outputEl.addEventListener("blur", event => this.handleBlur());

    // TODO add tabindex to outputEl
    this.renderResults(); // Render "No results." for initial reveal.
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
        html += this.resultRenderer(entry[2], entry[3], entry[4], entry[5]);
      }
    }

    this.outputEl.innerHTML = html || "No results.";
    this.cursorEl = this.outputEl.firstElementChild;
  }

  feelingLucky(query) {
    this.inputEl.value = query;
    this.search();
    this.clickCursor();
  }

  static focusedKeyMap = {
    "ArrowDown": "incrementCursor",
    "ArrowUp": "decrementCursor",
    "Enter": "clickCursor",
    "Escape": "hide"
  };

  static blurredKeyMap = {
    "/": "show"
  };

  handleKey(event) {
    const handler = (this.focused ? Search.focusedKeyMap : Search.blurredKeyMap)[event.key];
    if (handler) {
      this[handler]();
      event.preventDefault();
    }
  }

  handleBlur() {
    if (!this.focused) {
      this.hide();
    }
  }

  get focused() {
    return document.activeElement === this.inputEl || this.outputEl.contains(document.activeElement);
  }

  show() {
    this.inputEl.focus();
    this.outputEl.hidden = false;
  }

  hide() {
    this.inputEl.blur();
    // this.outputEl.hidden = true;
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
    this.hide();
    this.cursorEl?.querySelector("a[href]")?.click();
  }
}
