---
name: de-complect
description: Use when asked to "simplify", "de-complect", "untangle", "remove cruft", "make erroneous states unrepresentable", or "clean up" a design document (plan/ADR/spec) or an implementation branch after a feature lands and before merge — or when a diff is thick with defensive checks, sentinels, tri-state configs, scattered validation, speculative abstraction, and stored-but-derivable state.
---

# De-complect: remove braided complexity from designs and code

*Complect* = to braid, interleave, entwine. The complexity that hurts is rarely size; it is
independent concerns twisted together so that none can be reasoned about, changed, or debugged
alone. This pass finds those braids and cuts them so each concern hangs straight down. It runs on
two kinds of target:

- **A design document** (plan, ADR, spec, handoff doc) — the deliverable is a disentangled rewrite.
- **An implementation branch** — after a feature lands, before merge — the deliverable is a series
  of small, behavior-preserving cuts.

This is a **quality** pass, not a bug hunt. Design cuts preserve the document's intent and scope;
code cuts preserve behavior, with the test suite as one safety net among several. If you trip over
a genuine correctness bug mid-pass, note and surface it separately — never fix it here.

## Simple ≠ easy

- **Simple** = one fold. Un-braided: one role, one concept, one dimension of the problem.
  Objective — you can look and see whether two things are twisted together. Simplicity is NOT
  counting: one concern cleanly split across five files is simpler than two concerns knotted into
  one function. **Cardinality ≠ interleaving.**
- **Easy** = near at hand. Familiar, already-installed, within reach of current habits.
  Relative — easy *for whom?*

"We should do it this way because it's simpler" almost always means "because it's familiar to me" —
a claim about easy, inadmissible as evidence about simple. Interrogate every "simpler" in the
target *and in your own remedies*: does it reduce interleaving, or only unfamiliarity, keystrokes,
and file count?

Likewise, a recognizable shape — an `unwrap_or`, a single-`impl` trait — is a prompt to ask whether
the construct earns its keep *here*, not a finding in itself. Reason about intent and invariants,
not form.

## Judge the artifact, not the construct

We do not ship the design doc or the diff; we ship the running system, and then we live in it.
Evaluate every braid and every cut by the **artifact**:

- **Reasoning** — you can only reason about what you can hold in your head, and every braid adds
  combinatorially to that load.
- **Change** — when a requirement moves, how many entangled things must move with it? A redundant
  check quietly hardwires knowledge of what upstream guarantees; when upstream changes, the two
  drift apart.
- **Debugging** — the field bug got past the type checker and every test. A defensive check
  documents a *false* invariant ("apparently someone thought this could be `None` here"), actively
  misleading whoever debugs next.

This is why cutting "harmless belt-and-suspenders" is worth the effort: each unnecessary guard is
another thing to hold in your head, another coupling waiting to drift, another false signal in the
field. It is also why suite-green is not the goal: guardrails are secondary; simplicity is what
lets you localize the bug they missed. "Fewer keystrokes", "one file", "the team already knows
this pattern" are construct virtues — not on the list.

## The complect radar

Scan the target for these braids. Rank findings by artifact cost, not diff size.

| Braid | In a design | In code | Disentangled |
| -- | -- | -- | -- |
| **value + time** | "store the computed X"; a status field that ratchets forward | tri-state `Option<bool>` rewritten at assembly, read via `unwrap_or`; a cached derivable; an `is_ready` flag written once, read forever | store facts, derive conclusions at read; split the parse DTO from the resolved type |
| **what + how** | spec dictates implementation ("fold left over…") | single-`impl` trait with no second implementor in view; no-op wrapper that just forwards | name the operation set, keep the *how* behind it — or, if the seam cuts no braid, inline it |
| **policy (why) scattered** | the same rule restated in three flows; magic strings inline | invariant re-checked on every read instead of made unconstructable; the same guard inlined at N call sites; "this can't happen" branches; error variants for unreachable conditions | one placement: a type that makes the bad state unrepresentable, or a single declarative site |
| **data + representation** | bespoke record shapes wrapping plain facts | sentinel `""`/`-1`/`0` standing in for an `Option`/enum; a DTO class around what is a map of facts | put absence and variants in the type (`Option<&str>`, an enum); data as data |
| **when + where** | "A calls B then C" hardwired through the doc | a step that must know where the next step lives; hardwired call chains | queue, event, or derive-at-read, so no step names its successor |
| **fused to reduce parts** | "handle X and Y in one service/step/table to keep it simple" | one function/type serving two unrelated concerns | split them: more straight strands beat fewer knots |
| **modular but complected** | components that assume each other's internals | files that depend on each other's private behavior ("this assumes that never returns 17"); a "no-op" wrapper callers secretly rely on | limit what each part is *allowed to know*; make the contract explicit |

Separate **incidental** complexity (introduced by chosen constructs — fixable, always the design's
fault) from **inherent** complexity (imposed by the problem or the environment — leave it, and do
not count it against the code). Only incidental braids are findings.

## Judgment razors

- **A remedy must reduce interleaving — not familiarity, keystrokes, or count.** Inlining an
  abstraction because indirection feels heavy is an easy-claim; check what it was separating first.
- **An abstraction earns its keep iff you can name the braid it cuts.** Can't name one → ceremony →
  cut it. Equally: never *add* a layer that disentangles nothing.
- **Variants are distinct iff some caller's policy branches on the distinction.** Collapsing
  variants callers distinguish braids their whys back together; keeping variants nobody branches on
  is ornament. Count is never the test.
- **No named survivor → not redundant → restore it.** Every removed guard must name what now
  enforces its invariant.
- **Relocation is not removal.** A check moved into a helper still called at every site is the same
  braid in a tidier costume — it reads as progress and is worse than none.

## What to preserve

The general rule: a construct is load-bearing when it is the **sole placement of an inherent
constraint**. Instances — call them out as intentional rather than flagging them:

- **The sole enforcement point**: input validation that is the *only* guard (e.g. tool-call
  arguments where the schema is advisory and never enforced at the boundary).
- **Required safety rails**: a bound or check mandated by a spec/requirement, even if the current
  structure makes it hard to hit.
- **Concurrency primitives matching real ownership**: an `AtomicBool` guard through a shared
  `&self` cannot become a take-by-value `Option`.
- **Genuine architectural seams**: a trait that is the documented extension point, mirroring an
  established pattern in the codebase — even with one impl today.
- **Test seams**: a generalization (e.g. over `AsyncWrite`) with a real second caller in tests.
- A DI/context struct that is over-built today but has a confirmed near-term second consumer.

When unsure: **load-bearing until proven otherwise**, where *proven* means you can name the
concrete surviving enforcer. Finding nothing is a valid and common result — especially on small or
already-tight targets. Report "clean" rather than inventing a finding to justify the pass.

## Process

### 1. Identify the target
A path to a document → design lane. Otherwise default to the code lane: the cumulative branch diff
against the merge base, excluding generated/state files unless relevant. Ambiguous → ask.

### 2. Load it whole, plus surroundings
Read the target in full — no partial reads. Design lane: also the ADRs and code it references,
enough to know the artifact it will produce. Code lane: enough surrounding code to know intent and
invariants; for large multi-author branches, partition the changed files into coherent clusters
(parse/types, storage, wiring) and take one at a time — or one read-only reviewer per cluster if
the repo supports parallel review. Verify suspicious editor diagnostics against
`cargo check --all-targets` before reporting them.

### 3. Build the ledger
Every finding is one ledger entry:

> **braid** (which concerns, which radar row) → **artifact cost** (reasoning / change / debugging,
> concretely) → **the cut** (prefer "replace runtime check X with type Y" over "delete X") →
> **survivor** (what enforces the invariant afterward — often two mechanisms) → **precondition**
> (the fact the cut rests on — *verify it against the code, never assume it*) → confidence, and
> behavior-preserving or not.

An entry whose survivor cell you cannot fill is not a finding — it is a preserve. The ledger is the
finding format, the triage input, the review artifact, and the memo.

### 4. Rule and triage
Rule simple-vs-easy on every contested cut, and incidental-vs-inherent on every braid. Then bucket:
**clear wins**, **judgment calls**, and **intentional / load-bearing** (named, so they are not
re-litigated). Drop behavior-changing items that are not clearly improvements, anything that
removes a spec rail, and low-value cosmetic churn.

### 5. Surface load-bearing forks
When a cut could go multiple legitimate ways (derive-at-read vs. recompute-on-event), or a braid
might be a deliberate seam ("is this single-`impl` trait your intended extension point?"), ask the
author — one question converts a guess into a fact. Do not ask about local taste.

### 6. Execute
- **Design lane**: rewrite to a sibling `<basename>.simplified.md`, original untouched (in-place
  only on request). Lead the file with a **Simplification memo** — the ledger, condensed — so the
  reader sees what was braided and how it was cut before the revised design. Preserve intent,
  scope, and hard constraints: un-braid the design, do not redesign the product.
- **Code lane**: one cut (or one tightly-coupled pair) at a time, in **increasing invasiveness** —
  small isolated cuts first, the structural remodel last, on an already-clean base. Before a
  structural cut, pin the contract: the target type design, the invariant truth-table it must
  preserve, and a test-migration map. If no existing test exercises the changed path, the suite is
  not a safety net for it — add a characterization test first, or lower confidence and flag the
  gap. Verify with cargo and review after every cut.

### 7. Self-check gates (blocking)
Run both gates on your own output before finishing either lane; fix what they catch, then re-run.

- **The survivor gate.** For every cut that removed a guard, check, field, or variant:
  name the concrete surviving mechanism(s) enforcing the invariant; state the factual precondition
  the cut rests on and verify it against the code (e.g. "only safe if every path to this function
  goes through the parse"); and follow the deletion into the tests — a test that exercised a
  removed guard now tests nothing, so repoint it at the survivor. Never weaken an assertion to make
  a cut pass; only tests covering genuinely-removed code go with it.
- **The relocation gate.** Re-scan the finished cuts for braids *relocated*
  rather than cut, and for claims in your own ledger that the code contradicts: for every construct
  you called "inert", "no-op", or "documentation-only", confirm nothing reads it to branch, filter,
  or assert. Include the mechanical trap: before deleting a "no-op" `let _ = (&field, …)` discard
  or an `#[allow]`, confirm removal raises no warning (`#[derive(Deserialize)]` does not count as a
  read, and `#[derive(Debug)]` is ignored by dead-code analysis). If it warns, restore it and
  report — do not trade ornament for a warning.

### 8. Verify and report
- **Code lane**: run the full suite on the finished stack — `cargo fmt --check`,
  `cargo clippy --all-targets --all-features`, `cargo nextest run`, `ratchets check`.
- **Design lane**: confirm the memo leads the file and that intent, scope, and hard constraints
  survived intact.
- **Report**: the ledger of cuts with their survivors, rulings on contested "simpler" claims, forks
  raised, items preserved as intentional, and inherent complexity deliberately left alone. Route
  any correctness bugs to a bug-hunting review.

## Worked examples

- **value+time & data+representation — tri-state collapse.** `enabled: Option<bool>` rewritten
  `None → Some(true)` at assembly, read via `unwrap_or(false)`, then carried *dead* into a
  component that only exists when enabled. Cut: split the parse DTO from a resolved type; the
  consumer holds `Option<ResolvedConfig>` with **no `enabled` field** — "disabled" = `None` by
  construction. Survivor: the type. Deletes the rewrite, the accessor, the `unwrap_or`, the dead
  field, and the comments that existed only to compensate.
- **data+representation — sentinel → `Option`.** A helper returning an owned `String` with `""`
  meaning "absent", forcing a downstream `!is_empty() && …` guard. Cut: return `Option<&str>`.
  Survivor: the type; the guard and an allocation vanish.
- **what+how ceremony — namespacing struct → free fn.** A zero-field `struct FooThing;` hosting one
  associated `fn`, never called on an instance, implementing no trait. Cut: a module-level free
  `fn`; delete the struct/impl. (Distinguish the *real* seam — the trait plus the concrete type it
  delegates to — which stays.)
- **what+how ceremony — no-op wrapper.** A trait default `summarize()` that just returns
  `self.list()`, with no override and one caller. The relocation gate first — confirm no caller
  relies on it incidentally — then cut: the caller uses `list()`.
- **design lane — policy scattered & value+time.** A plan restates its authorization rule in three
  flows and stores a derived `status` that ratchets forward. Cut: one declarative policy section
  the flows reference; store the underlying facts and derive `status` at read. Survivors: the
  single policy site; the derivation.

## Rationalizations

| Excuse | Reality |
| -- | -- |
| "It's harmless belt-and-suspenders" | Each needless guard is reasoning load, a coupling waiting to drift, and a false invariant misleading the next debugger. |
| "The suite is green, so the cut is safe" | Green covers only exercised paths — that is why the survivor gate demands a named enforcer, not a passing run. |
| "This is obviously a no-op" | Callers may rely on it incidentally and lints may depend on it. Prove it at the relocation gate; don't eyeball it. |
| "I should find something to justify the pass" | Clean is a valid and common result. Report clean. |
| "It's simpler this way" | Simpler for whom? If it reduces familiarity or count but not interleaving, it is an easy-claim. |

## Traps

- "Simpler" that means familiar / fewer files / less typing — an easy-claim; relabel it and
  re-decide on artifact merits.
- Counting as simplicity — fusing independent concerns to reduce parts, or refusing a clean split
  because it adds files.
- Deleting into a compiler/clippy warning — verify first; restore if it warns.
- Removing a spec-mandated rail because the current structure makes it hard to hit.
- Stripping a documented forward seam or the sole enforcement point of an invariant.
- Weakening or deleting test assertions to make a cut pass — migrate them to the survivor instead.
- Adding an abstraction that disentangles no named braid — ceremony, not simplification.
- Doing the structural remodel first, or batching cuts into one giant unreviewable commit.
- "The tests/types cover it" — the shipped bug passed both; guardrails are secondary to being able
  to localize the fault.
- Treating the pass as a bug hunt — quality only; route correctness findings to a dedicated review.
- Redesigning the product instead of un-braiding the design — preserve intent and scope.
