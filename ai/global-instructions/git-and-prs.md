# Git branches and pull requests

## create PRs as drafts by default

Whenever you create a pull request on a remote (GitHub, Azure DevOps, GitLab, etc.), open it as a **draft** unless I explicitly ask for a ready-for-review / non-draft PR. Use the platform's draft flag (e.g. `gh pr create --draft`, Azure DevOps draft PR, GitLab draft/WIP). Do not mark a draft PR ready for review unless I ask.

## branch names carry the ticket ID

In any repo whose project tracks work in tickets, the branch name must name the ticket the work belongs to: `<type>/TICKET-123-short-description`. Do not push a ticketless branch because CI merely warns — a rename after the PR exists means abandoning that PR and opening a new one. Find the ticket before you push (in MigVisor: `ai/epam/jira.sh jql '...assignee = currentUser()...'`), and when nothing fits, ask me instead of guessing. The description part stays short and plain-language; the ticket ID belongs in the branch only, never in the PR title.

Pick the branch *type* from what the repo's remote actually holds (`git ls-remote --heads origin`, group by the first path segment), not from what the validator tolerates — a prefix that merely passes CI can still be one the team never uses. In the MigVisor Explainer repos that means `feat/`, `fix/`, `hotfix/`, `refactor/`; never `ci/`, even for pipeline work.

## PR descriptions: short and bulleted

Keep PR descriptions small. When the change has several distinct parts, use a short bullet list — one bullet per part, each stating what was done and what it brings; a single-purpose change gets 1–3 plain sentences instead. No exhaustive file-by-file walkthroughs, no restating the diff, no background story of how the change was developed. When a claim in the description rests on external documented behavior (an upstream API, a documented limitation or rule, a vendor recommendation), include the source link next to it — same sourcing standard as in replies, applied only where a reviewer would reasonably ask "says who?".

## never name teammates in shipped work

NEVER put a real person's name — teammate, reviewer, customer contact — into anything that leaves our private conversation: commit messages, branch names, PR titles and descriptions, PR comments and replies, code, code comments, docs, tickets, or chat messages drafted for others. Naming a colleague in shipped work is rude and unprofessional: it points at a person instead of the work.

I refer to people by name when I talk to you ("apply Hrysha's review notes", "do it like Pavlo did") — that is fine, and you may use names back to me in our private talk. When the work goes out, describe the substance instead of the person: `fix(shared-services): apply compose review notes`, not `apply Hrysha compose review notes`; "align with the existing dump workflow", not "do it like Pavlo". If a reference to someone's comment is truly needed, link the comment or thread itself. Before any commit, push, PR edit, or comment, check the text for names.
