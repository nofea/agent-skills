# Local software

Source: [Local-first software](https://www.inkandswitch.com/local-first/) by Ink & Switch and [The Twelve-Factor App](https://12factor.net/) for any backend it uses.

**What's different:** the software runs on devices you don't control. Old versions stay in use, networks come and go, and you can't fix user data directly.

**Starting shape:** one app with local storage, and no backend. Use plain files when users benefit from reading or moving them, and an embedded database such as SQLite when the app needs fast queries or changes across many records. Record a format version from the first release, in the file, or in a manifest for a folder of files, so later versions can migrate the data. A CLI usually needs only config files and a stable command interface.

## When to add more

| Stated requirement | Consider | Added cost |
| --- | --- | --- |
| Data must survive a crash or a lost device | Atomic saves, then backup or export | Testing failure cases |
| Users want their data on a second device | The platform's sync or a file-sync folder first, then your own sync service | Conflicts, and a service to run |
| Several people edit the same data | A conflict strategy, such as last-write-wins, merging or CRDTs | The hardest part of the product |
| The app needs accounts or paid features | A small backend for identity and licences | Now also a service: read [services-web.md](services-web.md) |
| Fixes must reach users quickly | An auto-update mechanism with signed releases | Update failures, release signing |
| Other people will install it | Packaged installers, with code signing where platforms expect it | Signing certificates, a build per platform |
| You need to understand crashes | Opt-in crash reporting | Privacy duties and consent |
| Several platforms need the same logic | A shared core with native interfaces | Build complexity |

An **atomic save** writes a temporary file, then swaps it into place, so a crash leaves the old version or the new one. **CRDTs** (conflict-free replicated data types) are data structures that merge concurrent edits automatically. They avoid conflicts in the data, but the merged result may still not be what users expected.

## Hard to reverse

- Local file and database formats
- CLI commands, flags and output that scripts depend on
- The sync and conflict model
- Platform and framework choices
- Any permissions or data access users have accepted

## Common failures

- Adding a backend for something the device could do by itself
- No format version, so upgrades can corrupt or strand user data
- Migrations with no backup or recovery path
- Treating sync as a small feature, then discovering it's a distributed system
- Assuming the network works, or that it fails quickly
- Auto-updates that can leave the app unable to start

## Review checks

- What happens to user data on upgrade, downgrade and crash during a save?
- What still works offline? Does the user know when they're offline?
- Can an old version safely open data from a new one?
- How long will you support old versions?
- Are updates signed, and can they recover from failure?
- If your company vanished, could users still get their data?
- For a CLI, is the output safe for scripts to depend on?
