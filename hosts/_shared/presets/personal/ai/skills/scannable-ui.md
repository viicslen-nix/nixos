---
name: scannable-ui
description: Make a UI feel "weirdly perfect" by designing it to be scanned rather than read — edge alignment, differentiated density, recognizable visuals over labels, relative emphasis, and dissolving nested cards. Use when building or reviewing any interface layout (cards, lists, settings panels, toolbars, dashboards, forms), when a design "looks off" or "feels cluttered/unpolished" and nobody can say why, when deciding between adding whitespace, dividers, tooltips or explanatory labels, or when asked to tighten, clean up, or polish a screen.
---

# Scannable UI

Nobody reads a screen. People arrive with a question already in their head and
hunt until they find the answer. Nothing is ever fully consumed — not a file
tree, not a settings panel, not a task list.

So every layout decision is judged by one question: **does this make the screen
faster to scan?** Prettiness is not the goal; it is a side effect of getting
this right. Each tool below speeds up scanning without ever having to tell the
user where to start.

## 1. Lock everything to an edge

A Walmart receipt has no dividers and almost no whitespace, yet it is trivial to
read: text hard left, prices hard right, and the only centered things are the
codes you are not meant to read. Two edges hold the whole thing together.

- A card hands you four edges free. Elements also create edges for each other —
  an avatar's baseline is an edge the content below can stack onto.
- In a well-built compact UI (chat input, kanban card, sidebar, checklist row)
  **every element borders at least two edges**. Check this explicitly.
- When something sits unaligned, do not reach for whitespace or a divider.
  Either move content to clear the edge, or **manufacture a new edge** — pull a
  row down so buttons and avatar form one solid line for the content below.
- Replacing small icons with large ones can destroy the bottom edge a row was
  providing. Restore it (a subline, a second row of text), don't ignore it.
- Edges must be *contained*. Letting divider lines run the full screen width
  leaves every edge exactly where it was and still ruins the feel.

Do not fix alignment by hiding elements. Collapsing the extra buttons into an
overflow menu makes the card look better and is still the wrong fix — it trades
a layout problem for a discoverability problem.

## 2. Differentiate density, don't dilute it

Too much content is rarely the problem. **Undifferentiated** content is.

Adding whitespace to a dense list helps slightly and makes everything longer.
Instead:

- Vary the element types — drop in avatars where people are referenced, icons
  where types are, chips where categories are.
- **Group** by a real axis (due date, status, owner). Once grouped, the amount
  of text stops mattering; anything is findable in about a second and density
  works for you.

This is why walls of agent output get bullet points and closing tables: the
differentiation is what makes it readable, not the word count.

## 3. Show, don't explain harder

When something is not clear, the instinct is to explain harder — add a
comparison, a label, a tooltip. Every addition is technically more information,
so it feels productive. But you have made the screen **harder to read in order
to make it easier to understand**, which is a trade you almost never want.

Replace plain text with visuals that register instantly:

- A red octagon is a stop sign before you read a word. Avatars identify people
  before you read a name. Blue + underline is a link. A chip with an icon is a
  value and its type at once.
- A card with *less* raw information can be strictly better if it turned that
  text into diagrams and icons.
- Visuals only pay off when they are **immediately recognizable**. An action bar
  of unlabeled icons is guessing-while-you-wait-for-a-tooltip; the one item you
  understand is the one whose *placement* tells you what it does.
- Making something visual often hands the user functionality for free — a
  swappable tag chip replaces a menu item.

## 4. Emphasis is relative, not intrinsic

Emphasis is not something an element has. It is the difference between it and
its neighbors.

- A checkbox that is off is a thin border: no color, no icon, easy to skip. The
  fill and checkmark are earned by being checked. **Nobody would design a
  checkbox that is blue when it is off** — the color is the entire signal.
- A settings panel where every chip shows a default value is six checkboxes that
  are all blue when off: clean edges, good grouping, real icons, and still
  useless, because nothing stands out.
- To make one thing stand out, **change its surroundings** before you reach for
  bolder text or more color on the thing itself. Render defaults gray and the
  non-defaults find the eye by themselves.
- Corollary: at most one saturated call-to-action per view. If the only blue
  button on a screen is the upsell, you know exactly what the screen wants.

## 5. Cards are scaffolding — dissolve them

Cards are the default because four edges come free and resizing fixes overflow.
But nobody ships just one card. On an open canvas people keep nesting
containers for structure until there are borders on borders and three radii
stacked together, and none of it helps.

A single line often replaces the whole hierarchy: a column edge does what the
card edge did, each row stacks onto the one above, sections do the grouping,
chips and icons do the reading, and gray defaults handle emphasis. Cards or no
cards, the target is the same scannable interface.

## Review checklist

Run this against a screen before calling it done:

1. Does every element border at least two edges? Are any divider lines running
   past their container?
2. Is dense content grouped and varied, or just spaced out?
3. Is anything explained with a label or tooltip that a recognizable visual
   could carry instead? Is any icon carrying meaning it cannot be read from?
4. Are defaults visually quiet? Pick the one thing that should win the eye — does
   it, because of its neighbors rather than its own styling?
5. How many nested containers/borders/radii deep is this? Can a line replace one?
