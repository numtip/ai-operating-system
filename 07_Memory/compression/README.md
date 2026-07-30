# Memory Compression

Index for session compression and archive.

| File | Role |
|------|------|
| [COMPRESSION_POLICY.md](COMPRESSION_POLICY.md) | When and how to compress |
| [ARCHIVE_POLICY.md](ARCHIVE_POLICY.md) | Retain / move / delete rules |
| [THRESHOLD.json](THRESHOLD.json) | Session count threshold |

## Templates

- [SESSION_SUMMARY](../../11_Templates/SESSION_SUMMARY.md)
- [EXECUTIVE_MEMORY_SUMMARY](../../11_Templates/EXECUTIVE_MEMORY_SUMMARY.md)
- [OPEN_DECISIONS_SUMMARY](../../11_Templates/OPEN_DECISIONS_SUMMARY.md)
- [LESSONS_LEARNED_SUMMARY](../../11_Templates/LESSONS_LEARNED_SUMMARY.md)

## Check

```powershell
pwsh -File scripts/check-session-threshold.ps1
pwsh -File scripts/check-session-threshold.ps1 -FailOnThreshold
```
