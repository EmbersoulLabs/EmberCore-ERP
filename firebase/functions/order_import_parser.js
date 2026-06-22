const functions = require("firebase-functions");
const { GoogleGenerativeAI } = require("@google/generative-ai");

const ORDER_IMPORT_SCHEMA = {
  type: "object",
  properties: {
    orderId: { type: "string" },
    clientName: { type: "string" },
    recipientName: { type: "string" },
    phone: { type: "string" },
    address: { type: "string" },
    postalCode: { type: "string" },
    region: { type: "string" },
    deliveryTimeSlot: { type: "string" },
    cardMessage: { type: "string" },
    deliveryDate: {
      type: "string",
      description: "ISO date YYYY-MM-DD when known",
    },
    orderType: {
      type: "string",
      description: "Delivery, PickUp, or Retail",
    },
    productHint: { type: "string" },
    productPrice: { type: "number" },
    needsReferencePhoto: { type: "boolean" },
  },
};

function readGeminiApiKey() {
  return (
    process.env.GEMINI_API_KEY ||
    functions.config().gemini?.api_key ||
    ""
  );
}

function buildPrompt(rawText, context = {}) {
  const industry = context.industryKey || "generic";
  const orderPrefix = context.orderIdPrefix || "EC";
  return `You extract structured order fields from staff-pasted chat or order messages.

Rules:
- Singapore/Malaysia context: phones are often 8 digits starting with 8 or 9.
- Dates: prefer YYYY-MM-DD. Accept DD/MM/YYYY or "17Jun" style and normalize.
- orderType: Delivery (delivery/送/on site/field service), PickUp (pickup/自取), Retail (walk-in/零售).
- orderId: patterns like ${orderPrefix}-JUN26-0001 or legacy TFG-* if present.
- cardMessage: greeting card / service notes / special instructions.
- productHint: main product or service description in one line.
- needsReferencePhoto: true if text mentions 如图, photo, reference image, or attach picture.
- Use null for unknown fields. Do not invent data.
- Industry preset: ${industry}.

Message:
${rawText}`;
}

function sanitizeParsedObject(raw) {
  if (!raw || typeof raw !== "object") {
    return {};
  }
  const out = {};
  const stringKeys = [
    "orderId",
    "clientName",
    "recipientName",
    "phone",
    "address",
    "postalCode",
    "region",
    "deliveryTimeSlot",
    "cardMessage",
    "deliveryDate",
    "orderType",
    "productHint",
  ];
  for (const key of stringKeys) {
    const value = raw[key];
    if (typeof value === "string" && value.trim()) {
      out[key] = value.trim();
    }
  }
  if (typeof raw.productPrice === "number" && Number.isFinite(raw.productPrice)) {
    out.productPrice = raw.productPrice;
  }
  if (typeof raw.needsReferencePhoto === "boolean") {
    out.needsReferencePhoto = raw.needsReferencePhoto;
  }
  return out;
}

async function parseOrderMessageWithGemini(rawText, context = {}) {
  const apiKey = readGeminiApiKey();
  if (!apiKey) {
    throw new Error(
      "GEMINI_API_KEY is not configured. Set firebase functions:config:set gemini.api_key=...",
    );
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: "gemini-2.0-flash",
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: ORDER_IMPORT_SCHEMA,
      temperature: 0.1,
    },
  });

  const result = await model.generateContent(buildPrompt(rawText, context));
  const text = result.response.text();
  if (!text || !text.trim()) {
    throw new Error("Gemini returned an empty response");
  }
  return sanitizeParsedObject(JSON.parse(text));
}

module.exports = {
  parseOrderMessageWithGemini,
  sanitizeParsedObject,
};
