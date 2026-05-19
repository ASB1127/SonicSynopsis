# SonicSynopsis

SonicSynopsis is an iOS app that turns spoken audio into structured notes. The app records audio locally, transcribes it with Apple's Speech framework, stores transcripts on-device, and generates AI summaries through Google's Gemini API.

This project was built as an end-to-end productivity product rather than a single-model demo. It covers the full workflow from capture to transcription to summarization, plus the file management needed to make the output usable inside the app.

## What It Does

- Records audio directly in the app using `AVFoundation`
- Stores recordings locally as `.m4a` files
- Transcribes saved recordings with `Speech`
- Persists transcripts and summaries as structured files in the app's documents directory
- Generates concise note-style summaries from transcripts using `GoogleGenerativeAI`
- Lets users rename, review, replay, and delete recordings, transcripts, and summaries

## Product Flow

1. Record audio in the `Record` tab.
2. Save the audio file locally in the app sandbox.
3. Swipe on a recording to transcribe it.
4. Store the transcription as a serialized text object.
5. Open the `Manage Transcriptions` tab to review or rename transcripts.
6. Generate an AI summary from any transcript.
7. Open the `Manage Summaries` tab to review, rename, or delete summaries.

## Architecture

### Core Components

- `ContentView.swift`
  - Main app flow for recording, playback, local file discovery, and transcription triggers
- `ManageTranscriptionsView.swift`
  - Transcript management, summary generation, and transcript persistence helpers
- `ManageSummariesView.swift`
  - Summary browsing, editing, and file lifecycle management
- `EditFileNamesView.swift`
  - Renaming flow for saved recordings
- `Router.swift`
  - Shared tab routing state

### Main Technologies

- `SwiftUI` for the app UI
- `AVFoundation` for recording and playback
- `Speech` for speech-to-text transcription
- `GoogleGenerativeAI` for summary generation
- Local file storage in the iOS documents directory for recordings, transcripts, and summaries

### Data Model

The app uses a lightweight `textobj` model to store generated artifacts:

- `name`
- `content`

Transcripts are saved with the `.transcription` extension and summaries are saved with the `.summary` extension. This keeps the app simple while still making generated outputs persistent and manageable.

## Engineering Highlights

- Built an end-to-end native iOS workflow instead of an isolated AI feature
- Combined local device capabilities with external LLM inference in a single UX
- Implemented asynchronous transcription and summarization flows
- Added file lifecycle operations for rename, delete, playback, and review
- Structured the app around multiple content states: raw audio, transcript, and summary

## Setup

### Requirements

- Xcode 15+
- iOS simulator or physical iPhone
- A Gemini API key

### Run Locally

1. Clone the repository.
2. Open `SonicSynopsis.xcodeproj` in Xcode.
3. Add your Gemini API key to `GenerativeAI-Info.plist` under `API_KEY`.
4. Build and run the app.

## Permissions

The app requires:

- Microphone access for recording
- Speech recognition access for transcription
