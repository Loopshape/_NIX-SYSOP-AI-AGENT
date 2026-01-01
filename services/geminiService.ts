import { GoogleGenAI, Type } from "@google/genai";
import { ReviewItem, ReviewCategory } from "../types";

// Integration with NEXUS environment variables
const API_KEY = process.env.GEMINI_API_KEY || "";
const ai = new GoogleGenAI({ apiKey: API_KEY });

export const reviewCode = async (code: string, focusAreas: string[]): Promise<ReviewItem[]> => {
    const focusInstruction = focusAreas.length > 0
        ? `The user has requested to specifically focus on the following areas: ${focusAreas.join(', ')}. Prioritize your feedback on these aspects.`
        : 'Perform a comprehensive review covering all major aspects like bugs, security, performance, and style.';

    const systemPrompt = `You are an expert code reviewer. Analyze the provided code snippet and identify areas for improvement. Provide your feedback as a JSON array of objects.
${focusInstruction}

For each issue, provide:
- A "category" from the following enum: ${Object.values(ReviewCategory).join(', ')}.
- The "line" number where the issue occurs. If it's a general comment, use null.
- A concise "comment" explaining the issue and suggesting a fix. The comment should be in GitHub-flavored markdown.

Ensure your entire response is a single, valid JSON array.`;

    try {
        // Fallback to Gemini Pro as standard provider
        const modelName = "gemini-1.5-pro"; 
        const response = await ai.getGenerativeModel({ model: modelName }).generateContent({
            contents: [{ role: 'user', parts: [{ text: `Here is the code to review:\n\n\
```\
${code}
\
```\n` }] }],
            generationConfig: {
                responseMimeType: "application/json"
            },
            systemInstruction: systemPrompt
        });
        
        const jsonString = response.response.text().trim();
        const reviewData = JSON.parse(jsonString);

        if (!Array.isArray(reviewData)) {
            throw new Error("AI response is not a JSON array.");
        }

        return reviewData as ReviewItem[];

    } catch (error) {
        console.error("Error calling Gemini API:", error);
        throw new Error(error instanceof Error ? `AI Core Error: ${error.message}` : "Unknown error.");
    }
};
