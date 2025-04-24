# Documentation Automation System

This project includes an automated documentation system that synchronizes README.md files from the codebase to a documentation site built with MkDocs and deployed to GitHub Pages.

## Quick Start

1. **Write documentation in README.md files** within your system/subsystem directories
2. **Push to main branch** to trigger automatic synchronization and deployment
3. **View documentation** on GitHub Pages

## Components

The documentation automation system consists of:

1. **sync_docs.py**: A Python script that synchronizes README.md files to the /docs folder
2. **GitHub Action**: A workflow that runs the sync script and deploys the documentation
3. **Pre-commit Hook**: An optional hook to enforce README.md existence

## How It Works

### Documentation Flow

```
[README.md files in codebase] → [sync_docs.py] → [/docs folder] → [MkDocs] → [GitHub Pages]
```

### Automation Process

1. When code is pushed to the main branch, a GitHub Action is triggered
2. The action runs the `sync_docs.py` script, which:
   - Scans the codebase for README.md files
   - Maps them to the appropriate location in /docs
   - Copies the content with a warning header
   - Updates the mkdocs.yml navigation if needed
   - Removes any orphaned .md files in /docs
3. The action then builds the MkDocs site and deploys it to GitHub Pages

## Setup Instructions

### GitHub Action (Already Set Up)

The GitHub Action is already configured in `.github/workflows/sync-docs.yml`. It will run automatically on pushes to the main branch.

### Pre-commit Hook (Optional)

To install the pre-commit hook:

```bash
# Copy the hook to the git hooks directory
cp pre-commit-hook.sh .git/hooks/pre-commit

# Make it executable
chmod +x .git/hooks/pre-commit
```

This hook will ensure that each system/subsystem has a README.md file before allowing commits.

## Manual Usage

If you need to manually synchronize the documentation:

```bash
# Run the sync script
python sync_docs.py

# Preview the documentation locally
mkdocs serve

# Build the static site
mkdocs build
```

## Documentation Structure

The documentation follows this structure:

1. **Game**
    * Overview
    * Schema of all systems connected
2. **Environment System**
    * Overview
    * Effects Manager
    * Ground Visual Manager
    * Shared Ground Manager
    * Theme System
    * Biome System
3. **Motion System**
    * Overview
    * Collision Materials
    * Bounce System
    * Boost System
    * Launch System
    * Obstacle System
4. **Camera System**
    * Overview
    * Follow System
    * Zoom System
    * Slow Motion System
    * Debug Tools
5. **Visual Background System**
    * Overview
    * Debug Tools
6. **Stage Composition System**
    * Overview
    * Chunk Management System
    * Content Distribution System
    * Stage Config System
    * Flow and Difficulty Controller
7. **Player System**
    * PlayerCharacter and PlayerSpawner (overall readme)
8. **Cross-Systems**
    * Dependency Injection
    * Effects

## Best Practices

1. **Keep README.md files up to date**: Update them whenever you make significant changes
2. **Follow the structure**: Use consistent headings and formatting
3. **Include examples**: Provide code examples where appropriate
4. **Explain the why**: Document the reasoning behind design decisions

## Troubleshooting

If you encounter issues with the documentation:

1. Check that your README.md files are properly formatted
2. Run `python sync_docs.py --dry-run` to see what changes would be made
3. Check the GitHub Action logs for any errors

For more details, see [docs/README.md](docs/README.md).
