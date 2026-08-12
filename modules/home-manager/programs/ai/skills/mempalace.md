---
name: mempalace
description: Drives the MemPalace CLI/MCP — mine projects and conversations into a searchable memory palace. Use ONLY when the user names MemPalace or their memory palace ("mempalace", "memory palace", "mine this into the palace", "search my palace", palace setup). Generic requests to remember, recall, or search past work are not this skill unless the palace is named.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# MemPalace

A searchable memory palace for AI - mine projects and conversations, then search them semantically.

## Prerequisites

Ensure `mempalace` is installed:

```bash
mempalace --version
```

If not installed:

```bash
pip install mempalace
```

## Usage

MemPalace provides dynamic instructions via the CLI. To get instructions for any operation:

```bash
mempalace instructions <command>
```

Where `<command>` is one of: `help`, `init`, `mine`, `search`, `status`.

Run the appropriate instructions command, then follow the returned instructions step by step.
