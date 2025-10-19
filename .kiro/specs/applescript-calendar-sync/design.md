# Design Document

## Overview

The AppleScript Calendar Sync system is designed as a standalone AppleScript application that synchronizes calendar events between two calendar accounts for the current day only. The system uses macOS Calendar app's AppleScript interface to read events from a source calendar and mirror them to a destination calendar, including removal of events that no longer exist in the source.

## Architecture

The system follows a simple pipeline architecture:

```
[Source Calendar] → [Event Reader] → [Event Processor] → [Destination Calendar]
                                          ↓
                                   [Duplicate Detector]
                                          ↓
                                   [Cleanup Manager]
```

### Core Components

1. **Calendar Manager**: Handles calendar account and calendar selection/validation
2. **Event Reader**: Retrieves events from source calendar for current day
3. **Event Processor**: Processes and transforms events for destination calendar
4. **Sync Engine**: Coordinates the synchronization process including cleanup
5. **Logger**: Provides user feedback and error reporting

## Components and Interfaces

### Calendar Manager
```applescript
-- Validates and retrieves calendar references
on getCalendar(accountName, calendarName)
on validateCalendarAccess(calendar)
on listAvailableCalendars()
```

**Responsibilities:**
- Validate calendar account and calendar names exist
- Return calendar object references for AppleScript operations
- Handle calendar access permissions and errors

### Event Reader
```applescript
-- Reads events from source calendar for current day
on getEventsForToday(sourceCalendar)
on parseEventProperties(event)
```

**Responsibilities:**
- Query source calendar for events occurring on current date
- Extract event properties (title, start time, end time, description, etc.)
- Handle different event types (all-day, timed, recurring)

### Event Processor
```applescript
-- Processes events for destination calendar
on createEventInDestination(eventData, destinationCalendar)
on updateExistingEvent(existingEvent, newEventData)
on compareEvents(event1, event2)
```

**Responsibilities:**
- Create new events in destination calendar
- Update modified events
- Compare events for duplicate detection

### Sync Engine
```applescript
-- Main synchronization coordinator
on performSync(sourceCalendar, destinationCalendar)
on cleanupRemovedEvents(sourceEvents, destinationEvents, destinationCalendar)
on generateSyncReport(results)
```

**Responsibilities:**
- Coordinate the entire sync process
- Manage event cleanup (removal of events not in source)
- Generate sync reports and statistics

### Logger
```applescript
-- Logging and user feedback
on logMessage(message, level)
on displayProgress(current, total)
on showSyncSummary(summary)
```

**Responsibilities:**
- Display progress information to user
- Log errors and warnings
- Show final sync summary

## Data Models

### Event Data Structure
```applescript
record EventData
    title: string
    startDate: date
    endDate: date
    isAllDay: boolean
    description: string
    location: string
    uid: string (for duplicate detection)
end record
```

### Sync Result Structure
```applescript
record SyncResult
    eventsCreated: integer
    eventsUpdated: integer
    eventsRemoved: integer
    eventsSkipped: integer
    errors: list of strings
end record
```

## Error Handling

### Error Categories
1. **Calendar Access Errors**: Invalid calendar names, permission issues
2. **Event Processing Errors**: Malformed events, property access failures
3. **Sync Operation Errors**: Network issues, calendar service unavailable

### Error Handling Strategy
- Graceful degradation: Continue processing other events when individual events fail
- Detailed error logging with specific error messages
- User-friendly error reporting with suggested solutions
- Rollback capability for critical failures

### Error Recovery
```applescript
on handleCalendarError(errorMessage)
    -- Log error details
    -- Provide user-friendly error message
    -- Suggest corrective actions
end handleCalendarError
```

## Testing Strategy

### Unit Testing Approach
Since AppleScript has limited testing frameworks, testing will focus on:

1. **Manual Testing Scenarios**:
   - Test with empty source calendar
   - Test with events spanning multiple days
   - Test with all-day events
   - Test with recurring events
   - Test calendar access errors

2. **Integration Testing**:
   - Test full sync workflow with real calendar data
   - Test cleanup functionality (event removal)
   - Test duplicate detection accuracy
   - Test error handling with invalid inputs

3. **Edge Case Testing**:
   - Very long event titles and descriptions
   - Events with special characters
   - Overlapping events
   - Events created/modified during sync

### Test Data Requirements
- Test calendars with known event sets
- Events with various properties (all-day, timed, recurring)
- Events with special characters and long descriptions
- Calendar accounts with different permission levels

## Implementation Considerations

### AppleScript Calendar Integration
- Use `Calendar` application's AppleScript dictionary
- Handle calendar app launch and focus management
- Manage calendar selection and event creation timing

### Performance Optimization
- Batch event operations where possible
- Minimize calendar app UI interactions
- Cache calendar references to avoid repeated lookups

### User Experience
- Provide clear progress indicators
- Show meaningful error messages
- Allow user to cancel long-running operations
- Display comprehensive sync results

### Security and Privacy
- Request calendar access permissions appropriately
- Handle sensitive calendar data securely
- Provide clear information about what data is accessed

## Configuration Management

### User Configuration
```applescript
-- Configuration properties
property sourceAccountName : "Work Account"
property sourceCalendarName : "Main Calendar"
property destinationAccountName : "Personal Account"
property destinationCalendarName : "Synced Events"
property enableLogging : true
```

### Runtime Configuration
- Allow users to modify calendar names without editing script
- Provide configuration validation before sync starts
- Save user preferences for repeated use