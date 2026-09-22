# Code and comments

## code style

When working on code, don't overengineer — align with the style the surrounding code is already written in. Don't add unnecessary comments that look AI-generated or ad-hoc (e.g. comments explaining a specific fix or prompt). If you comment, make it fit the repository's style and genuinely useful for a human to read.

## comments readable for humans

Write code comments the way a good human engineer would, structured for reading, not for compression:
- Short plain sentences. One idea per sentence. No dense clause-chains glued with em-dashes or nested parentheticals that need re-reading.
- Structure multi-step logic as a numbered/bulleted step list in the header comment, not as one long sentence.
- Helper functions get a one-line "what it does" plus a `Usage:` line; when the behavior is non-obvious (key transformations, formats), add a tiny concrete example.
- Explain each non-obvious statement in SQL/shell scripts — what it does and, when it matters, why (e.g. why a workaround is needed, what is deliberately skipped and why).
- Prefer everyday words over jargon ("safe to re-run" over "idempotent" when either works); don't name-drop docs/specs in every sentence — reference them once where it matters.
- Test: could a teammate who didn't write the code read the comment once and explain the block to someone else? If not, simplify.

## PR comments: the bar they must clear

Whenever a change adds, rewrites, or trims **comments in the code** — or writes the PR description — the wording must clear the bar below. Write it yourself by default.

Offer the comment-editor agent when the wording carries real weight: a header comment explaining a mechanism, a helper others will call, a constraint someone could "fix" and break. The author of a change is the worst editor of its comments — you know why every line exists, so you write for yourself, you preserve detail you happen to remember, you narrate the fix you just made, and you cannot see what a stranger would fail to understand. A fresh agent reads the code the way the next engineer will, with no memory of the conversation that produced it.

**Who to write for:** a competent engineer who has never seen this code, was not in the discussion, and does not know the history must be able to read the comment once and explain the block to someone else. Write for that person, not for the reviewer of this PR and not for yourself.

**What comments are for, in priority order:**
1. What this exists for — the job it does in the system.
2. How it fits the architecture — who calls it, what contract it upholds, what breaks elsewhere if it changes. Name the other components by their real names.
3. The non-obvious constraint — the thing a reader would otherwise "fix" and thereby break: an ordering requirement, a failure mode, a platform quirk, a compatibility window. State it once, plainly, with the reason.
4. Anything else is minutia and should be deleted. The code already says what it does line by line.

**What must go:** narration of the change ("now also handles X", "previously this used Y"), restating the next statement in English, defensive hedging, exhaustive enumerations of cases the code already enumerates, and any sentence that only makes sense to someone who followed the conversation that produced the edit. A comment is part of the artifact, not a record of how it was written.

**Don't re-explain what the team already knows.** A comment must not re-teach an established mechanism of the codebase — a convention, layout, or workflow the team works with daily, or one documented in a central place (README, design doc, the mechanism's own header). The author of a change is over-focused on the corner they just touched and tends to word out the whole surrounding machinery; the reader is a teammate who already knows that machinery. Explain only what is local and non-obvious at THIS spot; for shared background, at most one short pointer to where it's documented — never a paraphrase of it. Test: would a teammate who works in this repo every day learn anything from the sentence? If not, cut it.

**The first option is always NO comment.** For every comment, start from the assumption that it should not exist, and let it in only when the code truly cannot carry the meaning itself. Do not intrude comments everywhere: an uncommented block is the normal, healthy state of readable code, not a gap to fill. When a comment does survive, default to short — a few plain lines unless something genuinely needs more. Before keeping a multi-paragraph comment, justify why each paragraph is necessary at this spot; when in doubt, shorten or drop it. Long header essays are a defect even when every sentence is true.

**Every comment must earn its place — verify value, not just wording.** For each comment in the diff, ask: without this comment, would a competent reader actually struggle to understand what the code is doing? Keep it only when it explains a block with real functionality weight or a genuinely non-obvious constraint. If it is minutia, or relevant only in the context of this PR, drop it entirely — do not rewrite it, delete it. LLM-authored changes have a known failure mode of assigning significance to every little detail they touch, like a nerd in the bad sense; the result is a comment on every third line and a littered codebase. A small change does not deserve a comment per piece — the default for a small, readable edit is NO new comments at all. When the comment-editor agent runs, its report states per comment keep / rewrite / delete with a one-line reason, and "delete" must be a common verdict, not an exception.

**Style:** short plain sentences, one idea each. Multi-step logic becomes a numbered list in a header comment, never one long clause-chain. Helpers get a one-line "what it does" plus a `Usage:` line, and a tiny concrete example when a format or transformation is non-obvious. Everyday words over jargon. Match the density and voice of the surrounding file — a comment that reads as machine-written is a defect even when accurate.

Brief the comment-editor agent properly: it starts cold. Give it the repo path, the exact diff to work on, what the change is for, who reads this code, the repo's comment conventions, and an explicit instruction to change comments and docstrings ONLY — never code, never behavior. Ask it to return concrete replacements, and to say plainly where a comment should simply be deleted. Then read what it returns and apply it yourself; you own the result, so drop anything it got factually wrong about the code.
