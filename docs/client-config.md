# Client Migration Guide

**File location**: `docs/client-config.md`  
**Purpose**: Complete step-by-step guide for migrating this project to a new client  
**Why it exists**: To ensure no client-specific references are missed when switching to a new client  
**Relevant files**: `project-description.md`, `supabase/schemas/02-tables.sql`, `workflows/outreach-bulk.json`, `README.md`

## Overview

This document provides a comprehensive checklist for migrating the agentic outreach system to a new client. Follow each section in order to ensure complete migration.

## Pre-Migration Information Gathering

Before starting, collect the following information for the new client:

### ✅ Client Information Checklist
- [ ] **Company Name**: e.g., "NewClient Corp"
- [ ] **Primary Contact Email**: e.g., "sales@newclient.com"
- [ ] **Domain**: e.g., "newclient.com"
- [ ] **GitHub Repository URL**: e.g., "https://github.com/user/newclient-outreach"
- [ ] **Product/Service Name**: e.g., "AI Sales Platform"
- [ ] **Product Description**: Brief description of what they offer
- [ ] **Target Market**: Who are their customers?
- [ ] **Value Propositions**: Key selling points and metrics
- [ ] **Primary Language**: English, German, etc.
- [ ] **Communication Style**: Formal/informal, cultural considerations
- [ ] **Compliance Requirements**: GDPR, industry-specific regulations

## 1. Database Configuration Changes

### 1.1 Update Schema Files

**File**: `supabase/schemas/02-tables.sql`
- [ ] **Line 30**: Change default email
  ```sql
  # FROM:
  email TEXT NOT NULL DEFAULT 'marian@salesurance.co' -- Sender email address
  
  # TO:
  email TEXT NOT NULL DEFAULT 'sales@newclient.com' -- Sender email address
  ```

### 1.3 Update Migration File Headers

**Files to update**: All files in `supabase/migrations/`
- [ ] **Pattern**: Change file header comments
  ```sql
  # FROM:
  -- /Users/nick/NiCode GmbH/Salesurance/supabase/migrations/...
  
  # TO:
  -- /Users/nick/NiCode GmbH/NewClient/supabase/migrations/...
  ```

## 2. Code File Changes

### 2.1 Update File Headers

**Files affected**: All `.sql`, `.ts`, `.toml` files in `supabase/`

**Pattern**: Update all file header comments
```typescript
# FROM:
// /Users/nick/NiCode GmbH/Salesurance/supabase/functions/send-email/index.ts

# TO:
// /Users/nick/NiCode GmbH/NewClient/supabase/functions/send-email/index.ts
```

**Files to update**:
- [ ] `supabase/config.toml` (Line 1)
- [ ] `supabase/schemas/01-extensions.sql` (Line 1)
- [ ] `supabase/schemas/02-tables.sql` (Line 1)
- [ ] `supabase/schemas/03-indexes.sql` (Line 1)
- [ ] `supabase/schemas/04-functions.sql` (Line 1)
- [ ] `supabase/schemas/05-triggers.sql` (Line 1)
- [ ] `supabase/schemas/06-cron-jobs.sql` (Line 1)
- [ ] `supabase/functions/send-email/index.ts` (Line 1)
- [ ] `supabase/functions/resend-webhook/index.ts` (Line 1)
- [ ] `supabase/functions/receive-emails/index.ts` (Line 1)

### 2.2 Update Schema Documentation

**File**: `supabase/schemas/README.md`
- [ ] **Line 3**: Update description
  ```markdown
  # FROM:
  This directory contains the declarative schema definitions for the Salesurance agentic outreach system.
  
  # TO:
  This directory contains the declarative schema definitions for the NewClient agentic outreach system.
  ```

### 2.3 Update DSGVO Footer (if applicable)

**File**: `supabase/functions/send-email/index.ts`
- [ ] **Lines 30-35**: Update compliance footer if needed
  ```typescript
  # FROM:
  const DSGVO_FOOTER = `
  <br><br>
  <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
  <strong>DSGVO/GDPR Compliance:</strong> You are receiving this email because we believe it may be of interest to your business.
  
  # TO:
  const COMPLIANCE_FOOTER = `
  <br><br>
  <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
  <strong>Privacy Notice:</strong> You are receiving this email because we believe it may be of interest to your business.
  ```

## 3. Workflow Configuration

### 3.1 Update n8n Credentials

**File**: `workflows/outreach-bulk.json`
- [ ] **Replace all instances**: Change credential names
  ```json
  # FROM:
  "name": "salesurance_supabase"
  
  # TO:
  "name": "newclient_supabase"
  ```
- [ ] **Line 588**: Update workflow name
  ```json
  # FROM:
  "name": "salesurance"
  
  # TO:
  "name": "newclient"
  ```

### 3.2 Update AI Agent Instructions

**File**: `workflows/xml-instructions/outreach_agent.xml`
- [ ] **Line 5**: Update task description
  ```xml
  # FROM:
  <Task>Transform agency intelligence into compelling, personalized LinkedIn and email messages targeting German marketing agencies for Salesurance's white-label local SEO platform</Task>
  
  # TO:
  <Task>Transform prospect intelligence into compelling, personalized LinkedIn and email messages targeting [TARGET_MARKET] for NewClient's [PRODUCT_NAME]</Task>
  ```

- [ ] **Line 22**: Update product description
  ```xml
  # FROM:
  <OurProduct>White-label Standortmarketing-Plattform für Marketing-Agenturen zur Skalierung ihrer Local-SEO-Services mit 60+ Publishern (GMB, Apple, Bing, Facebook, etc.)</OurProduct>
  
  # TO:
  <OurProduct>[NEW_PRODUCT_DESCRIPTION]</OurProduct>
  ```

- [ ] **Update all rules and instructions**: Adapt targeting, language, and business logic to new client

**File**: `workflows/xml-instructions/research-agent.xml`
- [ ] **Line 6**: Update goal description
  ```xml
  # FROM:
  <Goal>Provide high-quality, verified agency information that enables creation of hyper-personalized messages with 15%+ response rates for Salesurance's white-label platform</Goal>
  
  # TO:
  <Goal>Provide high-quality, verified prospect information that enables creation of hyper-personalized messages with high response rates for NewClient's [PRODUCT_NAME]</Goal>
  ```

- [ ] **Update search strategy**: Modify search queries to match new target market
- [ ] **Update output structure**: Adapt fields to new business model

### 3.3 Update Workflow JSON (Embedded Instructions)

**File**: `workflows/outreach-bulk.json`
- [ ] **Lines 234-250**: Update embedded AI agent instructions in JSON
  - Replace all Salesurance references
  - Update product descriptions
  - Modify target market references
  - Adapt value propositions

## 4. Infrastructure Changes

### 4.1 Repository Configuration

**File**: `.git/config`
- [ ] **Line 9**: Update repository URL
  ```
  # FROM:
  url = https://github.com/nickgarreis/salesurance.git
  
  # TO:
  url = https://github.com/user/newclient-outreach.git
  ```

### 4.2 MCP Configuration

**File**: `.mcp.json`
- [ ] **Line 18**: Update Supabase project ID (if using different project)
  ```json
  # FROM:
  "--project-ref=ejlnibieoldtlaoymzvy"
  
  # TO:
  "--project-ref=NEW_PROJECT_ID"
  ```

### 4.3 CLAUDE.md Configuration

**File**: `CLAUDE.md`
- [ ] **Line 64**: Update Supabase project ID
  ```markdown
  # FROM:
  - **Main Branch Project ID**: `ejlnibieoldtlaoymzvy`
  
  # TO:
  - **Main Branch Project ID**: `NEW_PROJECT_ID`
  ```

## 5. Documentation Updates

### 5.1 Project Description

**File**: `project-description.md`
- [ ] **Complete replacement**: Rewrite entire file for new client
  - Company overview
  - Product description
  - Business challenge
  - Solution strategy
  - Target market
  - Value propositions
  - Success metrics

### 5.2 README.md Updates

**File**: `README.md`
- [ ] **Line 61**: Update clone URL
  ```bash
  # FROM:
  git clone https://github.com/nickgarreis/agentic_marketing_system.git
  
  # TO:
  git clone https://github.com/user/newclient-outreach.git
  ```

- [ ] **Line 108**: Update project structure path
  ```
  # FROM:
  Salesurance/
  
  # TO:
  NewClient/
  ```

- [ ] **Update all examples**: Replace Salesurance-specific examples with new client examples

### 5.3 XML Documentation

**File**: `docs/xml-instructions/xml-integration-guide.md`
- [ ] **Line 6**: Update relevant files reference
  ```markdown
  # FROM:
  **Relevant files**: `docs/xml-instructions/xml-instructions-best-practices.md`, `docs/xml-instructions/xml-templates.md`, `supabase/config.toml`, `workflows/outreach-bulk.json`
  
  # TO:
  **Relevant files**: `docs/xml-instructions/xml-instructions-best-practices.md`, `docs/xml-instructions/xml-templates.md`, `supabase/config.toml`, `workflows/outreach-bulk.json`
  ```

- [ ] **Lines 241-271**: Update language and cultural requirements if changed

**Files**: `docs/xml-instructions/xml-templates.md`, `docs/xml-instructions/xml-instructions-best-practices.md`
- [ ] **Update relevant files references**: Change workflow paths if needed
- [ ] **Update examples**: Replace Salesurance examples with new client examples

## 6. Testing & Verification

### 6.1 Search for Remaining References

Run these commands to find any missed references:

```bash
# Search for company name (case insensitive)
grep -r -i "salesurance" . --exclude-dir=.git

# Search for old email
grep -r "marian@salesurance.co" . --exclude-dir=.git

# Search for old domain
grep -r "salesurance.co" . --exclude-dir=.git

# Search for old product references
grep -r -i "white-label.*seo\|standortmarketing" . --exclude-dir=.git

# Search for old market references  
grep -r -i "marketing.*agenc" . --exclude-dir=.git
```

## 7. Post-Migration Checklist

### 7.1 Final Verification

- [ ] **No old references**: All searches return empty (except historical migration files)
- [ ] **Database functional**: Can create campaigns, leads, send emails
- [ ] **Workflows functional**: n8n processes run without errors
- [ ] **AI agents working**: Generate appropriate content for new client
- [ ] **Email delivery**: Test emails send and receive properly

### 7.2 Documentation

- [ ] **Update this guide**: Note any steps that were missed or unclear
- [ ] **Create deployment notes**: Document any client-specific deployment requirements
- [ ] **Update team**: Inform team of new configuration and credentials

### 7.3 Security

- [ ] **Rotate credentials**: Generate new API keys for production
- [ ] **Review permissions**: Ensure access controls are appropriate
- [ ] **Backup configuration**: Save working configuration for rollback if needed

## Common Gotchas

### ⚠️ Watch Out For:

1. **Embedded JSON strings**: AI instructions embedded in workflow JSON files
2. **File path comments**: Header comments in all code files
3. **Migration file references**: Previous migrations may reference old emails
4. **Case sensitivity**: Some references may be capitalized differently
5. **Language-specific content**: German vs English content requirements
6. **Timezone settings**: May need adjustment for different regions
7. **API rate limits**: Different clients may have different usage patterns
8. **Compliance requirements**: GDPR, CCPA, industry-specific regulations

## Support

If you encounter issues during migration:

1. **Check this guide**: Ensure all steps were followed
2. **Search for references**: Use grep commands to find missed items
3. **Test incrementally**: Don't change everything at once
4. **Keep backups**: Save working state before major changes
5. **Document issues**: Update this guide with any new findings