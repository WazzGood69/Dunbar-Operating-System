# COMPUTER

Dunbar OS's native AI assistant is named **COMPUTER**.

COMPUTER is intended to feel like part of the machine itself. It can eventually inspect the computer, operate applications, diagnose problems, manage files, and coordinate Dunbar services through a capability broker.

The personality layer is intentionally separate from privileges. COMPUTER can be sarcastic or playful without receiving extra authority.

The initial implementation is an interface foundation. A capable reasoning model still has to be supplied as a backend; the OS API does not magically create a new foundation model.

## Planned UI

A system-wide COMPUTER panel can be summoned from the desktop:

    COMPUTER
    --------------------------------
    > What are we doing?
    --------------------------------
    SYSTEM   READY
    MEMORY   ONLINE
    TOOLS    11 AVAILABLE

The panel should be an OS window rather than a web page.

## Hardware roadmap

The current BIOS stage2 is a small real-mode graphical prototype. COMPUTER will become a real service after the kernel is expanded to protected mode/32-bit operation, memory management, drivers, IPC, and user-space services.

Do not put the full AI stack into stage2: the current bootloader deliberately loads only a small fixed stage2 image.
