# WormScript AI Skills

Expert AI skills for [WormScript (WRM)](https://github.com/Alearian/WormScript) — the .NET code scaffolding tool that generates complete APIs, Dapper repositories, and React components from your PostgreSQL schema.

These skills give AI assistants deep knowledge of WRM conventions, annotations, features, and patterns so they can help you design schemas and build projects correctly, first time.

Supports **Claude Code**, **Cursor**, **GitHub Copilot**, **Windsurf**, and any tool that accepts a custom system prompt.

---

## Skills included

### `wrm`
Full WRM project assistant. Use when you want to:
- Create a new WRM project from scratch
- Write or edit a `.wrm` build script
- Choose features, configure ports, set up Docker
- Generate models, APIs, and web components
- Deploy to Azure

### `wrm-data-builder`
PostgreSQL schema designer for WRM. Use when you want to:
- Design a database schema that's compatible with WRM annotations
- Convert an existing schema to WRM conventions
- Add new tables to an existing WRM project
- Understand which WRM features fit your data requirements
- Get annotated SQL with correct `COMMENT ON` statements, `LIKE base.*` clauses, and a ready-to-paste `.wrm` snippet

---

## Quick install

### Install all skills for Claude Code

**macOS / Linux:**
```bash
git clone https://github.com/Alearian/WormScript-Skills.git
cd WormScript-Skills
bash install.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/Alearian/WormScript-Skills.git
cd WormScript-Skills
.\install.ps1
```

Restart Claude Code. Skills load automatically.

---

### Install for other tools

Run from inside the cloned repo, from your project directory:

| Tool | macOS/Linux | Windows |
|---|---|---|
| Cursor | `bash install.sh --tool cursor` | `.\install.ps1 -Tool cursor` |
| GitHub Copilot | `bash install.sh --tool copilot` | `.\install.ps1 -Tool copilot` |
| Windsurf | `bash install.sh --tool windsurf` | `.\install.ps1 -Tool windsurf` |
| All tools | `bash install.sh --tool all` | `.\install.ps1 -Tool all` |

### Install a specific skill only

```bash
bash install.sh --skill wrm-data-builder               # macOS/Linux
.\install.ps1 -Skill wrm-data-builder                  # Windows

bash install.sh --skill wrm-data-builder --tool cursor # Cursor only
.\install.ps1 -Skill wrm-data-builder -Tool cursor
```

### Any other tool (Zed, Aider, Continue, custom system prompt)

Copy the contents of `{skill-name}/adapters/generic.md` into your tool's system prompt or custom instructions field.

---

## Using the skills

### Claude Code

Trigger by name or naturally:

```
/wrm-data-builder
```
> *"Design a schema for a property management system"*
> *"I need tables for a helpdesk app — users can raise tickets, agents respond"*
> *"Add a subscription tier system to my WRM project"*

```
/wrm
```
> *"Create a new WRM project called RevCamp with AUTH and FILEHANDLING"*
> *"Update my .wrm script to add GraphQL support"*
> *"Why isn't my wrm build finding my models?"*

### Other tools

Once the adapter is installed, ask naturally — the AI will apply WRM rules automatically when it detects SQL, `.wrm` scripts, or WRM-related questions.

---

## Repo structure

```
README.md                           This file
install.sh                          macOS/Linux installer
install.ps1                         Windows installer

wrm/
  SKILL.md                          Claude Code skill
  COMMAND_REFERENCE.md              .wrm script syntax
  FEATURES.md                       Feature system details
  SQL_CONVENTIONS.md                SQL naming and annotation rules
  EXAMPLES.md                       Real project examples
  README.md                         Skill readme

wrm-data-builder/
  SKILL.md                          Claude Code skill
  WRM_ANNOTATIONS.md                COMMENT ON keyword reference
  WRM_CONFLICTS.md                  Reserved column names per feature
  FEATURE_ASSESSMENT.md             Feature detection heuristics
  SQL_PATTERNS.md                   Copy-paste SQL templates
  README.md                         Skill readme
  adapters/
    generic.md                      Any tool — paste as system prompt
    cursor.mdc                      Cursor rules (.cursor/rules/)
    copilot-instructions.md         GitHub Copilot (.github/)
    windsurf.rules                  Windsurf (.windsurfrules)
```

---

## Requirements

- [WormScript (WRM)](https://github.com/Alearian/WormScript) — `dotnet tool install --global Wrm`
- PostgreSQL 13+
- .NET 9.0 SDK (for generated projects)

---

## Issues and contributions

- Skill issues / feature requests: [github.com/Alearian/WormScript-Skills/issues](https://github.com/Alearian/WormScript-Skills/issues)
- WRM tool issues: [github.com/Alearian/WormScript/issues](https://github.com/Alearian/WormScript/issues)

---

*WormScript and these skills are developed by [Furniss Software](https://github.com/Alearian).*
