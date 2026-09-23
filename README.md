# Wiki Podcast Generator

Generate podcasts on different subjects.

## Setup

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI, installed and logged in (`claude` on your `PATH`)
- Docker
- `jq` and `curl` (both ship with macOS 15+; on older versions run `brew install jq`)

### Kokoro docker container

Create the Kokoro container by following the Docker instructions on the [Kokoro-FastAPI GitHub page](https://github.com/remsky/Kokoro-FastAPI). Pick the CPU or GPU image that suits your machine.

The script expects that:

- the container is named `kokoro` (override with `KOKORO_CONTAINER` in `.env`)
- the API is exposed on port `8880` (override with `KOKORO_PORT` in `.env`)
- the Docker VM and container have >4g memory

The script starts and stops the container itself, so you can leave it stopped after creating it.

Only one podcast is generated at a time. If one is already in progress, a new run waits for it to finish. A lock left behind by a crashed run is cleaned up automatically.

### Settings

Copy `.env.example` to `.env` and set `PODCAST_DESTINATION` to the folder the generated podcasts should be moved to (e.g. your iCloud Podcasts folder).

Optionally, you can also override the Kokoro container name, port, voice and speed there. The defaults are listed in `.env.example`.

## Raycast

You can trigger podcast generation from [Raycast](https://www.raycast.com) using the script command in `raycast/`.

Setup (one time):

1. Open Raycast Settings → **Extensions** → **+** → **Add Script Directory**
2. Select the `raycast/` folder in this project

Usage:

1. Open Raycast and search for **Generate Podcast**
2. Press Tab, type the subject and press Enter

The podcast is generated in the background and a macOS notification is shown when it's done. Output is logged to `raycast.log`.
