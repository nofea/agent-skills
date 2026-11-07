# Other systems

Use this when no other guide fits. Examples include browser extensions, plugins and smart contracts. If you can look things up, find the type's own widely used guidance before proposing a shape, and follow it for anything this file doesn't cover. Say which source you used. If you can't, say you're relying on general knowledge.

Work out the shape from these questions:

- **What's different about this type?** Find what makes it hard, such as a browser's permission model or immutable code in a smart contract.
- **What's the smallest thing that does the core job?** Use one program and no network if the job allows it, and add a data store only if something must be kept. That's the starting shape.
- **What does the platform already provide?** Use it before adding anything.
- **What's hard to reverse here?** Look at data formats, public interfaces, anything already shipped, and platform lock-in.
- **Who controls where it runs?** If it's not you, plan for old versions and limited ability to fix things.

These apply everywhere:

- Each addition needs a stated requirement, or for a security component, a named threat or applicable control.
- Check what happens when each part fails, slows down or runs twice.
- Mark where untrusted data enters, and apply [security.md](../security.md), including the threat model and lifecycle minimums. Those minimums still apply if the type has no standard of its own.
- Work out how it's upgraded after release, how faults are diagnosed from logs and telemetry alone, and how developer mode stays out of production.
- Count the whole cost, including who runs it.
- If a system combines types, read each matching guide.
