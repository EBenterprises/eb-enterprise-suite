/*
 * Request Runner® — Registered Symbol Normalizer
 *
 * Converts a standalone ® into a visually smaller superscript symbol
 * without changing the underlying legal text.
 */

(function () {
  "use strict";

  function normalizeRegisteredSymbols(root) {
    const scope = root || document;

    const walker = document.createTreeWalker(
      scope,
      NodeFilter.SHOW_TEXT
    );

    const nodes = [];

    while (walker.nextNode()) {
      const node = walker.currentNode;

      if (
        node.parentElement &&
        !node.parentElement.closest(
          "script,style,textarea,input,[data-ip-normalized]"
        ) &&
        node.nodeValue &&
        node.nodeValue.includes("®")
      ) {
        nodes.push(node);
      }
    }

    for (const node of nodes) {
      const parts = node.nodeValue.split("®");

      if (parts.length < 2) continue;

      const fragment = document.createDocumentFragment();

      parts.forEach((part, index) => {
        if (part) {
          fragment.appendChild(document.createTextNode(part));
        }

        if (index < parts.length - 1) {
          const symbol = document.createElement("sup");
          symbol.className = "ip-symbol";
          symbol.textContent = "®";
          symbol.setAttribute("aria-label", "registered trademark symbol");
          fragment.appendChild(symbol);
        }
      });

      const parent = node.parentNode;

      if (parent) {
        parent.replaceChild(fragment, node);
      }
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener(
      "DOMContentLoaded",
      () => normalizeRegisteredSymbols()
    );
  } else {
    normalizeRegisteredSymbols();
  }

  window.RequestRunnerIP = Object.freeze({
    normalizeRegisteredSymbols
  });
})();
