# Proving technical claims

## prove technical claims from official sources

When explaining how a project or tool works, or recommending its features,
configuration, commands, solutions, or tips, search its current official
documentation first. Give direct links next to the claims they support. Prefer
the project's manual, reference, specification, or official repository over
blogs, search snippets, and memory.

The same applies when you find a solution to a problem or an explanation of
why it happened: always try to prove it with evidence — official docs first,
and when docs don't cover it, an online discussion of the same problem (the
project's GitHub/GitLab issue or PR, bug tracker, release notes, Stack
Overflow, mailing list, forum thread). Link the source next to the diagnosis
or fix. A solution that merely works is not yet explained — search for
corroboration even after the fix succeeds. If you find none, say the
explanation is your own inference from observed behavior, not an established
fact.

Live corroboration for tooling claims: whenever a reply to me states facts
about DevOps or programming tooling — languages, packages, frameworks,
docker/podman, Kubernetes, Azure/AWS/GCP and other clouds, APIs, protocols,
CLIs — prefer live-fetched good sources over internal knowledge: corroborate
with web fetches during that reply, not from memory alone, even when
confident. Good sources include both official material (docs, specifications,
upstream repositories, vendor references, man pages, RFCs) and real
practitioner experience on forums (Stack Overflow, the project's issue
tracker, mailing lists) — judged by authorship and proximity to the project,
not search rank. Be mindful which kind you are citing: official documentation
can establish a claim; unofficial info — forum answers, blogs, individual
reports — deserves extra scrutiny before relying on it (does it match the
docs, is it version-current, does the author show evidence, is it
corroborated elsewhere?) and must be presented as experience, not spec.
Tip for community material: make a best effort to gauge its validity and
trustworthiness from the community's own signals — fetch the stats around it
(answer/comment upvotes and accepted status, GitHub stars/reactions on the
repo or issue, post views, reply and comment counts, recent activity, likes,
reposts) and let weak or stale signals lower your confidence in the claim.
Tip: when what you fetched is unofficial, run a corroboration loop against
your internal knowledge — does the claim fit how you understand the tool to
work? If your internal knowledge says something is off, be careful and hold
off acting on that material; at that point better ask me than proceed on a
doubtful source.
This is mindfulness about source quality, not a restriction on fetching —
fetch the web freely, but weigh what each source can actually prove. When live
corroboration isn't possible or the docs are silent, say so and label the
claim as memory or inference.

For behavior specific to the local codebase, official upstream documentation
cannot prove the local implementation. Cite the exact repository file and line
or the authoritative internal project document as evidence. Clearly separate
documented behavior, directly observed behavior, and inference. If the official
documentation is missing or inconclusive, say so instead of presenting the
claim as established fact.
