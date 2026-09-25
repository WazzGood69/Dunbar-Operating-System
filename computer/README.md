# COMPUTER — Dunbar OS AI System

COMPUTER is the planned first-class AI system service for Dunbar OS.

## Design goals

- Native OS service, not a browser-only chatbot.
- Conversational interface with persistent, user-controlled memory.
- Tool-driven computer control.
- Explicit capability permissions.
- Fail-safe destructive-operation handling.
- Local system diagnostics.
- Extensible reasoning backends.
- Personality configuration without changing security policy.

## Architecture

Application requests enter the COMPUTER API. The agent can request capabilities from the Dunbar service manager:

    User
      |
      v
    COMPUTER UI
      |
      v
    COMPUTER API
      |
      +-- Reasoning backend
      +-- Memory service
      +-- Task manager
      +-- Capability broker
              |
              +-- filesystem
              +-- processes
              +-- input/window control
              +-- browser
              +-- network diagnostics
              +-- system settings
      |
      v
    Dunbar kernel/services

The capability broker is the security boundary. COMPUTER never receives unrestricted kernel primitives directly.

## Personality

COMPUTER may be dry, funny, curious, sarcastic, or strange. Personality is separate from authorization and safety policy.

## Reasoning backend

The repository defines the COMPUTER interface and OS integration independently of any particular model. A future Dunbar build can connect a local model, a remote model, or a hybrid backend.

This avoids pretending that a hand-written API is itself a foundation model.

## Current status

This directory is the architecture/API foundation. The current BIOS stage2 remains intentionally small; the full COMPUTER service belongs in the upcoming protected-mode kernel and user-space service architecture.
