import { generate } from "./generate.js";

const prompt = process.argv.slice(2).join(" ");
await generate(prompt);

