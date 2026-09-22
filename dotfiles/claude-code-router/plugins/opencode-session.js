"use strict";

// OpenCode Go requires every request to carry a stable `x-opencode-session`
// header (one id per conversation) or its gateway answers 400 MissingSessionID.
// OpenCode sends it natively; claude-code-router does not, so we add it here.
//
// Usage:
//   1. Register this file in ccr's top-level `transformers` list:
//        "transformers": [{ "path": ".../opencode-session.js" }]
//   2. Add it to the opencode-go provider:
//        "transformer": { "use": ["opencode-session"] }
//
// The id must stay constant across the turns of one conversation so Go can
// reuse its prompt cache. Claude Code puts the conversation id in the
// Anthropic `metadata.user_id` field. If that is absent we hash the first
// message instead, and as a last resort use a per-process id.

const crypto = require("node:crypto");

class OpenCodeSession {
	constructor(options = {}) {
		this.name = "opencode-session";
		this.options = options;
		this.fallbackId = crypto.randomUUID();
	}

	async transformRequestIn(request, provider, context) {
		if (!request || typeof request !== "object") return request;
		return {
			body: request,
			config: {
				headers: { "x-opencode-session": this.resolveSessionId(context) },
			},
		};
	}

	resolveSessionId(context) {
		const body = context && context.req && context.req.body;
		const userId = body && body.metadata && body.metadata.user_id;
		if (typeof userId === "string" && userId) return userId;

		const messages = body && body.messages;
		if (Array.isArray(messages) && messages.length) {
			const seed = JSON.stringify(messages[0]);
			return crypto.createHash("sha256").update(seed).digest("hex").slice(0, 32);
		}

		return this.fallbackId;
	}
}

module.exports = OpenCodeSession;
