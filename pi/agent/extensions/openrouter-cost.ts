/**
 * OpenRouter Cost
 *
 * Re-prices OpenRouter usage against OpenRouter's own published pricing
 * (GET https://openrouter.ai/api/v1/models, public, no auth) instead of pi's
 * bundled catalog + pi.dev overlay.
 *
 * Why:
 *   - pi's catalog can be stale or missing a model entirely.
 *   - A model missing from pi's catalog falls back to the provider's *default*
 *     model rates (buildFallbackModel), so a valid OpenRouter request can be
 *     billed correctly by OpenRouter but estimated locally at unrelated rates.
 *   - OpenRouter also prices reasoning tokens (`internal_reasoning`) separately
 *     from output; pi folds reasoning into the output rate.
 *
 * How:
 *   - A module-level pricing cache is warmed on session_start (fire-and-forget,
 *     never blocking startup) and revalidated at most every CACHE_TTL_MS, plus
 *     a manual /or-cost-refresh command.
 *   - On each assistant message_end for the `openrouter` provider, the message's
 *     token buckets (input/output/cacheRead/cacheWrite, plus reasoning when the
 *     provider reports it) are re-priced against the cached OpenRouter rates and
 *     usage.cost.{input,output,cacheRead,cacheWrite,total} is replaced.
 *   - message_end only ever *reads* the cache (it may join an already-running
 *     warm fetch if the cache is still empty, but never starts a new request),
 *     so there is no per-message network round trip.
 *   - Non-openrouter messages, and openrouter messages without cached pricing,
 *     are returned untouched, so pi's own estimate still applies there.
 *
 * Limitations (v1):
 *   - Reasoning tokens are split out and priced at `internal_reasoning` only
 *     when the provider reports `completion_tokens_details.reasoning_tokens`
 *     in-stream; otherwise all output is priced at `completion` (pi's behavior).
 *   - Conditional pricing overrides are applied only for `min_prompt_tokens`
 *     and the daily UTC window; other future conditions are ignored.
 *   - Flat `request` and per-search `web_search` fees, and image/audio token
 *     rates, are not modeled (pi's usage has no such buckets; `request` is
 *     currently absent from OpenRouter anyway).
 *   - 1-hour cache-write tokens are priced at the default cache-write rate.
 *   - Only assistant messages are corrected; nested tool usage and
 *     compaction/branch summaries keep pi's estimate.
 *
 * Future enhancement (authoritative fallback):
 *   OpenRouter also exposes the exact per-request charge. Every response carries
 *   a generation id, which pi already stores on the assistant message as
 *   `responseId`; `GET /api/v1/generation?id=<gen_id>` (authenticated with the
 *   OpenRouter key) then returns `total_cost` for that request. If this catalog
 *   estimate ever proves inaccurate (flat/`web_search` fees, reasoning or media
 *   splits, routing quirks, overrides we don't model), `message_end` could look
 *   up `message.responseId` and overwrite `usage.cost.total` with OpenRouter's
 *   `total_cost`. That is fully authoritative but adds one authenticated request
 *   per assistant message, which is why this cache-based approach is used first.
 *
 * Install: place in ~/.pi/agent/extensions/ (auto-discovered, /reload-able)
 * or run: pi -e ./openrouter-cost.ts
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const MODELS_URL = "https://openrouter.ai/api/v1/models";
const CACHE_TTL_MS = 6 * 60 * 60 * 1000;
const FETCH_TIMEOUT_MS = 10_000;

// ---------------------------------------------------------------------------
// OpenRouter /models response shapes (subset we care about)
// ---------------------------------------------------------------------------

interface RawPricingOverride {
	min_prompt_tokens?: number | null;
	utc_start?: number | null;
	utc_end?: number | null;
	prompt?: string | null;
	completion?: string | null;
	internal_reasoning?: string | null;
	input_cache_read?: string | null;
	input_cache_write?: string | null;
}

interface RawPricing {
	prompt?: string | null;
	completion?: string | null;
	internal_reasoning?: string | null;
	input_cache_read?: string | null;
	input_cache_write?: string | null;
	overrides?: RawPricingOverride[] | null;
}

interface RawModel {
	id: string;
	canonical_slug?: string | null;
	pricing?: RawPricing | null;
}

// ---------------------------------------------------------------------------
// Normalized pricing
// ---------------------------------------------------------------------------

/** Prices in USD per token (OpenRouter returns them per-token, not per-1M). */
interface Pricing {
	prompt: number;
	completion: number;
	internalReasoning?: number;
	inputCacheRead?: number;
	inputCacheWrite?: number;
	overrides: PricingOverride[];
}

interface PricingOverride {
	minPromptTokens?: number;
	utcStart?: number;
	utcEnd?: number;
	prompt?: number;
	completion?: number;
	internalReasoning?: number;
	inputCacheRead?: number;
	inputCacheWrite?: number;
}

interface EffectiveRates {
	prompt: number;
	completion: number;
	internalReasoning: number;
	inputCacheRead: number;
	inputCacheWrite: number;
}

// ---------------------------------------------------------------------------
// Cache state
// ---------------------------------------------------------------------------

interface Cache {
	fetchedAt: number;
	/** Number of distinct models returned by /models (ids + canonical slugs both key the map). */
	modelCount: number;
	byModel: Map<string, Pricing>;
}

let cache: Cache | undefined;
let inflight: Promise<Cache> | undefined;
let warnedCacheFailure = false;
const warnedModels = new Set<string>();

function num(value: unknown): number {
	if (typeof value === "number") return Number.isFinite(value) ? value : 0;
	if (typeof value === "string") {
		const n = Number(value);
		return Number.isFinite(n) ? n : 0;
	}
	return 0;
}

function normalizePricing(raw: RawPricing | null | undefined): Pricing {
	const r = raw ?? {};

	const overrides: PricingOverride[] = (r.overrides ?? [])
		.filter((override): override is RawPricingOverride => !!override)
		.map((override) => {
			const o: PricingOverride = {};
			if (typeof override.min_prompt_tokens === "number") o.minPromptTokens = override.min_prompt_tokens;
			if (typeof override.utc_start === "number") o.utcStart = override.utc_start;
			if (typeof override.utc_end === "number") o.utcEnd = override.utc_end;
			if (override.prompt != null) o.prompt = num(override.prompt);
			if (override.completion != null) o.completion = num(override.completion);
			if (override.internal_reasoning != null) o.internalReasoning = num(override.internal_reasoning);
			if (override.input_cache_read != null) o.inputCacheRead = num(override.input_cache_read);
			if (override.input_cache_write != null) o.inputCacheWrite = num(override.input_cache_write);
			return o;
		});

	const pricing: Pricing = {
		prompt: num(r.prompt),
		completion: num(r.completion),
		overrides,
	};
	if (r.internal_reasoning != null) pricing.internalReasoning = num(r.internal_reasoning);
	if (r.input_cache_read != null) pricing.inputCacheRead = num(r.input_cache_read);
	if (r.input_cache_write != null) pricing.inputCacheWrite = num(r.input_cache_write);
	return pricing;
}

async function fetchPricing(): Promise<Cache> {
	const response = await fetch(MODELS_URL, { signal: AbortSignal.timeout(FETCH_TIMEOUT_MS) });
	if (!response.ok) {
		throw new Error(`OpenRouter /models returned HTTP ${response.status}`);
	}
	const payload = (await response.json()) as { data?: RawModel[] };

	const byModel = new Map<string, Pricing>();
	let modelCount = 0;
	for (const model of payload.data ?? []) {
		if (!model?.id) continue;
		modelCount++;
		const pricing = normalizePricing(model.pricing);
		byModel.set(model.id, pricing);
		if (model.canonical_slug) byModel.set(model.canonical_slug, pricing);
	}
	if (byModel.size === 0) {
		throw new Error("OpenRouter /models returned no models");
	}
	return { fetchedAt: Date.now(), modelCount, byModel };
}

/** Fetch (or join the in-flight fetch) and update the module cache. */
function refreshPricing(): Promise<Cache> {
	if (inflight) return inflight;
	inflight = fetchPricing()
		.then((next) => {
			cache = next;
			return next;
		})
		.finally(() => {
			inflight = undefined;
		});
	return inflight;
}

// ---------------------------------------------------------------------------
// Cost computation
// ---------------------------------------------------------------------------

/** True when an override's conditions match this request. */
function overrideApplies(override: PricingOverride, promptTokens: number, now: Date): boolean {
	if (override.minPromptTokens !== undefined && !(promptTokens > override.minPromptTokens)) {
		return false;
	}
	if (override.utcStart !== undefined || override.utcEnd !== undefined) {
		const hhmm = now.getUTCHours() * 100 + now.getUTCMinutes();
		const start = override.utcStart ?? 0;
		const end = override.utcEnd ?? 2400;
		if (start === end) return false;
		// Half-open window [start, end), wrapping past midnight when start > end.
		const inWindow = start < end ? hhmm >= start && hhmm < end : hhmm >= start || hhmm < end;
		if (!inWindow) return false;
	}
	return true;
}

/** Base pricing with applicable overrides applied (later overrides win per key). */
function effectiveRates(pricing: Pricing, promptTokens: number, now: Date): EffectiveRates {
	let prompt = pricing.prompt;
	let completion = pricing.completion;
	let internalReasoning = pricing.internalReasoning;
	let inputCacheRead = pricing.inputCacheRead ?? 0;
	let inputCacheWrite = pricing.inputCacheWrite ?? 0;

	for (const override of pricing.overrides) {
		if (!overrideApplies(override, promptTokens, now)) continue;
		if (override.prompt !== undefined) prompt = override.prompt;
		if (override.completion !== undefined) completion = override.completion;
		if (override.internalReasoning !== undefined) internalReasoning = override.internalReasoning;
		if (override.inputCacheRead !== undefined) inputCacheRead = override.inputCacheRead;
		if (override.inputCacheWrite !== undefined) inputCacheWrite = override.inputCacheWrite;
	}

	return {
		prompt,
		completion,
		// When a model has no separate reasoning rate, reasoning is billed at
		// the completion rate.
		internalReasoning: internalReasoning ?? completion,
		inputCacheRead,
		inputCacheWrite,
	};
}

interface CostBreakdown {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	total: number;
}

function computeCost(
	usage: { input: number; output: number; cacheRead: number; cacheWrite: number; reasoning?: number },
	rates: EffectiveRates,
): CostBreakdown {
	// reasoning is a subset of output (OpenAI/OpenRouter completion_tokens
	// already include it). Clamp in case a provider misreports.
	const reasoning = Math.min(Math.max(usage.reasoning ?? 0, 0), usage.output);
	const nonReasoningOutput = usage.output - reasoning;

	const input = usage.input * rates.prompt;
	const output = nonReasoningOutput * rates.completion + reasoning * rates.internalReasoning;
	const cacheRead = usage.cacheRead * rates.inputCacheRead;
	const cacheWrite = usage.cacheWrite * rates.inputCacheWrite;

	return {
		input,
		output,
		cacheRead,
		cacheWrite,
		total: input + output + cacheRead + cacheWrite,
	};
}

// ---------------------------------------------------------------------------
// Warnings
// ---------------------------------------------------------------------------

function warnCacheFailure(ctx: ExtensionContext): void {
	if (warnedCacheFailure) return;
	warnedCacheFailure = true;
	console.warn("openrouter-cost: OpenRouter pricing unavailable; keeping pi's cost estimates");
	if (ctx.hasUI) {
		ctx.ui.notify("OpenRouter pricing unavailable; keeping pi's cost estimates", "warning");
	}
}

function warnUnknownModel(ctx: ExtensionContext, modelId: string): void {
	if (warnedModels.has(modelId)) return;
	warnedModels.add(modelId);
	console.warn(`openrouter-cost: no OpenRouter pricing for "${modelId}"; keeping pi's cost estimate`);
	if (ctx.hasUI) {
		ctx.ui.notify(`No OpenRouter pricing for ${modelId}; keeping pi's estimate`, "warning");
	}
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
	pi.on("session_start", () => {
		// Warm the cache in the background. message_end joins this in-flight
		// fetch if the cache is still empty, so startup is never blocked.
		const stale = !cache || Date.now() - cache.fetchedAt >= CACHE_TTL_MS;
		if (stale) void refreshPricing().catch(() => {});
	});

	pi.on("message_end", async (event, ctx) => {
		const message = event.message;
		if (message.role !== "assistant" || message.provider !== "openrouter") return;

		// Never start a new request from message_end (keeps per-message latency
		// at zero); only join a warm fetch that is already running.
		if (!cache && inflight) {
			try {
				await inflight;
			} catch {
				// Warm failed; fall back to pi's estimate below.
			}
		}

		const byModel = cache?.byModel;
		if (!byModel) {
			warnCacheFailure(ctx);
			return;
		}

		const pricing =
			byModel.get(message.model) ??
			(message.responseModel ? byModel.get(message.responseModel) : undefined);
		if (!pricing) {
			warnUnknownModel(ctx, message.model || message.responseModel || "unknown");
			return;
		}

		const promptTokens = message.usage.input + message.usage.cacheRead + message.usage.cacheWrite;
		const cost = computeCost(message.usage, effectiveRates(pricing, promptTokens, new Date()));

		return {
			message: {
				...message,
				usage: {
					...message.usage,
					cost,
				},
			},
		};
	});

	pi.registerCommand("or-cost-refresh", {
		description: "Refresh the cached OpenRouter pricing and report model count",
		handler: async (_args, ctx) => {
			try {
				const next = await refreshPricing();
				const ageSeconds = ((Date.now() - next.fetchedAt) / 1000).toFixed(0);
				ctx.ui.notify(
					`OpenRouter pricing refreshed: ${next.modelCount} models (${ageSeconds}s ago)`,
					"info",
				);
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				ctx.ui.notify(`OpenRouter pricing refresh failed: ${message}`, "error");
			}
		},
	});
}
