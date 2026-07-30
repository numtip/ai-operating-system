# Agent Bootstrap Checklist

Use with [AGENT_BOOTSTRAP.md](AGENT_BOOTSTRAP.md).

## Pre-execute

- [ ] Read `07_Memory/SYSTEM_MEMORY.md`
- [ ] Read `07_Memory/CURRENT_STATE.md`
- [ ] Ran `git status` and `git log -5 --oneline`
- [ ] Loaded project memory only if needed
- [ ] Loaded relevant ADRs only if needed
- [ ] Loaded task / context package
- [ ] Write bounds and do-not-touch paths clear
- [ ] Session readiness noted ([SESSION_READINESS.md](SESSION_READINESS.md))

## Execute / close

- [ ] Changes limited to assigned paths
- [ ] No secrets, Hermes, unauthorized push/commit
- [ ] Validation done (narrow)
- [ ] Close updates per `07_Memory/SESSION_CLOSE.md` when ending session
