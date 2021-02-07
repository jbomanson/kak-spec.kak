# Architecture

```
                                                     ┌─────────────────┐
                                                     │  bin/kak-spec   │
                                                     └─────────────────┘
                                                       │
                                                       │ executes
                                                       ▼
                                                     ┌─────────────────┐
                                                     │  lib/runner.sh  │ ─┐
                                                     └─────────────────┘  │
                                                       │                  │
                                                       │ launches one     │
                                                       │ per spec file    │
                                                       ▼                  │
┌──────────────────────────────┐                     ┌─────────────────┐  │
│                              │                     │  kak client #1  │  │
│ lib/kak-spec.kak-no-autoload │                     │       ...       │  │
│                              │  ┌────────────────▶ │  kak client #n  │ ─┼────────────────┐
└──────────────────────────────┘  │                  └─────────────────┘  │                │
  ▲                               │                    │                  │                │
  │                               │ eventually         │ each informs     │                │
  │ each loads                    │ commands each to   │ via a separate   │ launches and   │
  │                               │ quit via kak -p    │ FIFO             │ waits for      │
  │                               │                    ▼                  │                │
  │                               │                  ┌─────────────────┐  │                │
  │                               └───────────────── │ lib/reporter.rb │ ◀┘                │
  │                                                  └─────────────────┘                   │
  │                                                    │                                   │
  │                                                    │ prints to                         │
  │                                                    ▼                                   │
  │                                                  ┌─────────────────┐                   │
  │                                                  │   /dev/stdout   │                   │
  │                                                  └─────────────────┘                   │
  │                                                                                        │
  └────────────────────────────────────────────────────────────────────────────────────────┘
```
