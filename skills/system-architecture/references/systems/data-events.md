# Data and event systems

Source: *Designing Data-Intensive Applications* by Martin Kleppmann, [Enterprise Integration Patterns](https://www.enterpriseintegrationpatterns.com/) and the [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/).

**What's different:** data moves through stages over time, so the hard problems are lost, duplicated, late or out-of-order data, and the ability to reprocess it.

**Starting shape:** one scheduled batch job that reads from the source, keeps the raw input unchanged, transforms it and writes the result. Make each run idempotent, so running it twice for the same period gives the same result. Use the existing database if it can hold the volume.

## When to add more

| Stated requirement | Consider | Added cost |
| --- | --- | --- |
| Results must be fresher than a batch schedule allows | Smaller, more frequent batches first, then streaming | Streaming adds state and late-data handling |
| Jobs depend on each other and failures need retries | A workflow orchestrator | One more system to run |
| Several independent consumers need the same events | A log-based message broker | Schemas, consumer lag, operations |
| Analytical queries slow down the operational database | A separate warehouse or columnar store | A second copy of the data to keep in sync |
| Raw data exceeds what the database can hold | Files in object storage | Partitioning and file-format decisions |
| Volume exceeds what one machine can process | Distributed processing | Much harder debugging and much higher cost |

## Delivery guarantees

Most brokers deliver **at least once**, so a message can arrive twice. "Exactly once" usually holds only inside one system. Design consumers to be idempotent, for example by using a unique event ID and ignoring repeats.

## Hard to reverse

- Event and file schemas, once consumers depend on them
- Keys used for partitioning and ordering
- Whether raw input is retained, because lost data can't be reprocessed
- Retention periods, and any legal duty to delete personal data
- The definition of event time and how late data is handled

## Common failures

- Using streaming because it sounds modern, when an hourly batch would meet the requirement
- Discarding raw input, which rules out fixing a transform bug later
- Non-idempotent runs that double-count after a retry
- Schema changes that silently break downstream consumers
- Jobs that succeed with empty or partial input, because nothing checks the data
- No record of where a number came from

## Review checks

- How fresh does the data really need to be, and who says so?
- What happens if a run fails halfway, then runs again?
- What happens if a message arrives twice, late or out of order?
- Can you rebuild the output from raw input? How long would it take?
- Who's told when a schema changes?
- How do you find out that data stopped arriving?
- Is personal data retained only as long as allowed?
