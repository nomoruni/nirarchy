---
name: diagnose-crash
description: >
  Diagnose why a program crashed on this machine, from a systemd-coredump core dump.
  Use when a process has segfaulted, aborted, or otherwise dumped core, when asked
  why an application crashed or disappeared, or when a "Process crashed:" desktop
  notification is acted on. Triggers: crash, segfault, SIGSEGV, SIGABRT, core dump,
  coredumpctl, "why did X crash", "X keeps crashing", backtrace symbolization.
---

# Diagnosing a Crash

Work from evidence. The goal is an honest account of what happened, not a
plausible-sounding story.

## Establish the facts

`coredumpctl info <pid>` is the starting point. Beyond the backtrace, note the
**command line** the process was started with — it usually reveals what the
program was working on when it died.

`coredumpctl list` shows whether this crash is a one-off or a pattern. Repeated
crashes of the same program, or several programs dying together, point somewhere
different than a single failure does.

## Rule out the boring causes first

Check resource exhaustion before blaming the program: `free -h`, and the journal
for OOM kills. A process killed by the OOM killer is not a bug in that process.

## Correlate against the timeline

The crash timestamp is the most underused piece of evidence. Compare it against:

- **Filesystem mtimes.** A file whose mtime lands on the same second as the crash
  strongly suggests what triggered it.
- **The journal** around that moment: `journalctl --since <time> --until <time>+1min`.
- **Recent package updates**: `grep -E 'upgraded' /var/log/pacman.log | tail -20`.
  A crash that starts right after an update points at the update.

## Read the whole core, not just frame 0

Thread stacks other than the crashing one show what work was **in flight** —
thumbnailers, image loaders, IPC readers, GPU queues. That context often explains
the trigger even when the crashing frame cannot be symbolized.

Note any third-party code in the address space: extensions, plugins, out-of-tree
drivers. In-process third-party code is a common culprit.

## Nirarchy-specific suspects

When the crashed process is part of the desktop itself, check these first:

- **quickshell** — QML errors and crashes land in `journalctl --user -u nirarchy-bar`.
  A config edit that breaks the bar auto-restarts every 2s in a loop; check for
  restart storms before deep-diving.
- **walker / elephant** — elephant holds `NIRI_SOCKET`; after a session change a
  stale socket makes app launches fail silently. `cat /proc/$(pgrep -x elephant)/environ`
  vs `echo $NIRI_SOCKET`.
- **hyprlock / hypridle** — both have a history of SIGABRTs; `coredumpctl list hypridle`.
- **GPU faults (SIGBUS)** on this machine have come from the iGPU driver, not from
  the crashing app itself. Check `journalctl -k | grep -iE 'gpu|drm|sigbus'`.

## Report structure

Answer, in this order:

1. What crashed, and what it was doing at the time.
2. The most likely mechanism — separating clearly what the evidence proves from
   what you are inferring.
3. Whether user data was lost, and where it can be recovered from (check the
   trash before concluding anything is gone).
4. Whether it is likely to recur, and what would avoid or fix it.

## Upstream

Most application crashes are upstream bugs, not Nirarchy's doing. If the cause
sits within Nirarchy's own scripts or QML, say so and propose the fix here. For
crashes in niri, quickshell, or the crashing application itself, point at the
respective upstream issue tracker instead of patching around it locally.
