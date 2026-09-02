"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var AiService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const hostels_service_1 = require("../hostels/hostels.service");
let AiService = AiService_1 = class AiService {
    constructor(config, hostelsService) {
        this.config = config;
        this.hostelsService = hostelsService;
        this.logger = new common_1.Logger(AiService_1.name);
    }
    async callClaude(system, messages, maxTokens = 200) {
        const apiKey = this.config.get('ANTHROPIC_API_KEY');
        if (!apiKey)
            return null;
        try {
            const res = await fetch('https://api.anthropic.com/v1/messages', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'x-api-key': apiKey,
                    'anthropic-version': '2023-06-01',
                },
                body: JSON.stringify({
                    model: 'claude-haiku-4-5-20251001',
                    max_tokens: maxTokens,
                    system,
                    messages: messages.map(m => ({
                        role: m.role === 'assistant' ? 'assistant' : 'user',
                        content: m.content,
                    })),
                }),
            });
            const data = await res.json();
            this.logger.log('Claude response: ' + JSON.stringify(data));
            return data.content?.[0]?.text || null;
        }
        catch (e) {
            this.logger.error('Claude API error', e);
            return null;
        }
    }
    async chat(req) {
        const apiKey = this.config.get('ANTHROPIC_API_KEY');
        if (!apiKey) {
            return { message: 'AI features are not configured yet. Please try again later.' };
        }
        try {
            const extractSystem = `You are a search parameter extractor for StayNest, a student hostel booking platform in Ghana. Extract search filters from the user message. Respond ONLY with a JSON object, no markdown, no backticks. Fields (all optional):
- "query": string (search text, e.g. hostel name or area)
- "maxPrice": number (max price in pesewas, 1 GHS = 100 pesewas)
- "minPrice": number (min price in pesewas)
- "roomType": string (one of: "1-in-a-room", "2-in-a-room", "3-in-a-room", "4-in-a-room")
- "amenities": string[] (e.g. ["wifi", "backup_power", "laundry"])
- "isConversational": boolean (true if the user is just chatting, not searching for hostels)

Price examples: GH\u20b5 2,000 = 200000 pesewas, GH\u20b5 3,000 = 300000 pesewas.
If the user says "under GH\u20b5 3,000" set maxPrice to 300000.
If purely conversational (greetings, thanks, off-topic), set isConversational to true and omit other fields.`;
            const extractText = await this.callClaude(extractSystem, [...req.history.slice(-6), { role: 'user', content: req.message }]);
            if (!extractText) {
                this.logger.warn('Claude unavailable, using keyword fallback');
                const fallbackParams = this.fallbackParse(req.message);
                this.logger.log('Fallback params: ' + JSON.stringify(fallbackParams));
                if (fallbackParams.isConversational) {
                    return { message: "I'm here to help you find hostels! Try asking something like \"Find me a hostel under GH\u20b53,000 near campus\"." };
                }
                const searchResult = await this.hostelsService.search({
                    q: fallbackParams.query,
                    maxPrice: fallbackParams.maxPrice,
                    minPrice: fallbackParams.minPrice,
                    roomType: fallbackParams.roomType,
                    sort: 'price_asc',
                    page: 1,
                    limit: 5,
                });
                const hostels = searchResult.data;
                const message = hostels.length > 0
                    ? "Here's what I found" + (fallbackParams.maxPrice ? ' under GH\u20b5' + (fallbackParams.maxPrice / 100).toLocaleString() : '') + ':'
                    : 'No hostels found matching those criteria. Try a higher budget or broader search.';
                return {
                    message,
                    hostels: hostels.map((h) => ({
                        id: h.id,
                        name: h.name,
                        pricePesewas: h.fromPricePesewas,
                        imageUrls: h.imageUrls || [],
                    })),
                };
            }
            let params;
            try {
                params = JSON.parse(extractText.replace(/```json?/g, '').replace(/```/g, '').trim());
            }
            catch {
                params = { isConversational: true };
            }
            if (params.maxPrice && params.maxPrice < 100000)
                params.maxPrice = params.maxPrice * 100;
            if (params.minPrice && params.minPrice < 100000)
                params.minPrice = params.minPrice * 100;
            this.logger.log('AI extracted params: ' + JSON.stringify(params));
            if (params.isConversational) {
                const chatText = await this.callClaude('You are StayNest AI, a friendly assistant for a student hostel booking platform in Ghana. Be concise, warm, and helpful. If the user asks something unrelated to hostels, gently guide them back. Keep responses under 3 sentences.', [...req.history.slice(-6), { role: 'user', content: req.message }]);
                return { message: chatText || "I'm here to help you find hostels!" };
            }
            const searchResult = await this.hostelsService.search({
                q: params.query,
                maxPrice: params.maxPrice,
                minPrice: params.minPrice,
                roomType: params.roomType,
                amenities: params.amenities,
                sort: 'price_asc',
                page: 1,
                limit: 5,
            });
            const hostels = searchResult.data;
            const hostelSummary = hostels.length > 0
                ? hostels.map((h, i) => `${i + 1}. ${h.name} - GH\u20b5${(h.fromPricePesewas / 100).toLocaleString()} (${h.location})`).join('\n')
                : 'No hostels found matching those criteria.';
            const responseText = await this.callClaude(`You are StayNest AI. The user searched for hostels and here are the results:\n${hostelSummary}\n\nSummarize the results naturally in 2-3 sentences. Mention the best match first. If no results, suggest broadening the search. Be warm and concise. Do NOT list prices or details - the app will show hostel cards below your message.`, [{ role: 'user', content: req.message }]);
            return {
                message: responseText || "Here's what I found:",
                hostels: hostels.map((h) => ({
                    id: h.id,
                    name: h.name,
                    pricePesewas: h.fromPricePesewas,
                    imageUrls: h.imageUrls || [],
                })),
            };
        }
        catch (err) {
            this.logger.error('AI chat error', err);
            return { message: 'Sorry, something went wrong. Please try again.' };
        }
    }
    fallbackParse(message) {
        const lower = message.toLowerCase();
        const params = {};
        const priceMatch = lower.match(/(?:under|below|less than|max|cheaper than|budget)[\s]*(?:gh[\u20b5c]?)?[\s]*(\d+(?:,\d{3})*)(k)?/);
        if (priceMatch) {
            let price = parseInt(priceMatch[1].replace(/,/g, ''), 10);
            if (priceMatch[2])
                price *= 1000;
            params.maxPrice = price * 100;
        }
        if (!params.maxPrice) {
            const simplePrice = lower.match(/(\d+(?:,\d{3})*)(k)?[\s]*(?:cedis|ghs|gh)?/);
            if (simplePrice && /cheap|afford|budget|price|cost|under|below/.test(lower)) {
                let price = parseInt(simplePrice[1].replace(/,/g, ''), 10);
                if (simplePrice[2])
                    price *= 1000;
                params.maxPrice = price * 100;
            }
        }
        if (/1[\s-]*in[\s-]*a[\s-]*room|single|1\s*bed|one.?bed/.test(lower)) {
            params.roomType = '1-in-a-room';
        }
        else if (/2[\s-]*in[\s-]*a[\s-]*room|double|2\s*bed|two.?bed/.test(lower)) {
            params.roomType = '2-in-a-room';
        }
        else if (/3[\s-]*in[\s-]*a[\s-]*room|triple|3\s*bed/.test(lower)) {
            params.roomType = '3-in-a-room';
        }
        else if (/4[\s-]*in[\s-]*a[\s-]*room|quad|4\s*bed/.test(lower)) {
            params.roomType = '4-in-a-room';
        }
        const queryMatch = lower.match(/(?:near|around|close to|at|in)\s+([\w\s]+?)(?:\s*(?:under|below|with|that|\.|,|$))/);
        if (queryMatch) {
            const q = queryMatch[1].trim();
            const stopWords = ['about', 'the', 'a', 'an', 'some', 'any', 'it', 'this', 'that'];
            if (!stopWords.includes(q))
                params.query = q;
        }
        if (/^(?:hi|hello|hey|thanks|thank you|bye|ok|okay|sure|yes|no|cool|great)\b/.test(lower) && !params.maxPrice && !params.roomType && !params.query) {
            params.isConversational = true;
        }
        return params;
    }
};
exports.AiService = AiService;
exports.AiService = AiService = AiService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService,
        hostels_service_1.HostelsService])
], AiService);
//# sourceMappingURL=ai.service.js.map