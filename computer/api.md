# COMPUTER API v1

The API is intentionally model-agnostic.

## Request

POST /api/v1/chat

    {
      "session": "default",
      "message": "Why is my browser slow?",
      "context": {
        "foreground_app": "browser"
      }
    }

## Tool request

The reasoning backend can emit a tool request:

    {
      "type": "tool_call",
      "tool": "system.inspect",
      "arguments": {
        "fields": ["cpu", "memory", "processes"]
      }
    }

The capability broker validates the requested capability before execution.

## Core capabilities

- system.read
- process.read
- filesystem.read
- filesystem.write
- application.launch
- application.control
- input.control
- window.control
- browser.control
- network.read
- settings.read
- settings.write

Potentially destructive capabilities are separate and require an explicit confirmation policy:

- filesystem.delete
- system.shutdown
- system.reboot
- software.install
- system.update

## Response

    {
      "type": "message",
      "text": "I'm checking the system now."
    }

Tool results are returned to the reasoning backend as structured data rather than raw kernel access.

## Privacy

The API must not silently expose credentials, private keys, authentication tokens, or unrelated user data to a reasoning backend. Sensitive fields are filtered by the capability broker.

## Future transports

The same interface can eventually be exposed through a local Unix-like socket, a native IPC mechanism, or a localhost service. The transport is deliberately separated from the agent protocol.
