import OpenAI from "openai";
import fs from "fs";

const INPUT_FILE_PATH = "input.txt";
const OUTPUT_FILE_PATH = "output.mp3";

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
    stream: true,
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
