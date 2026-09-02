# StayNest — Decisions Log

Append-only. A decision here is closed. If you want to reopen one, write a new
entry saying why and what changed — don't edit the old one.

---

## D1 — Backend framework: **NestJS**
**Date:** August 2026 · **Status:** Closed

TypeScript across `staynest-api`, `staynest-web` and the admin console. One
language, one toolchain, one mental model for a solo developer. Raw-body webhook
handling for the Paystack HMAC is straightforward to configure, which is the
single most common integration failure.

**Binding consequence — money is never a floating-point number.**
JavaScript has no decimal type. Therefore:

- All amounts are **integers in pesewas**. GH₵3,200 → `320000`.
- Postgres columns are `BIGINT`. Never `FLOAT`, never `REAL`.
- The API contract carries pesewas. Field names say so: `amountPesewas`.
- Formatting to `GH₵3,200.00` happens **only** in the Flutter render layer.
- Any arithmetic on money is integer arithmetic. Commission is computed as
  integer basis points, then rounded once, explicitly.

Add a lint rule and a schema check for this. It is the one thing NestJS makes
easier to get wrong than ASP.NET would have.

---

## D2 — Flutter state management: **Riverpod** (with `riverpod_generator`)
**Date:** August 2026 · **Status:** Closed

`AsyncValue` maps directly onto three of the five required screen states
(loading / error / data). Bloc's ceremony buys traceability that matters for a
team and costs typing that matters for one person.

Use the `@riverpod` annotation style from day one. The hand-written
`StateNotifierProvider` syntax in older tutorials is legacy — don't start there.

**Two states `AsyncValue` does not cover:**
- **Empty** is a variant of `data`, not a state of its own. A zero-length list
  is a successful response. Check length in the widget.
- **Offline** is orthogonal to any single request. A connectivity provider
  drives `SNOfflineBanner` app-wide; it is not a request state.

---

## D3 — Dark mode: **not in Phase 1**
**Date:** August 2026 · **Status:** Closed, revisit post-pilot

`globals.css` has no dark tokens. Defining a full second palette means dark
counterparts for 24 colours plus dark variants of every glass and shadow
treatment, and a second contrast pass on all 50 screens. That is real cost for a
preference feature that has no effect on whether a student can book a bed.

**Action:** remove the Dark Mode row from `settings.tsx`. Do not ship a toggle
that does nothing.

**But the plumbing is built for it anyway.** Colours live in a `ThemeExtension`
(`SNColorTokens`) read via `context.sn`, not in static consts. Adding dark mode
later is one new `SNColorTokens.dark` instance plus one line in `theme.dart` —
no screen changes. This cost about an hour now and saves a 50-screen refactor.

---

## D4 — Roommate identity on `select-bed`: **anonymised in Phase 1**
**Date:** August 2026 · **Status:** Closed

Carried forward from the app build plan; recorded here because it is a legal
decision, not a design one. Show "Level 300 · Computer Science · Female" with a
generic avatar. No name, no photo, no course-specific identifier, no "92% Match".
Real identity unlocks only when both parties are confirmed tenants **and** both
have opted in. Act 843 obligation and a safety requirement for women's hostels.

---

## Still open

| # | Decision | Blocks |
|---|---|---|
| O1 | Pilot campus — name one | Stage 5, and all content work |
| O2 | Margin source: student-side commission or owner-side subscription | Leakage exposure, owner contracts, Booking Review copy |
| O3 | Phase-1 cut list if week 20 arrives early | Nothing yet — but decide while it's cheap and unemotional |

Suggested answer to O3, from the app build plan: Interactive Map, Saved Hostels,
Student ID Verification.
