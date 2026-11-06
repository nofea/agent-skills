# Services and web apps

Source: [The Twelve-Factor App](https://12factor.net/), the [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/), [Site Reliability Engineering](https://sre.google/sre-book/table-of-contents/), [MonolithFirst](https://martinfowler.com/bliki/MonolithFirst.html) *Designing Data-Intensive Applications* by Martin Kleppmann, the [OWASP Top 10](https://owasp.org/Top10/), [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/) and the [OWASP API Security Top 10](https://owasp.org/API-Security/).

**What's different:** many users share one system over a network, so most hard problems come from shared data and concurrent requests.

**Starting shape:** one deployable, with clear modules inside it, and one managed relational database. Add automated backups, and keep servers stateless, so sessions and files don't live on one machine. This handles far more traffic than most projects reach.

## When to add more

| Stated requirement | Consider | Added cost |
| --- | --- | --- |
| Measured slow queries remain after indexing and query fixes | A read replica, or a cache for read-heavy data | Stale data and invalidation |
| Work takes too long to do during a request, such as sending email | A background job, using the database as a queue at first | Retries and duplicate work |
| Job volume or spikes exceed what the database queue handles | A dedicated queue | One more system to run |
| Uptime target can't survive one server failing | Two or more servers behind a load balancer | Deploys and sessions need more care |
| Users upload large files | Object storage, with no files in the database | Access control on stored files |
| Full-text search outgrows database search | A search engine | Keeping a second copy of data in sync |
| Separate teams block each other, or one part needs very different scaling | Extract one service | Network failures, versioning, more operations |

## Security and lifecycle

Apply [security.md](../security.md). For this type:

- **Threats:** broken access control, injection, stolen sessions or credentials, one tenant reaching another's data, and abuse of public endpoints
- **Maintenance:** upgrades that run alongside the old version, automated dependency and base image updates, and certificate and secret rotation without downtime
- **Diagnostics:** structured logs and traces with a correlation ID across each request, and error tracking tagged with the release. Nobody opens a shell on a production server. Data repairs run as reviewed migrations
- **Developer mode:** local environment with seeded fake data. Test logins and auth bypasses are excluded from production builds

## Hard to reverse

- The data model and tenant isolation, if you serve several customers
- How authorization is modelled, because checks spread through every feature
- Public API shapes and versioning
- User identity and how accounts are stored
- Which database engine you use
- Which regions hold user data, if data residency applies

## Common failures

- Splitting into microservices before a team or scaling need exists
- Several services sharing one database, which couples them without the benefits of a monolith
- Calling another service during a request with no timeout
- Migrations that lock a busy table or can't run alongside the old code
- Retried payments or orders running twice, because the action isn't idempotent
- Backups that have never been restored
- Authorization checked in the UI, but not on the server
- Admin or debug endpoints left reachable in production

## Review checks

- Does each component trace to a stated requirement?
- What happens if the database is down for five minutes?
- Do outbound calls have timeouts and safe retries?
- Can you deploy without downtime, and roll back?
- Have backups been restored in a test?
- Can one customer ever see another customer's data?
- Is there monitoring on errors, latency and saturation?
- Is every endpoint authenticated and authorized by default?
- Can a fault be diagnosed from logs and traces, with no production shell?
- How fast can a fix or dependency patch reach production?
