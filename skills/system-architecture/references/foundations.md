# Foundations

Shared thinking for every system type. Use what's relevant, and skip what isn't.

## Contents

- [Requirements](#requirements)
- [Estimation](#estimation)
- [Failure](#failure)
- [Security](#security)
- [Cost](#cost)
- [Glossary](#glossary)

## Requirements

Choose from these, along with anything the type guide raises. Ask only what would change the design, in plain language.

| Topic | Ask | Why it matters |
| --- | --- | --- |
| Purpose | What does it do, and for whom? | Sets the scope and the system type |
| Size | How many users, devices or records, now and in a year? | Sizes capacity |
| Speed | How long is too long to wait? | Sets the latency target |
| Downtime | If it stopped for an hour, what would happen? | Sets the availability target |
| Data loss | If the last hour of data vanished, what would happen? | Sets the backup and durability needs |
| Wrong results | How bad is a wrong answer or action? Which actions need a person's approval? | Sets validation and human checks |
| Environment | Where does it physically run, and who can reach it? | Limits hardware, power and maintenance |
| Sensitivity | Does it hold personal, payment, health or secret data? | Sets the security and legal duties |
| Threats | Who might want to misuse it, and what's the worst they could do? | Shapes the threat model |
| Market | Which sector is it for, and in which countries will it be sold? | Decides which standards and rules apply |
| People | Who builds and runs it? Who's on call at 3am? | Limits how much the team can operate |
| Budget | What's acceptable per month, or per unit? | Rules options in or out |
| Lifetime | Is this a prototype, or will it run for years? | Sets how much care to take |
| Maintenance | Who upgrades it after release, and for how long? | Sets the update, patching and support plan |
| Constraints | What's already decided: vendors, platforms, regulations? | Removes options up front |

## Estimation

Rough numbers are enough, because the goal is to find the right order of magnitude. Show the arithmetic, so the user can correct an input and learn the method.

**Request rate:** 10,000 daily users × 20 requests each = 200,000 a day. 200,000 ÷ 86,400 seconds ≈ 2.3 requests a second on average. Assume a peak of 10 times average unless you know better. That's about 23 a second, which one small server and database can usually handle.

**Storage:** 1,000 new records a day × 2 KB × 365 days ≈ 730 MB a year.

**Downtime allowed each year:**

| Availability | Downtime |
| --- | --- |
| 99% | about 3.7 days |
| 99.9% | about 8.8 hours |
| 99.99% | about 53 minutes |

Each extra nine costs far more than the last. Don't promise one without a requirement for it.

**Latency:** a user's wait is the sum of every step, so count the steps. As a rule of thumb, a memory read takes nanoseconds, a local SSD read takes microseconds, a network call within a data centre takes around a millisecond, and a call across continents takes 100 ms or more.

## Failure

Every part fails eventually. For each one, ask:

- **What happens if it stops, slows down or returns wrong answers?** Slow is often worse than stopped.
- **Is it a single point of failure,** and is that acceptable for the requirements?
- **Is a retry safe?** A retried action can run twice, so anything that retries needs idempotency.
- **How would you find out?** A failure nobody can see lasts longer.
- **How do you recover?** An untested backup may not work.

## Security

[security.md](security.md) holds the full rules: standards lookup, threat model, baseline, core controls, waivers and lifecycle minimums. In short:

- **Trust boundaries:** mark where data crosses from less trusted to more trusted. Validate it there.
- **Least privilege:** give each part only the access it needs.
- **Data:** encrypt it in transit and at rest. Collect and keep as little sensitive data as possible.
- **Secrets:** keep them out of code and images.
- **Identity:** use an established authentication provider or library. Never design your own cryptography.
- **Lifecycle:** plan for upgrades, diagnosis from logs and telemetry alone, and a developer mode that can't reach production.

## Cost

- Count the whole cost: hosting, licences, and the people who run it.
- For a product, spread one-off costs across units, such as engineering, certification and tooling. $50,000 ÷ 1,000 units = $50 a unit, before any parts.
- A managed service costs more per hour than self-hosting, but usually costs less overall for a small team.
- Check what grows with usage, such as per-request, per-token, data-transfer or per-unit costs.
- Look up the vendor's current pricing if you can. Don't use remembered prices, and say when you're estimating. If no vendor is chosen, use a sample price and name it. If you can't look it up, say so and label the figure as unverified.

## Glossary

- **ADR:** Architecture Decision Record, a short file that records one decision.
- **Availability:** the share of time a system works.
- **Background job:** work done outside a user's request.
- **Cache:** a fast copy of data, which adds the risk of serving stale data.
- **CISA:** the US Cybersecurity and Infrastructure Security Agency.
- **Component:** a separately running or deployed part of a system.
- **Consistency:** whether every reader sees the latest data. "Eventual" means they will, after a delay.
- **CWE:** Common Weakness Enumeration, a catalogue of software security weaknesses.
- **Deployable:** one unit you release on its own.
- **HSM:** hardware security module, a device that stores keys and uses them without exposing them.
- **Idempotent:** safe to run twice, with the same result as running once.
- **Latency:** how long one operation takes.
- **Load balancer:** a component that spreads requests across several servers.
- **Managed service:** one a provider runs for you, including updates and backups.
- **Monolith:** one deployable that holds the whole application.
- **OWASP:** the Open Worldwide Application Security Project, which publishes free security guidance.
- **Microservices:** many small deployables that talk over a network.
- **Queue:** a component that holds messages until a worker can process them.
- **Relational database:** one that stores data in linked tables, such as PostgreSQL.
- **Replica:** a copy of a database or service, for reliability or read capacity.
- **SBOM:** software bill of materials, a list of what a release contains.
- **SIEM:** security information and event management, a system that collects and analyses security logs.
- **Single point of failure:** one part that takes the whole system down when it fails.
- **Stateless:** keeps nothing on its own machine that you'd miss if it were replaced.
- **Threat model:** a list of what's worth protecting, who could harm it, how, and what stops them.
- **Throughput:** how many operations a system handles per second.
- **Trust boundary:** a point where data or control passes from less trusted to more trusted.
- **WAF:** web application firewall, a filter in front of a web app that blocks common attacks.
