# Wiki Podcast Generator

Generate podcasts on different subjects.

The project uses:

- https://github.com/remsky/Kokoro-FastAPI
- https://www.npmjs.com/package/openai

Note:

- Docker VM and container should have >4g memory

## Setup

Copy `.env.example` to `.env` and set `PODCAST_DESTINATION` to the folder the generated podcasts should be moved to (e.g. your iCloud Podcasts folder).

## Raycast

You can trigger podcast generation from [Raycast](https://www.raycast.com) using the script command in `raycast/`.

Setup (one time):

1. Open Raycast Settings → **Extensions** → **+** → **Add Script Directory**
2. Select the `raycast/` folder in this project

Usage:

1. Open Raycast and search for **Generate Podcast**
2. Press Tab, type the subject and press Enter

The podcast is generated in the background and a macOS notification is shown when it's done. Output is logged to `output/raycast.log`.
