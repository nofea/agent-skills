# AI and agent systems

Source: [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) and the [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/).

**What's different:** the same input can give different outputs, each call costs money and time, and text the model reads can act like instructions. Traditional tests can't fully show that it works, so evaluation is part of the architecture.

**Starting shape:** one model call with a clear prompt and structured output, inside ordinary code, plus a small evaluation set of real examples. Check the latest models, prices and limits in the provider's current documentation, because they change quickly.

## When to add more

| Stated requirement | Consider | Added cost |
| --- | --- | --- |
| The model needs facts it doesn't have | Retrieval, starting with database or keyword search | Keeping content fresh, access control |
| Keyword search misses relevant results in evaluation | Embeddings and vector search | Re-indexing, tuning, another store |
| A task divides into fixed steps | A chain of calls, with checks between them | More latency and cost |
| The steps can't be known in advance | One agent in a tool loop, with step and cost limits | Unpredictable cost, harder evaluation |
| Parts need separate tools, context or permissions | Multiple agents | Coordination, tracing, much harder debugging |
| Repeated requests or prompts drive up cost | Prompt or response caching | Stale answers, if responses are cached |

Use the first row that solves the problem, and try plain code first when the task doesn't need a model.

## Hard to reverse

- What data can be sent to a model provider, including retention and training terms
- What actions the system can take without human approval
- How tightly the system is bound to one provider's features
- The embedding model, because changing it means re-embedding everything
- The promises made to users about accuracy

## Common failures

- Building a multi-agent system when one call would do
- Shipping with no evaluation set, so nobody knows if a change helped
- Treating retrieved documents or web pages as trusted, which allows prompt injection
- Giving an agent broad tools, then relying on the prompt to restrict it
- No limit on steps or spend, so a loop becomes a large bill
- Trusting output format or content without validating it

## Review checks

- What's the evaluation set, and who updates it?
- What's the cost of one request at peak, and what's the monthly total?
- What happens on a timeout, a rate limit, or an outage at the provider?
- What's the worst action untrusted text could trigger? Is that enforced in code, outside the prompt?
- Which actions need human approval?
- Can you trace why the system produced a given result?
- Does retrieval respect each user's permissions?
