# Games

Source: [OWASP Desktop App Security Top 10](https://owasp.org/www-project-desktop-app-security-top-10/), [OWASP MASVS](https://mas.owasp.org/MASVS/) for mobile, and each engine's own networking documentation. Console rules are under NDA, so this guide stops at public-level advice for them.

**What's different:** the game must finish every frame on time, on hardware you don't control. Players run the client on machines they own, so they can read and change anything in it. Content is large, and a released multiplayer game can't change everything at once.

**Starting shape:** one program, using an existing engine, with local saves and no network or backend. State a frame budget from the start, such as 16.6 ms for 60 FPS, along with the minimum hardware. Record a format version in every save file from the first release. Use the store's own services for achievements, cloud saves and updates.

A custom engine is rarely the simplest shape. Recommend an existing engine, unless a stated requirement rules them out.

## When to add more

| Stated requirement | Consider | Added cost |
| --- | --- | --- |
| Friends play together, with nothing at stake | One player hosts, using the store's relay and invites | NAT problems, host quitting, host can cheat |
| Competitive play or ranked ladders | Dedicated authoritative servers | Hosting per match, ops, region choice |
| Fast real-time action over the network | Client prediction and server reconciliation, or rollback for fighting games | Must be designed in from the start. Very hard to add later |
| Slow or turn-based play | Plain request and response to a small service | Now also a service: read [services-web.md](services-web.md) |
| Strangers play together | Matchmaking, then a player report and block system | Moderation is now a duty |
| Players keep items, currency or rank online | Server-side accounts and storage, with an audit trail | Economy design, support, fraud |
| Purchases inside the game | The store's own payment system, with receipts checked on your server | Fees, refunds, legal duties |
| Content changes without a client patch | Signed content delivery and server-side configuration | Version mixes to test, cache problems |
| Live events or seasons | Live operations tools with staged rollouts | Staff, on-call, long-term cost |
| Players make mods or levels | A data-only format first, then a sandboxed scripting language | Attack surface, moderation |
| Large worlds | The engine's streaming tools | Content rules, memory budgets |
| You need to understand crashes or balance | Opt-in crash reports and limited telemetry | Privacy duties and consent |

An **authoritative server** decides what really happened, and treats client messages as requests. **Client prediction** shows the result of the player's input immediately, then corrects it when the server answers. **Rollback** re-simulates recent frames when late input arrives, and needs the game to be deterministic.

## Online trust

Choose the networking model from what's at stake.

- **The server decides** anything competitive, anything with shared value, and every purchase. That covers ranked results, inventories, currencies and receipts. The client sends what the player tried to do, never the result.
- **Casual co-op can stay peer-hosted.** Say plainly that the host can cheat, and keep anything lasting, such as a shared economy, out of it.
- **Client-side anti-cheat is extra defence only.** It can raise the cost of cheating, but it can't replace server checks, because the player controls the machine.
- **Kernel-level anti-cheat is hard to reverse.** Take it as a decision card. It adds a privileged component on players' machines, can stop some platforms from running the game, and a flaw in it harms players outside your game.
- **Mods and shared content are untrusted input.** Prefer data-only formats. If mods run code, sandbox them, and warn players that a mod can harm them if it isn't sandboxed. Don't load engine resource files from outside the game if they can run code.

## Security and lifecycle

Apply [security.md](../security.md). For this type:

- **Threats:** forged client messages, cheats, modified clients, stolen accounts, save files and mods that attack the loader, purchase fraud, denial of service against game servers, and harassment between players. Anything shipped in the client isn't secret, so API keys and server secrets stay off it
- **Maintenance:** signed updates through the store, migrations with a backup for save files, and a plan for keeping servers compatible while old clients update. Say how long online services will run, and what happens to the game afterwards
- **Diagnostics:** a local log the player can export, and opt-in crash reports matched to a build version and stored symbols. Remote access to a player's machine isn't a support path
- **Developer mode:** cheat commands, debug menus and test servers stay out of shipped builds, using the engine's own build configurations. A config flag alone isn't enough

## Hard to reverse

- Engine choice, and its licence and fee terms
- The networking model, including authoritative, peer-hosted, prediction and rollback
- Determinism, if rollback or replays depend on it
- Save file formats
- Network protocols that old clients still use
- Account and identity systems, including linking across stores
- In-game economy design, once players own things
- Any store's exclusive agreement or platform-specific service
- Anything a console platform holder must approve, which needs their own documentation

## Common failures

- Building an engine or a backend before the game is fun
- Adding multiplayer to a finished singleplayer game
- Trusting the client for damage, score, currency or position
- No save format version, so patches break player progress
- No frame budget until late, when content can't be cut
- Loading save files through a format that can run code
- Secrets shipped in the client
- Online services with no plan for when they end
- No way to report or block players
- Testing only on developer hardware

## Review checks

- What's the frame budget, and which minimum hardware was it measured on?
- What happens to saves on upgrade, downgrade, and a crash during saving?
- Which messages from the client can change lasting state? Does the server check each one?
- What could a modified client do, and who's affected?
- Which secrets are in the shipped client?
- How do old clients behave after a server update?
- Can saves, mods or shared levels run code when loaded?
- If the servers shut down, what can players still do?
- How do players report abuse, and who acts on it?
- Have the [game legal flags](../../SKILL.md#safety-and-legal-duties) been raised?
