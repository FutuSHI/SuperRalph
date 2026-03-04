# Web Enhancement Discipline

> **Conditional Module:** Only loaded when the project is detected as a web project.

## Auto-Detection Rules

A project is a web project if:
- `package.json` exists in the project root AND
- Dependencies (dependencies or devDependencies) include any of: `react`, `next`, `vue`, `nuxt`, `angular`, `@angular/core`, `svelte`, `solid-js`, `astro`, `remix`, `gatsby`

If detected, set `webProject: true` in SuperRalph state.

## UI Story Rules

For any user story that modifies UI (visual components, pages, layouts):

### Mandatory Acceptance Criteria
Every UI story MUST include: **"Verify in browser using dev-browser skill"**

### Browser Verification Process
1. Navigate to the page affected by the change
2. Interact with the changed elements (click, input, toggle)
3. Verify the visual output matches acceptance criteria
4. Check browser console for errors (there should be none)
5. If browser tools are not available: note in progress.txt that manual browser verification is needed

### Additional Web Quality Checks
- **Accessibility basics:** Images have alt text, interactive elements are keyboard-accessible
- **No console errors:** The browser console should be clean after changes
- **Responsive awareness:** If the project uses responsive design, verify changes don't break at common breakpoints

## Non-Web Projects

If `webProject: false`, this entire discipline is NOT loaded. Zero noise, zero overhead.
