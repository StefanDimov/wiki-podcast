import OpenAI from "openai";
import fs from "fs";

const [INPUT_FILE_PATH, OUTPUT_FILE_PATH] = process.argv.slice(2);

if (!INPUT_FILE_PATH || !OUTPUT_FILE_PATH) {
  console.error("Usage: node generate.js <input-file> <output-file>");
  console.error("Example: node generate.js input.txt output/output.mp3");
  process.exit(1);
}

const openai = new OpenAI({
  baseURL: "http://localhost:8880/v1",
  apiKey: "not-needed" // Any placeholder string works
});

async function main() {
  const inputText = fs.readFileSync(INPUT_FILE_PATH, "utf-8");

  const response = await openai.audio.speech.create({
    model: "kokoro",
    voice: "af_bella",
    input: inputText,
    response_format: "mp3",
  });

  const writeStream = fs.createWriteStream(OUTPUT_FILE_PATH);

  // response.body is an async iterable stream
  for await (const chunk of response.body) {
    writeStream.write(chunk);
  }

  writeStream.end();
  console.log("Audio stream write completed.");
}

main().catch(console.error);
