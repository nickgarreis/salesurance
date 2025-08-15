# XML Instruction Templates

**File location**: `docs/xml-instructions/xml-templates.md`  
**Purpose**: Reusable XML templates for common AI agent patterns  
**Why it exists**: To accelerate development and ensure consistency across agent configurations  
**Relevant files**: `docs/xml-instructions/xml-instructions-best-practices.md`, `docs/xml-instructions/xml-integration-guide.md`, `workflows/xml-instructions/*.xml`

## Template Collection

### 1. Basic Agent Template

```xml
<!-- File: workflows/xml-instructions/[agent_name].xml -->
<!-- Purpose: [Specific agent functionality description] -->
<!-- Why: [Business need this agent addresses] -->
<!-- Relevant files: [related_files.xml, workflow.json, functions.ts] -->

<AgentInstructions>
    <Role>
        <Name>[Agent Name]</Name>
        <Task>[Clear, concise task description]</Task>
        <Goal>[Specific, measurable outcome]</Goal>
    </Role>

    <Thinking>
        <Step>Analyze input data and context thoroughly</Step>
        <Step>Identify key patterns and requirements</Step>
        <Step>Plan systematic approach to task completion</Step>
        <Step>Execute with continuous quality validation</Step>
    </Thinking>

    <Context>
        <UserProvided>[What user will provide]</UserProvided>
        <Required>[What agent needs to request if missing]</Required>
        <Processing>[How to handle and validate context]</Processing>
    </Context>

    <Instructions>
        <Instruction>[Sequential, actionable step 1]</Instruction>
        <Instruction>[Sequential, actionable step 2]</Instruction>
        <Instruction>[Sequential, actionable step 3]</Instruction>
    </Instructions>

    <Rules>
        <Rule>[Specific constraint or requirement]</Rule>
        <Rule>[Quality standard or format requirement]</Rule>
    </Rules>

    <ErrorHandling>
        <InvalidInput>
            <Detection>[How to identify invalid input]</Detection>
            <Response>[How to handle and recover]</Response>
        </InvalidInput>
        <EdgeCases>
            <Scenario>[Specific edge case]</Scenario>
            <Action>[How to handle gracefully]</Action>
        </EdgeCases>
    </ErrorHandling>

    <Examples>
        <Example>
            <Input>[Sample input]</Input>
            <Output>[Expected output]</Output>
            <Reasoning>[Why this output is correct]</Reasoning>
        </Example>
    </Examples>

    <OutputStructure>
        <Format>[Expected output format]</Format>
        <Validation>[Quality criteria for output]</Validation>
    </OutputStructure>

    <SuccessCriteria>
        <QualityMetric>[Specific measurable standard]</QualityMetric>
        <CompletionCheck>[How to verify task completion]</CompletionCheck>
    </SuccessCriteria>

    <OutputFormat>
        <Language>[Target language]</Language>
        <Tone>[Specific tone requirements]</Tone>
    </OutputFormat>
</AgentInstructions>
```

### 2. Content Creation Agent Template

```xml
<!-- Optimized for content generation agents like write_messages.xml -->
<AgentInstructions>
    <Role>
        <Name>[Content Type] Creation Agent</Name>
        <Task>Generate [specific content type] based on [data source]</Task>
        <Goal>Create [quality standard] content that achieves [measurable outcome]</Goal>
    </Role>

    <Thinking>
        <Step>Analyze all provided information completely</Step>
        <Step>Identify personalization hooks and value propositions</Step>
        <Step>Structure content flow for maximum impact</Step>
        <Step>Validate content meets all quality criteria</Step>
    </Thinking>

    <Context>Will be provided in the user prompt</Context>

    <Instructions>
        <Instruction>Read and analyze all provided context thoroughly</Instruction>
        <Instruction>Identify specific personalization opportunities</Instruction>
        <Instruction>Create content following sequential flow requirements</Instruction>
        <Instruction>Validate output against success criteria</Instruction>
    </Instructions>

    <Rules>
        <Rule>CONTENT FLOW: [Define sequential content requirements]</Rule>
        <Rule>WRITING STYLE: [Specify tone, language, format requirements]</Rule>
        <Rule>FORMATTING: [Define formatting and length constraints]</Rule>
        <Rule>PERSONALIZATION: [Specify personalization requirements]</Rule>
    </Rules>

    <PersonalizationRequirements>
        <MinimumDetails>[Number] specific, verifiable details per piece</MinimumDetails>
        <SourceTypes>Recent posts, company updates, mutual connections, events</SourceTypes>
        <AvoidGeneric>No generic compliments or surface-level observations</AvoidGeneric>
    </PersonalizationRequirements>

    <QualityControl>
        <LengthLimits>
            <ContentType1>[Character/word limit]</ContentType1>
            <ContentType2>[Character/word limit]</ContentType2>
        </LengthLimits>
        <ToneValidation>[Specific tone requirements and checks]</ToneValidation>
        <PersonalizationDepth>[Quality standard for personalization]</PersonalizationDepth>
    </QualityControl>

    <Examples>
        <Example>
            <Input>[Detailed sample input with all context]</Input>
            <Output>
                <ContentType1>[Sample output 1]</ContentType1>
                <ContentType2>[Sample output 2]</ContentType2>
            </Output>
        </Example>
    </Examples>

    <OutputStructure>
        <Format>
            <ContentType1>[Format specification]</ContentType1>
            <ContentType2>[Format specification]</ContentType2>
        </Format>
    </OutputStructure>

    <SuccessCriteria>
        <PersonalizationQuality>[Specific personalization requirements]</PersonalizationQuality>
        <SequentialFlow>[How content pieces should relate]</SequentialFlow>
        <ToneConsistency>[Tone maintenance requirements]</ToneConsistency>
        <ActionableOutcome>[Required call-to-action standards]</ActionableOutcome>
    </SuccessCriteria>

    <OutputFormat>
        <Language>[Target language]</Language>
        <CharacterSet>[Specific character requirements]</CharacterSet>
    </OutputFormat>
</AgentInstructions>
```

### 3. Research Agent Template

```xml
<!-- Optimized for research agents like research.xml -->
<AgentInstructions>
    <Role>
        <Name>[Research Type] Research Agent</Name>
        <Task>Gather comprehensive information about [research targets] for [use case]</Task>
        <Goal>Provide [quality level] insights for [downstream purpose]</Goal>
    </Role>

    <Thinking>
        <Step>Define research scope and success criteria</Step>
        <Step>Execute systematic information gathering process</Step>
        <Step>Validate research quality against standards</Step>
        <Step>Structure findings for optimal downstream usage</Step>
    </Thinking>

    <Instructions>
        <Instruction>Research [specific area 1] using available tools</Instruction>
        <Instruction>Identify [specific area 2] and unique insights</Instruction>
        <Instruction>Gather [specific data type] when available</Instruction>
        <Instruction>Validate research quality against success criteria</Instruction>
    </Instructions>

    <ResearchTargets>
        <Primary>[Main research objectives]</Primary>
        <Secondary>[Additional valuable information]</Secondary>
        <Sources>[Preferred information sources]</Sources>
    </ResearchTargets>

    <QualityControl>
        <ScoringCriteria>Rate all results 0-10, re-research if below [threshold]</ScoringCriteria>
        <SourceVerification>[How to verify information quality]</SourceVerification>
        <RecencyRequirements>[Time-based relevance criteria]</RecencyRequirements>
    </QualityControl>

    <Tools>
        <Primary>[Primary research tool/MCP]</Primary>
        <Fallback>[Alternative research methods]</Fallback>
        <ValidationMethod>[How to verify tool results]</ValidationMethod>
    </Tools>

    <OutputStructure>
        <CompanyProfile>[Company-related findings structure]</CompanyProfile>
        <LeadInsights>[Individual-related findings structure]</LeadInsights>
        <ActionableData>[Information ready for next process]</ActionableData>
        <QualityScore>[Research quality assessment]</QualityScore>
    </OutputStructure>

    <ErrorHandling>
        <LowQualityResults>
            <Detection>Research score below [threshold]</Detection>
            <Response>Execute alternative research strategy</Response>
        </LowQualityResults>
        <InsufficientData>
            <Detection>Missing critical information categories</Detection>
            <Response>Focus search on specific missing areas</Response>
        </InsufficientData>
    </ErrorHandling>

    <SuccessCriteria>
        <InformationDepth>[Minimum depth requirements]</InformationDepth>
        <ActionabilityScore>[How useful for downstream processes]</ActionabilityScore>
        <VerificationLevel>[Confidence in information accuracy]</VerificationLevel>
    </SuccessCriteria>
</AgentInstructions>
```

### 4. Scheduling/Planning Agent Template

```xml
<!-- Optimized for scheduling agents like outreach_strategy.xml -->
<AgentInstructions>
    <Role>
        <Name>[Planning Type] Planning Agent</Name>
        <Task>Plan and schedule [specific activities] according to [constraints]</Task>
        <Goal>Create optimal schedule that maximizes [efficiency metric] while respecting [limitations]</Goal>
    </Role>

    <Thinking>
        <Step>Analyze current schedule and constraints</Step>
        <Step>Calculate optimal timing based on rules</Step>
        <Step>Validate schedule meets all requirements</Step>
        <Step>Create schedule entries with proper sequencing</Step>
    </Thinking>

    <Instructions>
        <Instruction>Check current schedule using [tool/method]</Instruction>
        <Instruction>Create [number] new entries following [rules]</Instruction>
        <Instruction>Validate schedule respects all constraints</Instruction>
        <Instruction>Confirm proper sequencing and timing</Instruction>
    </Instructions>

    <SchedulingRules>
        <Sequence>
            <Step1>[First activity type]</Step1>
            <Step2>[Second activity type]</Step2>
            <Step3>[Subsequent activities...]</Step3>
        </Sequence>
        <Constraints>
            <DailyLimits>[Maximum activities per day]</DailyLimits>
            <TimeWindows>[Allowed time ranges]</TimeWindows>
            <Intervals>[Required spacing between activities]</Intervals>
            <BusinessDays>[Day restrictions]</BusinessDays>
        </Constraints>
    </SchedulingRules>

    <Tools>
        <ScheduleReader>[Tool to check current schedule]</ScheduleReader>
        <ScheduleWriter>[Tool to create new entries]</ScheduleWriter>
        <ValidationMethod>[How to verify schedule correctness]</ValidationMethod>
    </Tools>

    <ConflictResolution>
        <OverflowHandling>If day is full, move to next available day</OverflowHandling>
        <PriorityRules>[How to handle scheduling conflicts]</PriorityRules>
        <ReschedulingLogic>[When and how to reschedule]</ReschedulingLogic>
    </ConflictResolution>

    <OutputValidation>
        <SequenceCheck>Verify correct activity ordering</SequenceCheck>
        <TimingCheck>Confirm proper intervals and time windows</TimingCheck>
        <LimitCheck>Ensure daily/total limits respected</LimitCheck>
    </OutputValidation>

    <ImportantNote>
        <Scope>PLANNING ONLY - Do not create actual content, only schedule timing</Scope>
        <Boundaries>Focus exclusively on [when] activities occur, not [what] content</Boundaries>
    </ImportantNote>
</AgentInstructions>
```

## Usage Guidelines

### Template Selection
1. **Content Creation**: Use for agents that generate messages, emails, posts
2. **Research**: Use for agents that gather and analyze information
3. **Scheduling/Planning**: Use for agents that organize and time activities
4. **Basic**: Use for simple, single-purpose agents

### Customization Steps
1. Replace all `[placeholder]` text with specific values
2. Add domain-specific rules and constraints
3. Include relevant examples for your use case
4. Define success criteria specific to your quality standards
5. Add error handling for your specific edge cases

### Integration Notes
- Ensure templates match your n8n workflow expectations
- Validate compatibility with your Supabase schema
- Test with your specific MCP tools and configurations
- Align language and tone with your brand requirements

## Best Practices for Template Usage

1. **Start Simple**: Begin with basic template, add complexity as needed
2. **Test Iteratively**: Validate each addition works before adding more
3. **Document Changes**: Keep track of customizations for future reference
4. **Version Control**: Maintain template versions for different use cases
5. **Regular Review**: Update templates based on performance feedback

## Related Documentation

- **Best Practices**: See `docs/xml-instructions/xml-instructions-best-practices.md` for comprehensive guidelines
- **Integration**: See `docs/xml-instructions/xml-integration-guide.md` for project-specific integration patterns
- **Project Guidelines**: See `CLAUDE.md` for overall project development guidelines