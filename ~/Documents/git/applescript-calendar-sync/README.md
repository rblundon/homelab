# AppleScript Calendar Sync

An AppleScript utility that synchronizes calendar events between two calendar accounts for the current day.

## Overview

This script reads events from a source calendar and mirrors them to a destination calendar, including removal of events that no longer exist in the source. It's designed to keep two calendars in sync automatically.

## Features

- Synchronizes events for the current day only
- Configurable source and destination calendars
- Comprehensive logging and error handling
- Progress tracking and user notifications
- Handles event creation, updates, and removal

## Configuration

Edit the configuration properties at the top of `calendar-sync.applescript`:

```applescript
property sourceAccountName : "Work Account"
property sourceCalendarName : "Main Calendar"
property destinationAccountName : "Personal Account"
property destinationCalendarName : "Synced Events"
property enableLogging : true
property enableDebugMode : false
```

## Usage

1. Configure the source and destination calendar settings
2. Run the script using Script Editor or from the command line with `osascript`
3. The script will sync today's events and display a summary

## Documentation

The `docs/` directory contains the complete specification:

- `requirements.md` - Detailed requirements and user stories
- `design.md` - Technical design and architecture
- `tasks.md` - Implementation plan and task breakdown

## Development Status

This project is currently in development. See `docs/tasks.md` for the current implementation progress.

## Requirements

- macOS with Calendar app
- AppleScript support
- Access to both source and destination calendar accounts