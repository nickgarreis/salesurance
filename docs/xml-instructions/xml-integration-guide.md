# XML Instructions Integration Guide

**File location**: `docs/xml-instructions/xml-integration-guide.md`  
**Purpose**: Project-specific guidelines for integrating XML best practices with your tech stack  
**Why it exists**: To ensure XML instructions work seamlessly with Supabase, n8n, and Render deployment  
**Relevant files**: `docs/xml-instructions/xml-instructions-best-practices.md`, `docs/xml-instructions/xml-templates.md`, `supabase/config.toml`, `workflows/outreach-bulk.json`

## Integration Architecture

Your agentic outreach system uses:
- **Supabase**: Database, edge functions, triggers, cron jobs
- **n8n**: Workflow automation (hosted on Render)
- **Render**: Hosting platform
- **MCPs**: Supabase, n8n, and Exa Search integrations

## Supabase Integration Patterns

### Edge Function Compatibility

When creating XML instructions for Supabase edge functions:

```xml
<SupabaseIntegration>
    <EdgeFunctionCalls>
        <Function>send-email</Function>
        <RequiredParams>
            <Param>recipient_email</Param>
            <Param>subject</Param>
            <Param>html_content</Param>
        </RequiredParams>
        <ErrorHandling>Handle CORS, auth, and rate limiting</ErrorHandling>
    </EdgeFunctionCalls>
    
    <DatabaseOperations>
        <Table>campaigns</Table>
        <Operations>INSERT, UPDATE, SELECT</Operations>
        <RequiredColumns>lead_id, message_type, scheduled_at</RequiredColumns>
    </DatabaseOperations>
    
    <AuthContext>
        <Required>service_role key for automated operations</Required>
        <UserContext>RLS policies for user-specific data</UserContext>
    </AuthContext>
</SupabaseIntegration>
```

### Database Schema Awareness

Your XML instructions should understand the current schema:

```xml
<DatabaseSchema>
    <Tables>
        <Table name="campaigns">
            <Columns>id, lead_name, lead_email, company, strategy, info, dsgvo_footer, email, auth</Columns>
            <Purpose>Store campaign configuration and lead data</Purpose>
        </Table>
        <Table name="messages">
            <Columns>id, campaign_id, message_type, content, scheduled_at, sent_at, status</Columns>
            <Purpose>Track scheduled and sent messages</Purpose>
        </Table>
        <Table name="email_threads">
            <Columns>id, campaign_id, thread_id, subject, references, in_reply_to</Columns>
            <Purpose>Maintain email conversation threading</Purpose>
        </Table>
    </Tables>
    
    <Functions>
        <Function name="schedule_next_message">
            <Purpose>Automatically schedule follow-up messages</Purpose>
            <Trigger>After message status update</Trigger>
        </Function>
    </Functions>
</DatabaseSchema>
```

### Migration-Safe Instructions

Since you use schema files instead of direct MCP modifications:

```xml
<DatabaseModifications>
    <Approach>Schema files in supabase/schemas/ directory</Approach>
    <Process>
        <Step>Write changes to schema file</Step>
        <Step>Run: supabase db diff -f change_name</Step>
        <Step>Review generated migration</Step>
        <Step>Apply migration to dev/prod</Step>
    </Process>
    <Restrictions>
        <NoDirectMCP>Never use MCP for database modifications</NoDirectMCP>
        <SchemaFirst>Always update schema files first</SchemaFirst>
    </Restrictions>
</DatabaseModifications>
```

## N8N Workflow Integration

### Workflow Compatibility

XML instructions should align with your n8n workflow structure:

```xml
<N8NIntegration>
    <WorkflowContext>
        <File>workflows/outreach-bulk.json</File>
        <ExpectedInputs>
            <Input>lead_data</Input>
            <Input>campaign_config</Input>
            <Input>message_templates</Input>
        </ExpectedInputs>
        <ExpectedOutputs>
            <Output>personalized_messages</Output>
            <Output>scheduling_data</Output>
            <Output>quality_metrics</Output>
        </ExpectedOutputs>
    </WorkflowContext>
    
    <NodeCompatibility>
        <HTTPNodes>Format API calls for Supabase edge functions</HTTPNodes>
        <CodeNodes>Structure JavaScript-compatible outputs</CodeNodes>
        <AINodes>Prepare prompts for OpenRouter API integration</AINodes>
    </NodeCompatibility>
    
    <ErrorHandling>
        <WorkflowErrors>Return structured error objects for n8n error handling</WorkflowErrors>
        <RetryLogic>Include retry-compatible output formats</RetryLogic>
        <FallbackPaths>Provide alternative outputs for workflow branching</FallbackPaths>
    </ErrorHandling>
</N8NIntegration>
```

### Workflow-Specific Output Formats

Ensure XML instructions generate n8n-compatible outputs:

```xml
<OutputStructure>
    <N8NCompatible>
        <ItemStructure>
            <json>
                <lead_id>{{ $node["Input"].json["lead_id"] }}</lead_id>
                <messages>
                    <linkedin_invite>{{ $json.linkedin_invite }}</linkedin_invite>
                    <linkedin_message>{{ $json.linkedin_message }}</linkedin_message>
                    <email_subject>{{ $json.email_subject }}</email_subject>
                    <email_body>{{ $json.email_body }}</email_body>
                </messages>
                <quality_score>{{ $json.quality_score }}</quality_score>
            </json>
        </ItemStructure>
    </N8NCompatible>
</OutputStructure>
```

## MCP Integration Patterns

### Supabase MCP Usage

Your XML instructions should leverage read-only Supabase MCP access:

```xml
<MCPIntegration>
    <SupabaseMCP>
        <ReadOperations>
            <Tables>campaigns, messages, email_threads</Tables>
            <Functions>List edge functions, get logs, check advisors</Functions>
            <Purpose>Gather context for intelligent decision making</Purpose>
        </ReadOperations>
        <Restrictions>
            <NoWrites>Never use MCP for database modifications</NoWrites>
            <SchemaUpdates>Use migration files instead</SchemaUpdates>
        </Restrictions>
    </SupabaseMCP>
    
    <N8NMCP>
        <NodeInformation>Get available nodes and their configurations</NodeInformation>
        <WorkflowDesign>Create JSON workflows for copy-paste implementation</WorkflowDesign>
        <Validation>Verify workflow structure and node compatibility</Validation>
    </N8NMCP>
    
    <ExaMCP>
        <Research>Lead and company information gathering</Research>
        <Verification>Validate information quality and recency</Verification>
        <SourcePriority>Recent posts, company updates, industry news</SourcePriority>
    </ExaMCP>
</MCPIntegration>
```

### Error Handling for MCP Failures

```xml
<MCPErrorHandling>
    <SupabaseFailures>
        <Timeout>Retry with exponential backoff</Timeout>
        <AuthError>Check service role key configuration</AuthError>
        <RateLimiting>Implement request queuing</RateLimiting>
    </SupabaseFailures>
    
    <ExaFailures>
        <LowQualityResults>Re-search with refined queries</LowQualityResults>
        <NoResults>Use fallback research strategies</NoResults>
        <RateLimiting>Queue requests and retry</RateLimiting>
    </ExaFailures>
    
    <N8NFailures>
        <NodeUnavailable>Use alternative node configurations</NodeUnavailable>
        <ValidationError>Provide simplified workflow structure</ValidationError>
    </N8NFailures>
</MCPErrorHandling>
```

## Render Deployment Considerations

### Environment-Specific Instructions

```xml
<DeploymentContext>
    <Environment>
        <Development>
            <SupabaseProjectId>wnqqioudrzffadjonxpv</SupabaseProjectId>
            <Branch>dev</Branch>
            <TestingMode>Enable verbose logging and validation</TestingMode>
        </Development>
        <Production>
            <OptimizedMode>Reduce logging, optimize performance</OptimizedMode>
            <ErrorHandling>Graceful degradation, user-friendly messages</ErrorHandling>
        </Production>
    </Environment>
    
    <ResourceConstraints>
        <MemoryLimits>Consider Render plan limitations</MemoryLimits>
        <ProcessingTime>Optimize for Render timeout limits</ProcessingTime>
        <NetworkLatency>Account for Europe-US latency in API calls</NetworkLatency>
    </ResourceConstraints>
</DeploymentContext>
```

## Language and Localization

### German-First Design

Your project uses German as primary language:

```xml
<LocalizationPatterns>
    <PrimaryLanguage>German</PrimaryLanguage>
    <ToneRequirements>
        <Formality>Use "Du" form for casual-professional tone</Formality>
        <AvoidBuzzwords>No "revolutionär", "bahnbrechend", generic terms</AvoidBuzzwords>
        <Simplicity>Short sentences, easy-to-understand language</Simplicity>
    </ToneRequirements>
    
    <ContentAdaptation>
        <CompanyNames>Shorten appropriately ("XYZ" not "XYZ Agency")</CompanyNames>
        <Locations>Use colloquial forms ("San Fran" not "San Francisco")</Locations>
        <Cultural>Adapt to German business communication norms</Cultural>
    </ContentAdaptation>
</LocalizationPatterns>
```

## Implementation Checklist

### Before Deploying XML Instructions

- [ ] **Supabase Compatibility**: Verify edge function integration
- [ ] **N8N Workflow**: Test with actual workflow structure
- [ ] **MCP Access**: Confirm read-only operations work correctly
- [ ] **Error Handling**: Test failure scenarios and recovery
- [ ] **Performance**: Validate timing constraints for Render
- [ ] **Localization**: Confirm German language requirements
- [ ] **Schema Alignment**: Check database table compatibility
- [ ] **Output Format**: Verify n8n node input requirements

### Testing Strategy

```xml
<TestingApproach>
    <UnitTesting>
        <Instructions>Test individual instruction components</Instructions>
        <Validation>Verify success criteria are met</Validation>
        <ErrorCases>Test edge case handling</ErrorCases>
    </UnitTesting>
    
    <IntegrationTesting>
        <SupabaseEdgeFunctions>Test function calls and responses</SupabaseEdgeFunctions>
        <N8NWorkflows>Validate workflow compatibility</N8NWorkflows>
        <MCPConnectivity>Verify MCP tool access and responses</MCPConnectivity>
    </IntegrationTesting>
    
    <ProductionValidation>
        <PerformanceMetrics>Response times, success rates</PerformanceMetrics>
        <QualityMetrics>Output quality, personalization depth</QualityMetrics>
        <UserAcceptance>Business outcome achievement</UserAcceptance>
    </ProductionValidation>
</TestingApproach>
```

## Migration Path for Existing Files

### Step-by-Step Modernization

1. **Assessment Phase**
   ```xml
   <CurrentState>
       <File>write_messages.xml</File>
       <HasThinking>Yes</HasThinking>
       <HasErrorHandling>Limited</HasErrorHandling>
       <HasValidation>Basic success criteria</HasValidation>
       <Improvements>Add comprehensive error handling, enhance validation</Improvements>
   </CurrentState>
   ```

2. **Enhancement Phase**
   - Add missing error handling patterns
   - Enhance validation criteria
   - Improve integration compatibility
   - Add comprehensive examples

3. **Validation Phase**
   - Test with existing workflows
   - Verify output quality improvement
   - Confirm backward compatibility

### Gradual Implementation

Start with one file, validate improvements, then apply to others:

```xml
<MigrationStrategy>
    <Phase1>Enhance write_messages.xml with modern patterns</Phase1>
    <Phase2>Update research.xml with improved structure</Phase2>
    <Phase3>Modernize outreach_strategy.xml scheduling logic</Phase3>
    <Phase4>Create new agents using best practice templates</Phase4>
</MigrationStrategy>
```

## Related Documentation

- **Best Practices**: See `docs/xml-instructions/xml-instructions-best-practices.md` for comprehensive guidelines
- **Templates**: See `docs/xml-instructions/xml-templates.md` for reusable XML templates
- **Project Guidelines**: See `CLAUDE.md` for overall project development guidelines

This integration guide ensures your XML instructions work seamlessly with your specific tech stack while maintaining the high-quality standards established in the best practices documentation.