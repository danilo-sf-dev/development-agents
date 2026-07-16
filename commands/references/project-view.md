# Reference: `/sdd.project --view`

**Used by**: `/sdd.project --view`.

1. **Run the viewer script**:
   ```bash
   bash development-agents/framework/tools/state/view-framework.sh "$(pwd)"
   ```
2. **Report result** to user (generated files, browser opened)
3. Do NOT execute any other project logic

## What the script does

1. Scans `sdd/` directory for standards, WIP features, and completed features
2. Generates `sdd/project-framework-data.json` with all project data
3. Copies the interactive HTML viewer to `sdd/project-framework-viewer.html`
4. Opens the viewer in the default browser

**If `sdd/` directory doesn't exist**:
```
Error: No sdd/ directory found. Initialize a feature first with /sdd.start.
```
