# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# IMPORTANT
- Always prioritize writing clean, simple, and modular code.
- Use simple & easy-to-understand language. Write in short sentences.
- DO NOT BE LAZY! Always read files IN

# COMMENTS
- Write lots of comments in your code. explain exactly what you are doing in your comments.
- but be strategic, do not explain obvious syntax - instead explain your thought process at the time of writing the
- NEVER delete explanatory comments from the code you're editing (unless they are wrong/obsolete)
- focus on explaining the non-obvious stuff in the comments, the nuances / details
- DO NOT delete comments
currently in our code. If the
comment is obsolete, or wrong, then update it - but NEVER mindlessly remove comments without

# HEADER COMMENTS
- EVERY file HAS TO start with 4 lines of comments!
1. exact file location in codebase
2. clear description of what this file does
3. clear description of WHY this file exists
4. RELEVANT FILES: comma-separated list of 2-4 most relevant files
- NEVER delete these "header comments" from the files you're

# ACTIVE CONTRIBUTORS
- **User (Human)**: Works in Cursor IDE, directs the project, makes high-level decisions, has the best taste & judgement.
- **Cursor Agent**: AI copilot activated by User, lives in the Cursor IDE, medium level of autonomy, can edit multiple files at once, can run terminal commands, can access the whole codebase; the User uses it to vibe-code the app.
- **Claude Code**: Terminal-based AI agent with high autonomy, can edit multiple files simultaneously, understands entire codebase automatically, runs tests/Git operations, handles large-scale refactoring and complex debugging independently

## Architecture Overview
This is an agentic-outreach system built with supabase and n8n which is hosted on Render.

### Access to MCPs
- Supabase MCP: READ-ONLY access to Supabase tables, triggers and edge functions and so on. NEVER use MCP for database modifications-- always create migration files manually in the supabase/migrations/ folder
- N8N MCP: get all available n8n nodes and their structure in order to plan writing workflows in json so the user can just copy and paste them into n8n and they'll work immediately
- Exa Search MCP: Search the internet, github and other developer orientated sources to get the latest information about coding/developement practices (its 2025)

## Development Guidelines

## Project Awareness
- Always keep in mind that we use supabase and its cutting edge functioanlities like edge functions, functions, triggers as main way to add functionalities to our agentic-outreach-system and enhance it with custom n8n workflows
- IMPORTANT. Just add n8n workflows if there is no way (or an extremely difficult way) to add the needed functionality in supabase

### Anti-Complexity Philosophy
- BE VERY SUSPICIOUS OF EVERY COMPLICATION - simple = good, complex = bad
- Do exactly what's asked, nothing more
- Execute precisely what the user asks for, without additional features
- Constantly verify you're not adding anything beyond explicit instructions

### Communication Style
- Use simple & easy-to-understand language. write in short sentences
- Be CLEAR and STRAIGHT TO THE POINT
- EXPLAIN EVERYTHING CLEARLY & COMPLETELY
- Address ALL of user's points and questions clearly and completely.

# IMPORTANT
- never EVER push to github unless the User explicitly tells you to.

## Supabase Development

### Branch Configuration
- **Main Branch Project ID**: `ejlnibieoldtlaoymzvy` 

<SOLID_principles>
# SOLID PRINCIPLES - NON-NEGOTIABLE ARCHITECTURE RULES

**FAILURE TO FOLLOW SOLID = CODEBASE DEATH.** These principles are the difference between
a $100B company and a failed startup

## S - Single Responsibility Principle
Every class/function does ONE thing. PERIOD.

## 0 - Open/Closed Principle
Open for extension, CLOSED for modification.
- **Never edit working code** - extend it with new classes/components
- **Use abstractions**: Agent base → StandardChatAgent

## ENFORCEMENT RULES
1. **Every PR violating SOLID gets REJECTED** - no exceptions
2. **Files > 300 LOC = automatic SOLID violation** - split immediately
3. **Can't unit test it? = DIP violation** - refactor NOW
4. **Adding "if" statements to handle new cases? = OCP violation** - use polymorphism
# MOST IMPORTANT: KEEP IT SIMPLE. THE SIMPLER, THE BETTER.
</SOLID_principles>
