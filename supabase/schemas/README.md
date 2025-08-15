# Supabase Declarative Schemas

This directory contains the declarative schema definitions for the Salesurance agentic outreach system. These files define the desired state of the database structure and are automatically converted to migrations by Supabase.

## File Organization

The schema files are organized logically and applied in alphabetical order:

1. **01-extensions.sql** - PostgreSQL extensions (uuid-ossp, pg_cron, pg_net)
2. **02-tables.sql** - Complete table definitions with all columns, constraints, and RLS
3. **03-indexes.sql** - Database indexes for query optimization
4. **04-functions.sql** - Database functions for business logic and automation
5. **05-triggers.sql** - Triggers for automatic updates and message scheduling
6. **06-cron-jobs.sql** - Scheduled jobs for automated email processing

## Database Structure

### Core Tables

- **clients** - Client information and status
- **campaigns** - Campaign management with strategy configuration  
- **leads** - Lead/prospect data with research results
- **messages** - Outreach message tracking across channels

### Key Features

- **Automated Message Scheduling** - When leads change to 'processing' status, messages are automatically created based on campaign strategy
- **Business Hours Enforcement** - All messages scheduled only during Mon-Fri 9AM-6PM Berlin time
- **Capacity Management** - Maximum 20 messages per campaign per day with 20-minute intervals
- **Email Tracking** - Integration with Resend API for delivery, open, click tracking
- **Thread Management** - Email threading support for conversation continuity

## Using Declarative Schemas

### Making Changes

1. Edit the appropriate schema file (e.g., `02-tables.sql` for table changes)
2. Generate migration: `supabase db diff -f descriptive_name`
3. Review the generated migration carefully
4. Apply migration: `supabase migration up`

### Best Practices

- Always append new columns to the end of tables
- Review generated migrations before applying
- Test changes in development environment first
- Keep data manipulation (DML) in separate migration files

### Limitations

Some changes must still use traditional migrations:
- Data manipulation (INSERT, UPDATE, DELETE)
- RLS policy modifications
- Complex permission changes
- Comments and schema privileges

## Commands

```bash
# Generate migration from schema changes
supabase db diff -f migration_name

# Apply migrations
supabase migration up

# Reset local database to current migrations
supabase db reset

# Deploy to production
supabase db push
```

## Benefits

- **Single Source of Truth** - Complete database structure visible in one place
- **Better Documentation** - Clear organization and comments
- **Easier Collaboration** - Cleaner diffs and reviews
- **AI-Friendly** - Tools like Claude Code can easily understand the full schema
- **Automatic Migration Generation** - Less manual migration writing