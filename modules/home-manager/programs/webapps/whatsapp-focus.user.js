// ==UserScript==
// @name         WhatsApp Focus
// @namespace    local.webapps
// @version      2.2
// @description  Hide everything except the open conversation; make the chat list collapsible (toggle button / Ctrl+B).
// @match        https://web.whatsapp.com/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function () {
  'use strict';

  // Idempotent: if injected twice (e.g. two userscript managers) do nothing the
  // second time, so we never end up with duplicate keydown handlers / buttons.
  if (window.__waFocusLoaded) return;
  window.__waFocusLoaded = true;

  const STYLE_ID = 'wa-focus-style';
  const BTN_ID = 'wa-focus-toggle';

  // State lives as a data-attr on <html>, NOT a body class: WhatsApp rewrites
  // body.className on its own re-renders, which was wiping the toggle (list
  // flashing on then snapping back). It does not touch our data-attribute.
  const root = document.documentElement;

  // ponytail: WhatsApp classes are obfuscated; key off the stable layout — the
  // flex row `.two` holds [icon rail <header>][chat-list panel :has(#side)]
  // [conversation pane]. Collapse the first two. Adjust here if a WA update moves things.
  const css = `
    html[data-wa-focus] .two > header { display: none !important; }
    html[data-wa-focus] .two > div:has(#side) { display: none !important; }
    /* Leftover drawer columns that sit beside the chat list. */
    html[data-wa-focus] .two > [data-testid="drawer-fullscreen"] { display: none !important; }
    html[data-wa-focus] .two > div:has([data-testid="drawer-left"]) { display: none !important; }

    /* Once the icon rail + chat-list are hidden, the ancestors of #main keep
       their full-3-column sizing and overflow the small floating window, which
       spawns extra scrollbars. Clip that chain and let the conversation column
       fill; #main keeps its own internal message scroll. */
    html[data-wa-focus] .app-wrapper-web,
    html[data-wa-focus] [data-testid="wa-web-main-screen"],
    html[data-wa-focus] .two,
    html[data-wa-focus] .two > div:has(#main) {
      min-width: 0 !important;
      overflow: hidden !important;
    }
    html[data-wa-focus] .two > div:has(#main) { flex: 1 1 auto !important; }

    #${BTN_ID} {
      position: fixed; top: 6px; left: 6px; z-index: 2147483647;
      width: 30px; height: 30px; border: none; border-radius: 50%;
      background: #2a3942; color: #e9edef; font-size: 15px; line-height: 30px;
      text-align: center; cursor: pointer; opacity: .55;
      box-shadow: 0 1px 4px rgba(0,0,0,.4);
    }
    #${BTN_ID}:hover { opacity: 1; }
  `;

  function addStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const s = document.createElement('style');
    s.id = STYLE_ID;
    s.textContent = css;
    (document.head || document.documentElement).appendChild(s);
  }

  function toggle() {
    root.toggleAttribute('data-wa-focus');
  }

  function addButton() {
    if (document.getElementById(BTN_ID)) return;
    const b = document.createElement('button');
    b.id = BTN_ID;
    b.type = 'button';
    b.textContent = '☰';
    b.title = 'Toggle chat list (Ctrl+B)';
    b.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      toggle();
    });
    document.body.appendChild(b);
  }

  addStyle();
  root.setAttribute('data-wa-focus', ''); // default: only the conversation shown

  window.addEventListener('keydown', (e) => {
    if (e.ctrlKey && !e.shiftKey && !e.altKey && !e.metaKey && e.key.toLowerCase() === 'b') {
      e.preventDefault();
      toggle();
    }
  });

  // WhatsApp mounts async — wait for <body> to add the button.
  const ready = setInterval(() => {
    if (!document.body) return;
    addButton();
    clearInterval(ready);
  }, 200);
})();
