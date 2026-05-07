# Common Issues

## Submit Button Not Clickable After Turbo Navigation

**Symptoms:** Submit button works on initial page load (full reload) but becomes unclickable after navigating via Turbo. The button appears normal but does not respond to clicks.

**Root Cause:** Button placed outside its intended parent container due to misplaced `</div>` tag. Parent container had `overflow-hidden` CSS, clipping the button's clickable area after Turbo restored page with different scroll position.

**Solution:** Verify HTML structure is correct. Ensure interactive elements (buttons, links, form inputs) are inside their intended parent containers.

**Check for:**
- `overflow-hidden` on parent containers
- `overflow-y-auto` on ancestors
- Fixed heights (`h-full`, `h-screen`)
- Absolute/fixed positioning
- Misplaced closing `</div>` tags

**Debugging tips:**
1. Inspect element — check for `disabled` attribute or `pointer-events: none` CSS
2. Check parent containers for `overflow-hidden` or clipping
3. Compare HTML structure — verify closing tags are in correct order
4. Test with full reload — if it works after reload but not after Turbo navigation, likely scroll position restoration or HTML structure issue
