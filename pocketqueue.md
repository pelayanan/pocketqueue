# Pocket Queue

## 1. App Title

**Pocket Queue — Simple Digital Queue Manager**

### Tagline
**“Take a number. Know your turn.”**

Pocket Queue is a lightweight Android application for small businesses, clinics, barbershops, repair shops, salons, government counters, and service desks that need a simple digital queue system without complicated POS or enterprise software.

The app works primarily offline and stores queue data locally on the device.

---

# 2. Core Concept

The application allows an operator to:

1. Create a service counter.
2. Configure queue categories.
3. Generate queue numbers.
4. Call the next customer.
5. Skip or recall a queue number.
6. Display the current queue.
7. Track completed and waiting customers.
8. View daily queue statistics.

Customers do not need to install the application.

The operator can simply show the Android device screen or connect the device to an external display.

---

# 3. Target Users

Primary users:

- Small clinics
- Dental clinics
- Barbershops
- Beauty salons
- Car workshops
- Motorcycle workshops
- Repair shops
- Restaurants with waiting queues
- Government service counters
- Pharmacy counters
- School administration offices
- Laundry businesses
- Small customer service desks

---

# 4. Platform

## Android

Recommended technology stack:

- **Language:** Kotlin
- **UI:** Jetpack Compose
- **Architecture:** MVVM
- **Database:** Room
- **Dependency Injection:** Hilt
- **Navigation:** Navigation Compose
- **State Management:** StateFlow
- **Build System:** Gradle Kotlin DSL
- **Minimum Android:** Android 8.0+
- **Target Android:** Latest stable Android SDK available during development

The application should be fully functional offline.

No backend is required for the MVP.

---

# 5. Branding

## App Name

**Pocket Queue**

## Logo Concept

Create a modern minimalist icon consisting of:

- A rounded square background.
- A large queue ticket represented by a small white ticket/card.
- The ticket contains the number **01**.
- A subtle queue line underneath the ticket.
- Small circular dots representing people waiting.
- Clean geometric shapes.
- No gradients that are overly strong.
- Professional but friendly appearance.

## Icon Style

The icon should communicate:

**Queue + Number + Simplicity**

Recommended visual style:

- Flat
- Minimal
- Modern
- High contrast
- Easily recognizable at 48dp and 24dp sizes

## Suggested Brand Colors

Primary:

`#2563EB`

Secondary:

`#0F172A`

Background:

`#F8FAFC`

Success:

`#16A34A`

Warning:

`#F59E0B`

Danger:

`#DC2626`

White:

`#FFFFFF`

---

# 6. Main Navigation

Use a simple bottom navigation or navigation rail depending on screen size.

Main sections:

1. **Queue**
2. **Display**
3. **History**
4. **Settings**

The Queue screen is the default screen.

---

# 7. Complete Application Workflow

## First Launch

### Step 1 — Welcome Screen

Show:

**Pocket Queue**

Text:

> Manage your customer queue quickly and easily.

Buttons:

**Get Started**

Secondary action:

**View Demo**

---

## Step 2 — Setup Business

Fields:

- Business Name
- Counter Name
- Operator Name

Example:

Business Name:

`Happy Smile Clinic`

Counter Name:

`Registration`

Operator:

`Reception Desk`

Button:

**Continue**

---

## Step 3 — Configure Queue

Allow the operator to configure:

### Queue Prefix

Examples:

- A
- B
- C
- REG
- PAY

### Starting Number

Default:

`001`

### Maximum Number

Default:

`999`

### Auto Reset

Options:

- Every Day
- Never
- Manual Reset

Button:

**Save Queue**

---

# 8. Home / Queue Screen

The main screen should immediately show the operational controls.

## Header

Display:

**Happy Smile Clinic**

Below:

**Registration Counter**

Top-right:

- Settings icon
- Fullscreen icon

---

## Current Queue Card

Large card:

**NOW SERVING**

# A-023

Below:

**Counter 1**

Buttons:

**Recall**

**Finish**

---

# 9. Queue Statistics

Show three compact cards:

### Waiting

`12`

### Served

`38`

### Skipped

`3`

Optional:

### Average Wait

`08:32`

---

# 10. Next Queue Section

Show:

**NEXT CUSTOMER**

Large number:

**A-024**

Button:

**CALL NEXT**

The CALL NEXT button should be the primary action on the entire screen.

---

# 11. Additional Controls

Buttons:

**Add Queue Number**

**Skip**

**Recall**

**Finish**

**Pause Queue**

**Reset Queue**

Actions should require confirmation when destructive.

---

# 12. Add Queue Number Workflow

When the operator taps:

**Add Queue Number**

Open a bottom sheet.

Display:

### Queue Type

Options:

- Regular
- Priority
- Appointment

### Quantity

Default:

`1`

Button:

**Generate Number**

Example result:

> Queue number A-024 created successfully.

Automatically return to Queue screen.

---

# 13. Call Next Workflow

The main operational workflow:

```text
Operator taps CALL NEXT
        ↓
Check waiting queue
        ↓
Get earliest waiting number
        ↓
Set status = SERVING
        ↓
Update current queue
        ↓
Play optional sound
        ↓
Display large queue number
        ↓
Start service timer
```

If there are no waiting customers:

Display:

**No customers waiting**

---

# 14. Finish Queue Workflow

Operator taps:

**FINISH**

Show confirmation:

> Finish service for A-023?

Buttons:

**Cancel**

**Finish Service**

After confirmation:

```text
A-023
↓
status = COMPLETED
↓
record completion timestamp
↓
calculate service duration
↓
remove from active queue
↓
prepare next queue
```

---

# 15. Skip Queue Workflow

Operator taps:

**SKIP**

Confirmation:

> Skip queue A-023?

After confirmation:

```text
A-023
↓
status = SKIPPED
↓
save skip timestamp
↓
move to history
↓
prepare next queue
```

---

# 16. Recall Workflow

Recall allows the operator to call the current queue again.

Workflow:

```text
Tap RECALL
↓
Play queue announcement
↓
Flash current queue number
↓
Update last_called_at
```

Optional sound:

> “Queue A twenty-three, please proceed to counter one.”

---

# 17. Digital Display Mode

The application should include a dedicated display mode for a TV, tablet, or monitor.

The operator taps:

**Display Mode**

The screen switches to fullscreen.

Layout:

```text
----------------------------------------
|          HAPPY SMILE CLINIC         |
|                                    |
|              NOW SERVING            |
|                                    |
|                 A-023              |
|                                    |
|              COUNTER 1              |
|                                    |
|       NEXT: A-024   A-025   A-026   |
|                                    |
----------------------------------------
```

The display should use extremely large typography.

---

# 18. Display Mode Features

Include:

- Current queue
- Counter
- Next 3 queue numbers
- Business name
- Current time
- Current date
- Optional animated transition
- Optional audio announcement
- Fullscreen mode

Settings:

**Show Clock**

**Show Date**

**Show Next Queues**

**Enable Sound**

**Animation**

---

# 19. Queue Announcement

Optional text-to-speech feature.

Example:

> “Queue A zero two three, please proceed to Registration Counter.”

Announcement settings:

- Enable / Disable
- Volume
- Voice
- Repeat Count

The application should avoid repeating announcements unnecessarily.

---

# 20. History Screen

Display daily history.

Example:

```text
TODAY

A-023     Completed     10:32
A-022     Completed     10:29
A-021     Skipped       10:25
A-020     Completed     10:21
```

Each item can be opened.

---

# 21. Queue Detail Screen

Display:

### Queue Number

**A-023**

### Status

**Completed**

### Created

10:14

### Called

10:26

### Started

10:27

### Completed

10:32

### Waiting Time

13 minutes

### Service Time

5 minutes

---

# 22. Daily Statistics

Provide summary:

- Total Generated
- Total Served
- Total Skipped
- Current Waiting
- Average Waiting Time
- Average Service Time
- Longest Waiting Time
- Busiest Hour

Visualize the data using simple charts.

Example:

```text
Customers Served

08:00  ███
09:00  █████
10:00  ████████
11:00  ██████
12:00  ███
```

---

# 23. Settings

Settings should contain:

## Business

- Business Name
- Logo
- Address
- Phone
- Opening Hours

## Queue

- Prefix
- Starting Number
- Number Length
- Reset Schedule
- Priority Queue
- Appointment Queue

## Display

- Fullscreen
- Theme
- Clock
- Date
- Next Queue Count
- Animation

## Sound

- Enable Voice
- Voice Language
- Volume
- Repeat Announcement

## Data

- Backup
- Restore
- Export CSV
- Delete History
- Reset Application

---

# 24. Theme

Support:

- Light Mode
- Dark Mode
- System Default

The Queue operation screen should prioritize visibility and readability over decorative design.

Use large buttons and large numbers.

---

# 25. Responsive UI

The UI must support:

- Small phones
- Large phones
- Tablets
- Landscape orientation
- External display scenarios

On phones:

Use stacked cards.

On tablets:

Use a two-column layout.

On landscape displays:

Use:

```text
LEFT
Current Queue

RIGHT
Next Queue + Controls
```

---

# 26. Data Model

Use Room Database.

## BusinessSettings

Fields:

```text
id
businessName
counterName
operatorName
logoUri
address
phone
createdAt
updatedAt
```

## Queue

Fields:

```text
id
queueNumber
prefix
queueType
status
createdAt
calledAt
startedAt
completedAt
skippedAt
serviceDuration
waitingDuration
counterName
priority
notes
```

Possible statuses:

```text
WAITING
SERVING
COMPLETED
SKIPPED
CANCELLED
```

## QueueSettings

Fields:

```text
id
prefix
startingNumber
maxNumber
numberLength
resetMode
lastNumber
enablePriority
enableAppointments
```

## AppSettings

Fields:

```text
id
theme
soundEnabled
voiceEnabled
volume
showClock
showDate
showNextQueues
animationEnabled
```

---

# 27. Database Relationships

Use:

```text
BusinessSettings
      |
      |
      +---- QueueSettings
      |
      |
      +---- Queue
      |
      +---- AppSettings
```

The MVP can keep the database intentionally simple.

---

# 28. Empty States

Every major screen should have a useful empty state.

Example:

### No Queue

**No customers waiting**

> Generate a queue number to start serving customers.

Button:

**Add Queue Number**

---

# 29. Error Handling

Examples:

### Queue Already Exists

> This queue number already exists.

### Database Error

> Something went wrong while saving your queue.

Buttons:

**Retry**

### Reset Warning

> Resetting the queue will remove today's active queue numbers.

Buttons:

**Cancel**

**Reset Queue**

---

# 30. Accessibility

The application should support:

- Large touch targets
- High contrast
- Screen reader labels
- Minimum 48dp clickable controls
- Large queue numbers
- Content descriptions for icons
- Avoid color-only status indicators

For example:

Instead of only a green dot:

**● Completed**

---

# 31. Offline-First Architecture

All core functionality must work without internet access.

Local functionality:

- Create queues
- Call queues
- Skip queues
- Finish queues
- Display mode
- Statistics
- History
- Settings

Cloud synchronization is not required for MVP.

---

# 32. Backup and Export

Provide:

### Export Data

Formats:

- CSV
- JSON

Example:

```text
queue_number,status,created_at,called_at,completed_at
A-021,COMPLETED,08:15,08:21,08:27
A-022,COMPLETED,08:17,08:27,08:32
A-023,SKIPPED,08:20,08:35,
```

The user can share exported files using the Android Sharesheet.

---

# 33. Recommended Folder Structure

```text
app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/pocketqueue/
│   │   │       ├── data/
│   │   │       │   ├── local/
│   │   │       │   ├── dao/
│   │   │       │   ├── entity/
│   │   │       │   └── database/
│   │   │       ├── domain/
│   │   │       ├── ui/
│   │   │       │   ├── navigation/
│   │   │       │   ├── screens/
│   │   │       │   ├── components/
│   │   │       │   └── theme/
│   │   │       ├── viewmodel/
│   │   │       └── MainActivity.kt
│   │   │
│   │   ├── res/
│   │   └── AndroidManifest.xml
│
├── docs/
│   ├── index.html
│   ├── workflow.html
│   ├── architecture.html
│   ├── database.html
│   ├── screenshots/
│   │   ├── welcome.png
│   │   ├── setup.png
│   │   ├── queue.png
│   │   ├── display.png
│   │   ├── history.png
│   │   └── settings.png
│   └── assets/
│       └── styles.css
│
├── README.md
└── build.gradle.kts
```

---

# 34. Documentation Requirement

The AI developer must generate complete project documentation directly inside:

```text
app/docs/
```

The documentation must be written in English.

The documentation must use HTML.

Required files:

```text
docs/index.html
docs/workflow.html
docs/architecture.html
docs/database.html
docs/screenshots/
```

---

# 35. Documentation Website

Create a professional static documentation website.

## index.html

Sections:

- Project Overview
- Features
- Screens
- Architecture
- Database
- Workflow
- Build Instructions
- Testing
- Troubleshooting

Use responsive HTML and CSS.

Do not rely on an external web framework.

Use local CSS.

---

# 36. Screenshot Documentation

The AI must generate screenshots of the implemented application.

Required screenshots:

```text
welcome.png
setup.png
queue.png
queue_add.png
queue_serving.png
display.png
history.png
queue_detail.png
statistics.png
settings.png
```

The screenshots must represent the actual final UI.

Do not use placeholder images.

Every screenshot should be referenced inside the HTML documentation.

Example:

```html
<figure>
    <img src="screenshots/queue.png" alt="Pocket Queue main queue screen">
    <figcaption>Main Queue Screen</figcaption>
</figure>
```

---

# 37. Screenshot Documentation Page

Create:

```text
docs/screenshots.html
```

This page should show all application screenshots in a responsive gallery.

Each screenshot should include:

- Screen name
- Screen purpose
- Main actions
- Workflow description

---

# 38. Visual Documentation Style

Documentation should look like professional product documentation.

Use:

- Responsive layout
- Sticky sidebar
- Cards
- Code blocks
- Tables
- Screenshot galleries
- Section headings
- Breadcrumbs
- Clean typography

Recommended font:

**Inter**

Use a local/system fallback so the documentation still works offline.

---

# 39. README.md

The root README must contain:

```text
Pocket Queue

Features
Architecture
Requirements
Installation
Running the App
Building APK
Testing
Project Structure
Database
Documentation
Screenshots
License
```

Add a documentation link:

```text
Open docs/index.html
```

---

# 40. Android Permissions

Keep permissions minimal.

Expected permissions:

```xml
android.permission.POST_NOTIFICATIONS
```

Only request notification permission when notification features actually require it.

Do not request unnecessary permissions such as:

- Contacts
- Location
- Camera
- Microphone
- SMS

unless a future feature explicitly requires them.

---

# 41. Performance Requirements

The application should:

- Launch quickly.
- Remain responsive with thousands of queue history records.
- Avoid unnecessary recompositions.
- Use Room pagination for large history datasets.
- Avoid memory leaks.
- Use lifecycle-aware state collection.
- Handle screen rotation correctly.

---

# 42. Testing Requirements

Implement:

## Unit Tests

Test:

- Queue number generation
- Queue reset
- Queue status transitions
- Waiting time calculation
- Service time calculation
- Priority ordering

Example:

```text
WAITING
↓
SERVING
↓
COMPLETED
```

Invalid transition:

```text
COMPLETED
↓
WAITING
```

must be rejected.

---

# 43. UI Tests

Test:

- Get Started
- Business Setup
- Generate Queue
- Call Next
- Finish Queue
- Skip Queue
- Recall Queue
- Open Display Mode
- Open History
- Open Settings
- Reset Queue

---

# 44. Queue Number Algorithm

Default configuration:

```text
Prefix = A
Number Length = 3
```

Generated numbers:

```text
A-001
A-002
A-003
...
A-999
```

After reset:

```text
A-001
```

If priority queue is enabled:

```text
P-001
P-002
```

Priority queues should be configurable.

---

# 45. Queue Ordering

Default order:

```text
Priority waiting queues
        ↓
Regular waiting queues
        ↓
Oldest creation timestamp
```

The application must prevent duplicate active queue numbers.

---

# 46. Security

Because this is an offline application:

- Store data locally.
- Validate all input.
- Protect exported data through the Android share system.
- Do not log sensitive customer information.
- Avoid storing unnecessary personal data.

The application should not require customer names for the basic workflow.

---

# 47. MVP Scope

The MVP must include:

- Welcome
- Setup
- Queue generation
- Call next
- Finish
- Skip
- Recall
- Display mode
- History
- Statistics
- Settings
- Room database
- Export CSV
- Offline support
- Documentation
- Screenshots

Do not add unnecessary complex features to the MVP.

---

# 48. Future Features

Possible future versions:

### Cloud Sync

Allow multiple Android devices to share one queue.

### Multi-Counter

Example:

```text
Counter 1
Counter 2
Counter 3
```

### Customer Display Device

A secondary Android device can act as a display-only screen.

### QR Queue Ticket

Customers scan a QR code and receive a queue number.

### Remote Queue Monitoring

Business owner can monitor the queue remotely.

### Printer Support

Print queue tickets using Bluetooth thermal printers.

---

# 49. AI Developer Instructions

Build the complete Android application instead of creating only a mockup.

The final result must be a runnable Android project.

The AI developer must:

1. Create the complete Android project.
2. Implement all MVP screens.
3. Implement functional queue logic.
4. Implement Room persistence.
5. Implement navigation.
6. Implement settings.
7. Implement display mode.
8. Implement history.
9. Implement statistics.
10. Implement export.
11. Add unit tests.
12. Add UI tests where practical.
13. Generate the application icon.
14. Generate the required screenshot assets.
15. Generate HTML documentation.
16. Store the documentation inside the project.
17. Ensure screenshots match the actual implementation.
18. Build the APK successfully.
19. Verify the application launches successfully.
20. Fix compile errors before finishing.

---

# 50. GitHub Workflow

Use GitHub for source control.

Recommended workflow:

```text
Create Project
    ↓
Implement UI
    ↓
Implement Database
    ↓
Implement Queue Logic
    ↓
Implement Tests
    ↓
Generate Documentation
    ↓
Generate Screenshots
    ↓
Build Debug APK
    ↓
Run Tests
    ↓
Fix Errors
    ↓
Commit
    ↓
Push to GitHub
```

---

# 51. GitHub Actions

Create:

```text
.github/workflows/android.yml
```

The workflow should:

1. Checkout repository.
2. Set up JDK.
3. Set up Android SDK.
4. Grant Gradle execute permission.
5. Run unit tests.
6. Build debug APK.
7. Upload APK as GitHub Actions artifact.

Example output:

```text
app/build/outputs/apk/debug/app-debug.apk
```

---

# 52. Definition of Done

The project is complete only when:

```text
[✓] App builds successfully
[✓] APK generated
[✓] Application launches
[✓] Queue generation works
[✓] Call Next works
[✓] Finish works
[✓] Skip works
[✓] Recall works
[✓] Display Mode works
[✓] History works
[✓] Statistics work
[✓] Settings work
[✓] Data survives app restart
[✓] Export works
[✓] Tests pass
[✓] Icon exists
[✓] Screenshots exist
[✓] HTML documentation exists
[✓] Documentation matches actual application
[✓] README exists
[✓] GitHub Actions build exists
```

---

# 53. Final Product Vision

Pocket Queue should feel like a small professional business tool rather than a complicated enterprise application.

The most important design principle is:

> **An operator should be able to start the queue in less than one minute.**

The main queue screen must make the most important actions immediately obvious:

```text
CURRENT QUEUE
A-023

[ RECALL ]

[ FINISH ]

NEXT CUSTOMER
A-024

[ CALL NEXT ]
```

The interface should remain fast, readable, and reliable even when the operator is serving customers continuously throughout the day.

---

# 54. Final AI Prompt

Build **Pocket Queue**, a complete offline-first Android queue management application using **Kotlin, Jetpack Compose, MVVM, Hilt, Room, StateFlow, and Navigation Compose**.

Implement the complete workflow described in this specification.

Use English throughout the application.

Create a professional minimalist UI using the Pocket Queue branding.

Create the actual Android launcher icon according to the logo specification.

Implement:

- Welcome
- Setup
- Queue generation
- Queue management
- Call Next
- Recall
- Finish
- Skip
- Queue details
- History
- Statistics
- Display Mode
- Settings
- Export
- Offline persistence

Use Room for local persistence.

Use proper state management and lifecycle-aware Compose patterns.

Make the application responsive for phones, tablets, and landscape display mode.

Do not create a fake prototype. All main buttons must perform real actions.

Generate real screenshots from the implemented application.

Create the following documentation inside the application repository:

```text
docs/index.html
docs/workflow.html
docs/architecture.html
docs/database.html
docs/screenshots.html
docs/screenshots/*.png
docs/assets/styles.css
```

The HTML documentation must be fully usable offline.

The screenshots must be generated from the actual final application UI and must not be placeholders.

Also create:

```text
README.md
.github/workflows/android.yml
```

Run tests and build the APK before finishing.

Fix all compile, runtime, and test errors.

The final repository should be ready for GitHub and capable of producing a working Android APK through GitHub Actions.