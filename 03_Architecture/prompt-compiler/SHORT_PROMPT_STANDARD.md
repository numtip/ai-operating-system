# Short Prompt Standard

Rules for compiled prompts. Goal: minimal tokens, maximal executability.

## Hard limits

| Limit | Value |
|-------|-------|
| Max words (body) | 400 (target ≤250) |
| Max sections | 7 |
| Max bullet depth | 1 (no nested lists) |
| Max `context` chars | 800 (prefer paths/links) |

## Required section order

1. **Goal** — one sentence
2. **Scope** — in / out bullets
3. **Files** — read / write / do-not-touch
4. **Constraints** — hard rules only
5. **Validation** — checklist
6. **Output Format** — exact return shape
7. **Context** — optional; omit if empty

## Style rules

1. Imperative voice. No preamble (“You are an expert…”).
2. No duplicated constraints across sections.
3. Prefer paths over pasted file contents.
4. Prefer enums/flags over prose when encoding routing.
5. Ban: secrets, API call instructions, model marketing fluff.
6. Ban: open-ended “explore the repo” without file bounds.
7. One job per prompt; split multi-job work upstream.

## Pass criteria

- [ ] Sections 1–6 present and ordered
- [ ] Within word/section limits
- [ ] Write paths bounded
- [ ] Output Format is exclusive (“Return ONLY…”)
- [ ] No provider invoke language

## Fail → recompile

If any pass criterion fails, shorten or split; do not ship the prompt.
