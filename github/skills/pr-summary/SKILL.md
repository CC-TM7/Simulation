---
name: pr-summary
description: Create business-focused pull request summaries for AL projects by analyzing branch changes and presenting impact in a clear stakeholder-friendly structure.
argument-hint: "target branch (optional)"
---

# PR Summary Skill

Use this skill when the user asks for a pull request summary, PR description text, or a concise overview of branch changes.

## Objectives

- Produce summaries that emphasize business value and user impact.
- Keep output concise, structured, and ready to paste into a PR description.
- Avoid low-value implementation details unless explicitly requested.

## Required Output Format

Always return the full summary inside a Markdown code block:

```markdown
## 📋 Summary

[2-3 sentence overview of the changes and their purpose]

## ✨ What's New

[List new functionality and features that add value]

## 🔧 What's Changed

[List modifications to existing functionality]

## 🐛 Bug Fixes

[List resolved issues - only include if applicable]

## 🎯 Business Value

[Bullet points explaining the benefits and impact of these changes]
```

## Authoring Rules

- Be concise and clear.
- Focus on outcomes, not internal implementation.
- Omit empty sections.
- Do not include file counts, line counts, or raw diff stats unless the user asks.
- Write for mixed audiences (technical and non-technical).
- Use section emojis for readability (📋 ✨ 🔧 🐛 🎯).
- Do not hallucinate: only mention features, fixes, or changes that are observable in changed files, commits, or PR discussion.

## Analysis Workflow

When creating a summary, analyze the branch before writing:

1. List changed files and statuses.
2. Review key diffs and commit messages for intent.
3. Identify the dominant change type (feature, bug fix, refactor, docs, infra).
4. Translate technical changes into business impact.
5. Generate only relevant summary sections.
6. If change intent is unclear, ask exactly 1 clarifying question before generating the final summary.

## Branch-Type Emphasis

| Branch Type    | Prioritize                     | Emphasis                                       |
| -------------- | ------------------------------ | ---------------------------------------------- |
| Feature        | What's New, Business Value     | New capabilities and user benefits             |
| Bugfix         | Bug Fixes, What's Changed      | Problems resolved and reliability improvements |
| Refactor       | What's Changed, Business Value | Maintainability and performance improvements   |
| Documentation  | What's New, Business Value     | Clarity, onboarding, and consistency           |
| Infrastructure | What's New, Business Value     | Team productivity and quality guardrails       |

## Good/Bad Guidance

Good summaries explain what changed, why it matters, and who benefits.

Avoid summaries that are mostly procedure names, object IDs, file paths, or diff statistics.

## Quality Checklist

Before returning the final summary, verify:

- Sections are relevant to the branch changes.
- No empty sections are included.
- Technical noise is removed unless explicitly requested.
- Business value is clearly stated.
