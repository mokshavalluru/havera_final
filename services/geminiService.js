const { GoogleGenerativeAI } = require("@google/generative-ai");

let genAI = null;
let model = null;

const initGemini = () => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY_HERE') {
    console.warn("⚠️  GEMINI_API_KEY is not set or is invalid. AI analysis will be skipped.");
    return;
  }
  
  genAI = new GoogleGenerativeAI(apiKey);
  // Using gemini-1.5-flash as it's fast and suitable for this task
  model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
  console.log("✅ Gemini API initialized");
};

/**
 * Analyzes an incident description using Google Gemini and returns severity, summary, and recommended actions.
 * @param {string} description The incident description
 * @returns {Promise<{severity: string, aiSummary: string, recommendedActions: string[]}>}
 */
const analyzeIncident = async (description) => {
  if (!model) {
    return {
      severity: "PENDING",
      aiSummary: "AI analysis unavailable (API key not configured).",
      recommendedActions: ["Contact emergency services manually."]
    };
  }

  const prompt = `
    You are an AI assistant for a hotel emergency response system. 
    Analyze the following emergency incident description and provide a JSON response.
    
    Incident Description: "${description}"
    
    Respond STRICTLY in the following JSON format without any markdown wrappers or additional text:
    {
      "severity": "LOW" | "MEDIUM" | "HIGH",
      "aiSummary": "A concise 1-2 sentence summary of the incident.",
      "recommendedActions": ["Action 1", "Action 2", "Action 3"]
    }
  `;

  try {
    const result = await model.generateContent(prompt);
    const responseText = result.response.text().trim();
    
    // Remove any markdown code block backticks if the model added them
    let cleanJsonStr = responseText;
    if (cleanJsonStr.startsWith("```json")) {
      cleanJsonStr = cleanJsonStr.replace(/^```json\n/, "").replace(/\n```$/, "");
    } else if (cleanJsonStr.startsWith("```")) {
      cleanJsonStr = cleanJsonStr.replace(/^```\n/, "").replace(/\n```$/, "");
    }

    const parsedResponse = JSON.parse(cleanJsonStr);
    
    return {
      severity: parsedResponse.severity || "MEDIUM",
      aiSummary: parsedResponse.aiSummary || "Unable to summarize.",
      recommendedActions: parsedResponse.recommendedActions || []
    };
  } catch (error) {
    console.error("❌ Error analyzing incident with Gemini:", error);
    return {
      severity: "PENDING",
      aiSummary: "Error occurred during AI analysis.",
      recommendedActions: ["Check on the guest immediately.", "Assess situation manually."]
    };
  }
};

module.exports = {
  initGemini,
  analyzeIncident
};
