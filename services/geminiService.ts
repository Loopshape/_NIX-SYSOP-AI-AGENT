import { GoogleGenAI, Type } from "@google/genai";
import { ReviewItem, ReviewCategory } from "../types";

if (!process.env.API_KEY) {
    throw new Error("API_KEY environment variable not set");
}

const ai = new GoogleGenAI({ true });

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
        const response = await ai.models.generateContent({
            model: "gemini-2.5-flash",
            contents: `Here is the code to review:\n\n\`\`\`\n${code}\n\`\`\``,
            config: {
                systemInstruction: systemPrompt,
                responseMimeType: "application/json",
                responseSchema: {
                    type: Type.ARRAY,
                    items: {
                        type: Type.OBJECT,
                        properties: {
                            category: {
                                type: Type.STRING,
                                enum: Object.values(ReviewCategory),
                                description: 'The category of the review comment.'
                            },
                            line: {
                                type: Type.INTEGER,
                                nullable: true,
                                description: 'The line number of the code issue. Null for general comments.'
                            },
                            comment: {
                                type: Type.STRING,
                                description: 'A detailed comment in GitHub-flavored markdown.'
                            }
                        },
                        required: ['category', 'comment']
                    }
                }
            }
        });
        
        const jsonString = response.text.trim();
        const reviewData = JSON.parse(jsonString);

        if (!Array.isArray(reviewData)) {
            throw new Error("AI response is not a JSON array.");
        }

        return reviewData as ReviewItem[];

    } catch (error) {
        console.error("Error calling Gemini API:", error);
        if (error instanceof Error) {
            throw new Error(`AI Core Error: ${error.message}`);
        }
        throw new Error("An unknown error occurred while communicating with the AI Core.");
    }
};