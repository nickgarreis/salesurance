# Agentic Marketing System

**AI-Powered Email Outreach Automation Platform**

## 🚀 Key Features

- **Automated Email Campaigns** - Set up and manage multi-step email sequences
- **AI-Driven Personalization** - Generate personalized messages using OpenRouter AI models
- **Lead Discovery & Research** - Automated lead qualification and research
- **Email Threading** - Maintain conversation context across email exchanges
- **GDPR/DSGVO Compliance** - Built-in compliance features and unsubscribe handling
- **Real-time Webhooks** - Process email events and responses instantly
- **Scheduled Messaging** - Cron-based automatic email sending
- **Multi-Environment** - Separate production and development environments

## 🛠 Tech Stack

- **Backend**: Supabase (PostgreSQL, Edge Functions, Cron Jobs)
- **Workflow Automation**: n8n (self-hosted on Render)
- **Email Provider**: Resend API
- **AI Models**: OpenRouter API
- **Deployment**: Render.com (Frankfurt region)
- **Runtime**: Deno for edge functions
- **Database**: PostgreSQL 15

## 🏗 Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Supabase      │    │      n8n        │    │   Resend API    │
│                 │    │                 │    │                 │
│ • Database      │◄───┤ • Workflows     │────┤ • Email Sending │
│ • Edge Functions│    │ • Automation    │    │ • Webhooks      │
│ • Cron Jobs     │    │ • Triggers      │    │ • Tracking      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  OpenRouter AI  │
                    │                 │
                    │ • Message Gen   │
                    │ • Research      │
                    │ • Strategy      │
                    └─────────────────┘
```

## 📋 Prerequisites

- Node.js 18+
- Supabase CLI
- Docker (for local n8n development)
- Render account
- OpenRouter API key
- Resend API key

## ⚡ Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/nickgarreis/agentic_marketing_system.git
cd agentic_marketing_system
```

### 2. Install Dependencies
```bash
npm install
pip install -r requirements.txt
```

### 3. Environment Setup
```bash
# Copy environment template
cp .env.example .env

# Configure required variables
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
OPENROUTER_API_KEY=your_openrouter_key
RESEND_API_KEY=your_resend_key
```

### 4. Supabase Setup
```bash
# Login to Supabase
supabase login

# Initialize project
supabase init

# Run migrations
supabase db push
```

### 5. Deploy to Render
```bash
# Push to GitHub
git push origin main

# Deploy using render.yaml configuration
# Production: main branch
# Development: dev branch
```

## 📁 Project Structure

```
pokale_meier/
├── supabase/                   # Database & edge functions
│   ├── functions/              # Edge function handlers
│   │   ├── receive-emails/     # Email webhook receiver
│   │   ├── resend-webhook/     # Resend event processor
│   │   └── send-email/         # Email sending function
│   ├── migrations/             # Database migrations
│   └── schemas/                # Declarative schema files
│       ├── 01-extensions.sql   # Database extensions
│       ├── 02-tables.sql       # Table definitions
│       ├── 03-indexes.sql      # Database indexes
│       ├── 04-functions.sql    # PL/pgSQL functions
│       ├── 05-triggers.sql     # Database triggers
│       └── 06-cron-jobs.sql    # Scheduled jobs
├── pokale_meier/               # AI instructions & workflows
│   ├── instructions/           # XML prompts for AI agents
│   │   ├── outreach_strategy.xml
│   │   ├── research.xml
│   │   └── write_messages.xml
│   └── workflows/              # n8n workflow definitions
│       └── outreach.json
├── render.yaml                 # Render deployment config
├── Dockerfile.n8n             # n8n Docker configuration
├── requirements.txt            # Python dependencies
└── CLAUDE.md                  # AI assistant guidelines
```

## 🔧 Environment Variables

## 🗄 Database Schema

### Core Tables

- **campaigns** - Email campaign configurations and settings
- **leads** - Target prospects and their information
- **messages** - Individual email messages and templates
- **email_events** - Email delivery and interaction tracking

### Key Relationships

```sql
campaigns (1) ──► (n) leads
leads (1) ──► (n) messages
messages (1) ──► (n) email_events
```

### Automated Triggers

- **Campaign Processing** - Auto-schedules messages when leads are added
- **Email Threading** - Maintains conversation chains
- **Event Tracking** - Records email opens, clicks, and replies

## 🔌 API Endpoints

### Edge Functions

| Endpoint | Method | Purpose | Auth |
|----------|--------|---------|------|
| `/functions/v1/send-email` | POST | Send individual emails | Required |
| `/functions/v1/receive-emails` | POST | Process incoming emails | Webhook |
| `/functions/v1/resend-webhook` | POST | Handle Resend events | Webhook |

## 👨‍💻 Development Workflow

### Branch Strategy

- **main** - Production environment
- **dev** - Development environment 