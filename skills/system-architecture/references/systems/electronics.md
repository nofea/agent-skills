# Electronics

Source: *The Art of Electronics* by Paul Horowitz and Winfield Hill, and each part's manufacturer datasheet.

Read this with [embedded.md](embedded.md). Apply the safety rule in [SKILL.md](../../SKILL.md#safety-and-legal-duties) to mains voltage, lithium batteries, high current and anything that could cause harm.

**Scope:** stay at architecture level. Produce block diagrams, power trees, part requirements with named examples, interface choices, budgets, supply-risk notes and board test plans.

**Don't produce** schematics, circuit component values, pin assignments, PCB layouts or manufacturing files. Errors there can look correct and still damage hardware, so leave them to an electronics engineer. Requirements are fine, such as a battery's capacity, a sensor's accuracy or a rail's estimated current. Leave ratings for safety parts, such as fuses and protection, to the engineer. Treat every part you name as an example, and tell the user to check it against the current datasheet, including its availability.

**Starting shape:** an off-the-shelf development board, with parts connected on a bench and no custom PCB. This proves the idea, and a shipped product may need more. A user's request for a PCB isn't a need by itself, so ask what it's for. A **pre-certified radio module** avoids much of the radio design and part of the certification work. Move to a custom board only with a stated need.

## When to add more

| Stated requirement | Consider | Added cost |
| --- | --- | --- |
| Size, cost, volume or power rules out development boards | A simple carrier board for a module, then a full custom PCB | Design, bring-up and revisions |
| Unit cost dominates at high volume | Discrete radio or integrated parts | Certification and RF expertise |
| Battery life target can't be met | Lower-power parts, a sleep strategy, a larger battery | Cost, size, wake-up time |
| The environment is harsh | Rated parts, enclosure and protection | Cost and testing |
| A single part is at supply risk | A pin-compatible or second-source alternative | More validation |

## Block diagrams and power trees

- **Block diagram:** show the processor, memory, sensors, actuators, radios and connectors, labelling each link with its interface.
- **Power tree:** show each source and regulator, and each rail with its voltage and estimated current. Include startup and peak current, as well as the average.
- Use Mermaid for both, and include them in the overall shape for any hardware you're building yourself. Off-the-shelf products don't need them.

## Lithium batteries

Always apply the safety rule. Raise these points in any battery decision, and have a qualified engineer confirm them:

- Cells need a protection circuit, and a charger made for that exact chemistry.
- Heat and sealed enclosures raise the risk, and many cells mustn't be charged below freezing.
- Shipping lithium cells is regulated.

## Choosing interfaces

| Interface | Typical use | Watch for |
| --- | --- | --- |
| I²C | Slow sensors on a shared two-wire bus | Short distances, address conflicts |
| SPI | Faster parts such as displays and flash | Needs more wires |
| UART | Simple point-to-point links, debug | Two devices per link |
| CAN | Reliable links in electrically noisy systems | Needs a transceiver |
| USB | Connection to a computer | Protocol complexity, certification for branding |
| Ethernet | Fast, reliable wired networks | Cost, space, power |

## Hard to reverse

- The processor, radio and any single-source parts
- Power architecture and battery chemistry
- Connectors and the physical form factor
- Anything needing certification, because changes can force retesting
- Enclosure and tooling, once paid for

## Common failures

- Designing a custom board before proving the idea on a development board
- Forgetting peak current, such as a radio transmitting, which can reset the device
- Choosing a part with a long lead time or a planned end of life
- No test points or debug access on the first board
- Debug access left open on production units
- Leaving certification, such as FCC or CE, until the end
- Assuming a sensor's headline accuracy holds across temperature

## Review checks

- Is each named part confirmed against its current datasheet and availability?
- Does the power tree cover peak current, with margin?
- Is there a second source for each high-risk part?
- How will each board be programmed and tested in production, and how is debug access locked afterwards?
- If keys are stored on the device, does the hardware protect them?
- Which certifications apply, and what's their cost?
- Does the bill of materials meet the target unit cost at the planned volume?
- Has a qualified engineer been named for anything covered by the safety rule?
