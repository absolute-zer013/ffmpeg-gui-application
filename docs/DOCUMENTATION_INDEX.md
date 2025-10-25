# FFmpeg Export Tool — Documentation Index

Complete guide to all project documentation. Start here to find what you need.

## Quick Links

### Getting Started
- **[README.md](../README.md)** - Project overview, setup, and basic usage
- **[FEATURES.md](FEATURES.md)** - Complete list of implemented features
- **[IMPLEMENTATION_OVERVIEW.md](IMPLEMENTATION_OVERVIEW.md)** - Consolidated implementation summary (replaces phase reports)

### Testing & Quality
- **[TESTING.md](TESTING.md)** - Testing guide and running tests
- **[CI_CD_SETUP.md](../CI_CD_SETUP.md)** - Continuous integration setup

### Deployment
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Build and distribution instructions

### Enhancement Planning
- **[ENHANCEMENTS.md](ENHANCEMENTS.md)** - Roadmap and ideas
- **[issues/NEW_FEATURES_COMBINED_ISSUE.md](issues/NEW_FEATURES_COMBINED_ISSUE.md)** - Single tracking issue for upcoming features
  

## Current Documentation Map

We’ve consolidated all phase reports and summaries into a single overview:

- Implementation overview: `IMPLEMENTATION_OVERVIEW.md`
- Implemented feature details: `FEATURES.md`
- Roadmap and ideas: `ENHANCEMENTS.md`
- Upcoming work (single tracker): `issues/NEW_FEATURES_COMBINED_ISSUE.md`
  

## Documentation by Type

### Planning Documents
| Document | Purpose | Audience |
|----------|---------|----------|
| [ENHANCEMENTS.md](ENHANCEMENTS.md) | Roadmap and candidate features | Developers, Contributors |
| [IMPLEMENTATION_OVERVIEW.md](IMPLEMENTATION_OVERVIEW.md) | Consolidated view of what’s shipped | Product Owners, Managers |
| [issues/NEW_FEATURES_COMBINED_ISSUE.md](issues/NEW_FEATURES_COMBINED_ISSUE.md) | Single tracking issue for upcoming work | Project Managers |
  

### Implementation Documents
| Document | Purpose | Audience |
|----------|---------|----------|
| [FEATURES.md](FEATURES.md) | Implemented feature list | Users, Developers |
| [README.md](../README.md) | Getting started guide | Users, New Developers |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Quick usage reference | Users |

### Development Documents
| Document | Purpose | Audience |
|----------|---------|----------|
| [TESTING.md](TESTING.md) | Testing guide and standards | Developers, QA |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Build and release process | Developers, DevOps |
| [CI_CD_SETUP.md](../CI_CD_SETUP.md) | CI/CD configuration | DevOps |

## Where to Find Things Now

We’ve simplified the docs:
- What’s shipped → `IMPLEMENTATION_OVERVIEW.md` and `FEATURES.md`
- What’s next → `ENHANCEMENTS.md` and `issues/NEW_FEATURES_COMBINED_ISSUE.md`
- How to test/build/deploy → `TESTING.md`, `DEPLOYMENT.md`

### For Contributors
1. Review **[ENHANCEMENTS.md](ENHANCEMENTS.md)** for candidate features
2. Check **[issues/NEW_FEATURES_COMBINED_ISSUE.md](issues/NEW_FEATURES_COMBINED_ISSUE.md)** for current focus
3. Propose changes via PRs and update **[FEATURES.md](FEATURES.md)** when implemented

## Documentation Structure

```
/
├── README.md                      # Project overview and setup
├── CI_CD_SETUP.md                # CI/CD summary
│
├── docs/
│   ├── DOCUMENTATION_INDEX.md    # This file
│   ├── IMPLEMENTATION_OVERVIEW.md# Consolidated implementation overview
│   ├── FEATURES.md               # Implemented features
│   ├── ENHANCEMENTS.md           # Roadmap and ideas
│   ├── TESTING.md                # Testing guide
│   ├── DEPLOYMENT.md             # Deployment guide
│   ├── QUICK_REFERENCE.md        # Quick usage reference
│   │
│   └── issues/
│       └── NEW_FEATURES_COMBINED_ISSUE.md  # Single tracking issue for upcoming work
```

## Finding Information

### "How do I use feature X?"
→ [FEATURES.md](FEATURES.md) or [README.md](../README.md)

### "What features are planned?"
→ [ENHANCEMENTS.md](ENHANCEMENTS.md) and [issues/NEW_FEATURES_COMBINED_ISSUE.md](issues/NEW_FEATURES_COMBINED_ISSUE.md)

### "How do I implement feature Y?"
→ [ENHANCEMENTS.md](ENHANCEMENTS.md)

### "What's the status of Phase Z?"
→ Use `IMPLEMENTATION_OVERVIEW.md` (we no longer track by phase)

### "How do I run tests?"
→ [TESTING.md](TESTING.md)

### "How do I build and deploy?"
→ [DEPLOYMENT.md](DEPLOYMENT.md)

### "What's next to build?"
→ [issues/NEW_FEATURES_COMBINED_ISSUE.md](issues/NEW_FEATURES_COMBINED_ISSUE.md)

## Contributing

When adding new features:
1. Review the roadmap in [ENHANCEMENTS.md](ENHANCEMENTS.md)
2. Align with the focus in [issues/NEW_FEATURES_COMBINED_ISSUE.md](issues/NEW_FEATURES_COMBINED_ISSUE.md)
3. Update documentation when complete:
   - Mark feature as implemented in [ENHANCEMENTS.md](ENHANCEMENTS.md)
   - Add to [FEATURES.md](FEATURES.md) with details
   - Update the combined issue checklist if applicable
   - Update README.md if notable

## Documentation Maintenance

### When to Update
- **README.md**: When adding major features visible to users
- **FEATURES.md**: When completing any feature from the roadmap
- **ENHANCEMENTS.md**: When a feature is completed (mark with ✅)
- **CHANGELOG.md** and **CHANGELOG_SUMMARY.md**: When features land
- **issues/NEW_FEATURES_COMBINED_ISSUE.md**: When focus or status changes

### Documentation Standards
- Use Markdown for all documentation
- Include dates on planning documents
- Keep cross-references up to date
- Use consistent formatting and structure
- Include examples where helpful
- Update both summary and detailed docs

## Questions?

If you can't find what you need:
1. Check this index first
2. Search across all documentation files
3. Review the relevant phase documentation
4. Open a discussion or issue on GitHub

---

**Last Updated:** 2025-10-25  
**Documentation Version:** 6.2 (consolidated; single tracker retained)
