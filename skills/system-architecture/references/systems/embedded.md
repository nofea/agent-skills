# Embedded

Source: *Making Embedded Systems* by Elecia White, [RFC 9019: a firmware update architecture for IoT](https://www.rfc-editor.org/rfc/rfc9019) and [NIST IR 8259: IoT device cybersecurity](https://csrc.nist.gov/pubs/ir/8259/final).

Read [electronics.md](electronics.md) as well. For physical risk or regulated products, apply the safety rule in [SKILL.md](../../SKILL.md#safety-and-legal-duties) from the start.

**What's different:** software runs under fixed memory, power and timing limits, on hardware that's expensive to change and may be physically out of reach once shipped.

**Starting shape:** one microcontroller running one main loop with interrupts for urgent events, or a wake-work-sleep cycle on battery. Use no RTOS of your own, and no network unless the product's job needs one. Keep hardware access behind thin drivers, so logic can be tested on a computer. An **RTOS** (real-time operating system) schedules tasks and helps them meet deadlines. A vendor's radio software may use one internally, which doesn't mean your code has to. This is the shape for proving the idea. A shipped product may need more, and each addition still needs a requirement.

## When to add more

| Stated requirement | Consider | Added cost |
| --- | --- | --- |
| Several timing-critical activities conflict in one loop | An RTOS | Stack sizing, races, priority problems |
| The device needs complex networking, files or a display stack | Embedded Linux on an application processor | Boot time, power, cost, security updates |
| Hard real-time work must coexist with Linux | A separate microcontroller for that work | An inter-chip protocol, two firmware images |
| Devices need fixing after shipping | OTA updates, with a safe rollback | Bootloader, signing, double the flash in many designs |
| Data must reach a backend | The simplest fitting link, with a store-and-forward buffer | Backend: read [services-web.md](services-web.md) |
| Many devices need management | A device management service | Identity, provisioning, cost per device |

**OTA** (over-the-air) means updating devices through a network. **Store-and-forward** means saving data locally until the connection returns.

## Budgets

Set these early, with margin, because running out late can force a hardware change:

- **Timing:** deadlines, including the worst case
- **Memory:** flash and RAM, with room for updates and future fixes
- **Power:** average draw and battery life

Work out average current from each state. Example: awake for 3 seconds at 100 mA, once an hour, then asleep at 0.02 mA. Awake charge is 3 × 100 ÷ 3,600 ≈ 0.083 mAh an hour, and sleep adds about 0.02 mAh, so the average is about 0.1 mA.

Battery life: 2,000 mAh ÷ 0.1 mA ≈ 20,000 hours, or about 2.3 years on paper. Allow at least 30% less for temperature, ageing and self-discharge. Sending less often is usually the biggest saving, so check whether measuring and sending can happen on different schedules.

## Devices that act on the physical world

If a device switches a heater, motor, valve, lock or other load that could cause harm, apply the safety rule and settle this before other decisions:

- **Safe state:** what the device does on power loss, lost connection, a failed update or a crash
- **Remote action:** whether it can start when nobody's present
- **Limits:** a maximum run time and any interlocks, enforced on the device, not in the cloud or the app
- **Manual control:** whether a local control works with no network

A qualified engineer confirms these. Don't choose protection methods yourself.

## Hard to reverse

- The processor family and its toolchain
- The bootloader and the partition layout
- Device identity, keys and how they're provisioned
- Wire protocols and stored data formats in shipped devices
- Whether OTA exists at all, since it can't be added to devices already in the field. Always put this to the user as a decision, even if they didn't mention updates

## Common failures

- An OTA update that can brick a device, because there's no rollback
- Shared or hard-coded credentials across every device
- Unsigned firmware, or debug ports left open on production units
- A hung task with no watchdog reset
- A load left running after losing its connection
- Reasoning about average timing, when the worst case missed a deadline
- Flash wearing out because logs are written too often
- Assuming the connection and clock are always available

## Review checks

- What happens if power fails during an update or a write?
- Can every device be updated, and recovered, without physical access?
- What's the margin on timing, flash, RAM and power?
- Does each device have its own identity, and can it be revoked?
- What happens during a week without a connection?
- How do you learn about faults in the field?
- For any physical load, what's the safe state in each failure, and is it enforced on the device?
- Which safety, radio or product rules apply? Which need a qualified engineer?
