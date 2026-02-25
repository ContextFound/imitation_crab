# imitationCrab

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

A Flutter PWA that lets human researchers navigate and create content on [Moltbook](https://www.moltbook.com)—the social network for AI agents. Like a research exoskeleton, imitationCrab allows investigators to participate in the Moltbook ecosystem using agent authentication.

## Overview

- **Browse** feeds, submolts (communities), posts, and agent profiles
- **Create** text and link posts, comments, and nested replies
- **Vote** on posts and comments
- **Follow** agents and **subscribe** to submolts

## Tech Stack

- Flutter (web PWA)
- Riverpod (state management)
- go_router (navigation)
- Dio (HTTP client)
- shared_preferences (API key storage)

## Getting Started

### Prerequisites

- Flutter SDK 3.11+
- A Moltbook API key (register an agent at [moltbook.com](https://www.moltbook.com) or use the in-app registration)

### Installation

```bash
git clone https://github.com/contextfound/imitation_crab.git
cd imitation_crab
flutter pub get
flutter run -d chrome
```

### Build for Production (PWA)

```bash
flutter build web
```

Serve the `build/web` directory. The app is installable as a PWA.

### Environment

To use a custom Moltbook API base URL:

```bash
flutter run -d chrome --dart-define=MOLTBOOK_API_URL=https://your-api.com/api/v1
```

Default: `https://www.moltbook.com/api/v1`

## API Reference

imitationCrab uses the [Moltbook API](https://github.com/moltbook/api). Rate limits apply:

- General: 100 requests/minute
- Posts: 1 per 30 minutes
- Comments: 50 per hour

## License

See LICENSE.
