# machin-batch

A **stream batcher** written in **[machin](https://github.com/javimosch/machin)** (MFL). Reads stdin lines and emits a batch (as a JSON array) whenever it reaches **-n lines** or **-t milliseconds** elapse with lines pending — whichever comes first — plus a final partial batch when the input ends. Useful for feeding bulk APIs or rate-controlling a downstream stage. Single native binary, libc-only.

Part of [**awesome-machin**](https://github.com/javimosch/awesome-machin) — the machin ecosystem.

## Why it exists (dogfooding)

The collector waits on the **input channel and a ticker channel at once**, and has to tell "a line arrived" apart from "the input was closed" — so it can do a final flush and stop. A plain `<-ch` can't express that. Building this tool drove the **comma-ok receive** into machin:

```machin
select {
    case line, ok := <-in:
        if ok == false { flush(); done = true }   // input closed → final flush
        if ok { batch = append(batch, line) ... }
    case <-tick:
        if len(batch) > 0 { flush() }              // time's up → flush pending
}
```

`v, ok := <-ch` reports `ok == false` once a channel is closed and drained — standalone, or inside a `select` case (a closed channel makes its case fire, with `ok == false`).

## Build

Needs the [machin](https://github.com/javimosch/machin) compiler with comma-ok receive + `flush()` (v0.18.0+) on `PATH` and a C compiler.

```bash
./build.sh                          # → ./machin-batch
MACHIN=~/ai/machin/machin ./build.sh
```

## Use

```bash
printf 'a\nb\nc\nd\ne\n' | ./machin-batch -n 2
#   ["a","b"]
#   ["c","d"]
#   ["e"]
tail -f app.log | ./machin-batch -n 100 -t 5000
```

Flags: `-n SIZE` flush after SIZE lines (default 10) · `-t MILLIS` flush at most every MILLIS ms when lines are pending (default 1000). Each batch prints as a JSON array of lines, and the tool calls `flush()` after each one so batches appear immediately downstream even through a pipe.

## How it works

A `read_stdin` goroutine feeds lines into the `in` channel and closes it at EOF; a `ticker` goroutine sends on `tick` every `-t` ms. `main` selects over both, accumulating a `[]string` batch and flushing it (via `json(batch)`) on size, on tick, or on close. Concurrency, channels, `select`, `close`, comma-ok, `json`, and `flush` are all plain machin.

## Layout

```
machin-batch/
├── batch.src     # the whole batcher (MFL)
├── build.sh      # encode → compile to native
└── README.md
```
