# Gemini Notes
- How to keep the "Mobile" door open:
To ensure your "Web First" app doesn't become "Web Only," follow this one rule: Don't use dart:html.
If you need to do something platform-specific (like picking a file), use a Flutter package (like file_picker) rather than a web-only library. This ensures that when you finally run flutter run -d ios, 100% of your code still compiles [7].

- What about the "Desktop" specific features?
You mentioned isDesktop. In Flutter, you use kIsWeb or Platform.isWindows only for logic, not layout.
Use LayoutBuilder for: "Should I show a sidebar?"
Use Platform check for: "Should I show a 'Quit App' button?" (Since you can't "Quit" a website).
Does this "Content-First" scaling make sense for your Hub layout?

# Todo
- Put a search bar at the top of the shell
- Download pregnancy app, check web, see if they have subreddit concept