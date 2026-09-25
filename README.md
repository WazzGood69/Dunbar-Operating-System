# Dunbar OS

Dunbar OS is a lightweight, BIOS-era operating-system prototype for the Dell Inspiron E1705.

The first real hardware build keeps the original design goals:

- DOS-style boot sequence
- Minimal, no-bloat environment
- Dunbar sci-fi / strange laboratory personality
- Keyboard-driven interface
- Real BIOS keyboard input
- Real PC-speaker tones for security/fatal events
- Wrong-password red flash sequence
- Three failed passwords -> fatal/lockout screen
- Simple text-mode desktop

## Hardware target

Initial target: Dell Inspiron E1705, legacy BIOS, x86.

The current build is intentionally tiny and uses BIOS services rather than requiring Windows, Linux, or a modern runtime.

## Demo login

The current development image uses:

**Operator:** any non-empty name  
**Password:** `DUNBAR`

This is a prototype credential embedded in the image, not secure authentication.

## Build

The GitHub Actions workflow assembles the boot image with NASM and publishes the raw disk image as a workflow artifact.

For real hardware, write the resulting image to a USB drive or other disposable test media only after verifying the target device. Writing a disk image overwrites the destination.

## Status

This is the foundation for the real Dunbar OS. The graphical/windowed interface will be built on top of the bootable base rather than remaining only an HTML mockup.


## Graphical shell

The current stage-2 core now enters VGA mode 13h and provides a real graphical-shell foundation directly on the Inspiron hardware. The shell includes a Dunbar access sequence using the physical arrow keys:

- Up = Ϟ
- Left = ⟟
- Right = ᛝ
- Down = ∴
- Enter = ◈

The development password remains `DUNBAR`.

The desktop currently exposes real shell entry points for Terminal, Settings, Authorized Network Diagnostics, and Browser. Network and browser modules are intentionally separate from the kernel and are not yet implemented as full network/browser stacks.

## Security boundary

Dunbar is being designed as a small, auditable operating system. Security work will use defense in depth: signed/integrity-checked system components, authentication, least privilege, minimal network services, encrypted data where supported, rate limiting, tamper-evident auditing, and recovery paths.

Dunbar will not silently monitor or capture unrelated nearby networks. Network diagnostics are intended for interfaces and networks the operator is authorized to administer.

## Browser

A modern browser engine is planned as a user-space application rather than part of the kernel. The eventual browser will integrate Dunbar's network filtering/ad-blocking layer while remaining isolated from the core OS.
