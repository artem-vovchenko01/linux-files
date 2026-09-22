# Side agents and verification

## side agents: propose them, don't auto-run them

Spawn side agents freely when they do *work* for you — searching a codebase, exploring, scraping logs, running a prepared harness, bulk mechanical edits. That is your call and needs no permission.

Agents that *judge work you just did* — code reviewer, test agent, comment editor, architecture reviewer — are opt-in. Never launch them on your own. Instead, when you finish a change (a PR, a push, a sizeable edit), think about whether an outside pass is worth it, then say so in two or three lines: which agents you'd run, what each would hunt for, and why this change deserves it. I confirm, and only then you run them. When you judge the change too small to be worth anyone's time, say that instead and move on — a one-line "not worth verifying" is a good answer.

When I ask for a review, a tester, or a comment pass directly, that IS the confirmation — run it without asking again.

The sections below define how the reviewer, test, and architecture agents work when we do run one. The comment-editor agent and its bar live in `code-and-comments.md`.

## PR verification: reviewer and test agents

Verifier agents exist because you review your own work with your own blind spots — they hunt for what you missed from angles you didn't take. They run on request: mine, or yours with my confirmation. Nothing here fires by itself on a new PR or a push.

What to weigh when you judge whether to propose them: how much of the change is real behavior rather than text, how far a mistake would reach, whether it touches a contract other components rely on, and whether it has been tested already. A docs edit or a one-line config tweak needs nobody. A change to a data flow, a deploy path, or a shared interface usually earns both agents. Say which way you lean and why.

**Launch agents of your own model family** — Claude Code spawns Claude agents, Codex spawns Codex agents, and so on. Do NOT shell out to another vendor's CLI as reviewer (no `codex exec` from Claude, no `claude -p` from Codex) — cross-family adversaries are retired: they start cold, run minutes per round, and burn tokens without access to session context. Same-family subprocesses are fine: in Claude Code, verifiers run through `claude-alt -p` per `alt-accounts.md`.

**The two verifiers (run them in parallel when we run both):**
1. **Reviewer agent** — adversarial code review. Brief it cold and completely: repo path, the PR's **real target branch** (e.g. `dev`, not always `main`) and source branch, an instruction to review exactly `git diff <target>...HEAD`, the intent, the PR title/description, repo conventions, and the specific risks worth hunting (correctness, security, regressions, broken contracts). Ask for concrete file:line findings ranked by severity, and to say plainly if it finds nothing.
2. **Test agent** — contrive extensive tests for the changed behavior and RUN them: happy path, edge cases, and above all the specific failure the change claims to fix (show it fails before / passes after, where feasible). It must execute what it designs — in a scratch dir or throwaway worktree, never committing test artifacts — and report the commands, results, and evidence, not proposals. **Exception — no duplicate testing:** if I already had the change tested in the main thread this session (I asked for tests and they ran), skip this agent and say you skipped it because testing was already done.

**Model choice ("smartness") — always report it.** Verifier agents (reviewer and test agent alike) run on Opus 5 — do not spend the session's top model on them. In Claude Code they run headless on the alternate Pro account (`claude-alt -p`, see `alt-accounts.md`), falling back to native only when that account is unavailable. Every final report must name each verifier, the model it ran on, and which account it billed.

**Then close the loop — you own the outcome, not the verifiers:**
1. Never act on a finding you haven't verified yourself. Every finding or failing test is an unproven claim — verifiers misread intent, cite stale file:line locations, and produce confident false positives. Blindly applying their fixes just trades your blind spots for their hallucinations.
2. Verify each finding against primary evidence BEFORE touching any code: open the cited files/lines, confirm the failure mode is real (trace the code path, reproduce it, render the config — whatever proves it). Keep only what you independently confirmed; discard noise, style nits already covered by repo conventions, and misreadings of intent.
3. Act on what survives: fix it and push the update, then re-verify at most ONE more round on the updated diff. After that round, apply or record any remaining accepted nits without launching further rounds — no review ping-pong.
4. Tell me what the verifiers flagged, what you kept vs. rejected and why, what you changed, the test results, and which model each verifier ran on. Never hide a finding just because you decided not to act on it.

**A third agent — the architecture reviewer.** Propose it rarely, and only when the change is more than local: new components or abstractions, changed interfaces or data flows, anything touching how pieces of the system interact. Never for minutiae — a config tweak, a one-liner, mostly comments or docs. Its two jobs:
1. **Cohesion** — are the changes and additions actually needed and relevant, and do they fit the patterns and architecture the codebase already uses? A new addition that doesn't fit — duplicates an existing mechanism, fights the established style, or breaks existing features and functionality — should be flagged with the advice to drop it, however cool it is. "Advise not including it" is a valid and expected outcome.
2. **Architecture soundness** — map the architectural pieces this PR touches: what exists, which components are involved, how they interact, what contracts (interfaces, formats, protocols, invariants, consumers) the PR changes or depends on. Judge whether the resulting architecture is sound and call out any existing contract the change silently breaks.
Brief it cold like the other verifiers (repo path, branches, exact diff, intent) but point it wider than the diff: it must read the surrounding system, not just the changed lines. Judgment-critical, so it gets the session's strongest model. Its findings go through the same close-the-loop rules as the other verifiers.
