# Veto App - QA Test Suite

This document outlines the structured test suite for the Veto Flutter application, covering basic use cases, critical edge cases, race conditions, and UI/UX states.

## 1. Basic Use Cases (Happy Paths)

| Test ID | Scenario | Steps to Reproduce | Expected Result |
| :--- | :--- | :--- | :--- |
| **TC-BP-001** | **Standard Room Creation** | 1. Open app and select "Create Room".<br>2. Observe the generated 4-character code.<br>3. Verify host status. | Host is in the lobby with a visible 4-character code. The `connectedPlayers` array contains the host, and `isNowHost` is `true`. |
| **TC-BP-002** | **Joining a Room** | 1. Second user opens app and selects "Join Room".<br>2. Enter the host's 4-character code.<br>3. Tap "Join". | Second user appears in the lobby. Both users see the updated `connectedPlayers` list. |
| **TC-BP-003** | **Host Setting Filters** | 1. Host taps "Settings" in the lobby.<br>2. Modify filters (Year, Minimum Score, Maximum Runtime, Family Friendly, Spoken Languages).<br>3. Save settings. | The settings bottom sheet closes. Updated parameters are saved to the room's Firestore document. |
| **TC-BP-004** | **Starting the Session** | 1. Host taps "Start Swiping".<br>2. Wait for TMDB API response and Firestore sync. | All users in the room are transitioned to the `SwipeDeckScreen`. The first movie card is loaded. |
| **TC-BP-005** | **Right Swipe (Like)** | 1. User swipes right on a movie card.<br>2. Observe Firestore state. | Card animates off-screen right. A Firestore transaction executes, adding the user's ID to the movie's `likes` array. |
| **TC-BP-006** | **Left Swipe (Dislike)** | 1. User swipes left on a movie card. | Card animates off-screen left. The next movie in the deck is displayed. Firestore is not updated for dislikes. |
| **TC-BP-007** | **Matching Consensus** | 1. All users in the room swipe right on the same movie (`likes.length == totalPlayers`). | A Match Overlay is triggered for all users in the room simultaneously. The `latestMatch` field in Firestore is populated. |
| **TC-BP-008** | **Ending a Session (Host Revert)** | 1. Host taps "Return to Lobby" or ends session.<br>2. Observe navigation for all users. | Room status reverts to `waiting`. All connected users are seamlessly teleported back to the `WaitingRoomScreen`. |

## 2. Edge Cases & Race Conditions (Critical)

| Test ID | Scenario | Steps to Reproduce | Expected Result |
| :--- | :--- | :--- | :--- |
| **TC-EC-001** | **Screen Rotation Mid-Swipe** | 1. User begins dragging a card (mid-swipe).<br>2. Rotate device from portrait to landscape.<br>3. Release card. | Swiper state persists without resetting. The swipe action completes normally. No duplicate TMDB API calls are triggered. |
| **TC-EC-002** | **Screen Rotation Mid-Fetch** | 1. User swipes the last visible card, triggering a fetch for the next batch.<br>2. Rotate device during the loading state. | The fetch request completes successfully. The new batch of cards is rendered. No duplicate API requests are made. |
| **TC-EC-003** | **Host Migration (Lobby)** | 1. Multiple users in the lobby.<br>2. Host closes the app or leaves the room. | The app dynamically reads `isNowHost`. The next user in the `connectedPlayers` array is instantly promoted to host, gaining access to settings and start controls. |
| **TC-EC-004** | **Host Leaves Mid-Match** | 1. A match is triggered (Match Overlay visible).<br>2. Current host closes the app exactly when the match triggers. | Host migration occurs in the background. The Match Overlay remains visible for remaining users. The new host inherits the ability to manage the room without disrupting the match flow. |
| **TC-EC-005** | **Lost Connection During Swipe** | 1. User turns off Wi-Fi/Cellular.<br>2. User swipes right on a movie. | App queues the Firestore transaction locally. UI reflects the swipe. Upon reconnection, the transaction executes and syncs with the room. |
| **TC-EC-006** | **Strict Filters (0 TMDB Results)** | 1. Host sets extremely narrow filters (e.g., Year 1920-1921, Tagalog language, Score > 9).<br>2. Host taps "Start Swiping". | The app gracefully handles the empty TMDB response. An error SnackBar or dialog informs the host "No movies found with these filters", preventing navigation to the empty Swipe Deck. |
| **TC-EC-007** | **Simultaneous "Keep Swiping"** | 1. Match overlay is active.<br>2. Multiple users tap the "Keep Swiping" button at the exact same millisecond. | The first request deletes the `latestMatch` field. Subsequent requests handle the null field gracefully without crashing. The listener drops the overlay for everyone simultaneously, and a single SnackBar notification is shown. |

## 3. UI/UX States

| Test ID | Scenario | Steps to Reproduce | Expected Result |
| :--- | :--- | :--- | :--- |
| **TC-UI-001** | **Lazy-Loading on Fast Swipes** | 1. User rapidly swipes left 10 times in a row.<br>2. Observe network traffic and card rendering. | The swiper handles rapid input smoothly without jank. The background lazy-loading of Director, Cast, and Reviews is debounced or cancelled for rapidly skipped cards, only loading fully for the currently viewed card. |
| **TC-UI-002** | **Tablet Split-Screen Layout** | 1. Launch app on an iPad or Android Tablet in landscape mode.<br>2. Navigate to `SwipeDeckScreen`. | The UI utilizes a split-screen layout (e.g., Swipe Deck on the left, Movie Details/Chat on the right) rather than stretching the mobile UI. |
| **TC-UI-003** | **Responsive Text Scaling** | 1. Change device system font size to maximum.<br>2. View Movie Cards and Settings Modal. | Text scales appropriately without overflowing bounds, causing clipping, or breaking the layout (especially on the `flutter_card_swiper` widget). |
| **TC-UI-004** | **Host Settings Modal Constraints** | 1. Host opens Settings bottom sheet on a small mobile device.<br>2. Open the keyboard for a text input field (if any). | The modal is constrained properly. Content is scrollable. The keyboard does not obscure critical buttons (e.g., Save/Apply). |
| **TC-UI-005** | **Match Overlay Animation** | 1. Trigger a match.<br>2. Observe the overlay entrance and exit. | The overlay animates smoothly (e.g., fade-in/scale-up). The UI remains responsive while the overlay is visible. Dropping the overlay transitions cleanly back to the swipe deck. |
