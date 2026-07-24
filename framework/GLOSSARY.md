# SDD Kit - Glossary

Terminology and definitions for Specification-Driven Development.

---

## A

### Acceptance Criteria
Specific, testable conditions that must be met for a feature to be considered complete. Part of the functional specification.

### ADR (Architecture Decision Record)
Document that captures an important architectural decision along with its context and consequences.

### Agent
AI-powered assistant that performs specific tasks within the framework. Examples: sdd-system-designer, sdd-implementer.

### dependency security scanner
Generic term for whatever MCP server/tool your organization uses for security vulnerability detection and dependency scanning (e.g. an internal security team's tool, Snyk, Dependabot, etc.). Not a specific product — configure the one your org actually has.

---

## B

### Backlog
Collection of features or tasks waiting to be implemented. Located in `sdd/backlog/`.

### Brownfield
Existing project with code already written. Opposite of greenfield. Requires `/sdd.reverse-eng` to document.

### Build Phase
Third phase of SDD where code is generated based on specifications.

---

## C

### Claude Code
Anthropic's CLI tool for Platform AI docs-assisted development. Primary supported tool for SDD Kit.

### Command
Framework action triggered by `/sdd.<command>`. Example: `/sdd.start`, `/sdd.build`.

---

## D

### Diataxis
Documentation framework organizing content into: Tutorial, How-to, Reference, Explanation.

### DOCaaS
Documentation as a Service. project's documentation platform.

---

## E

### Express Mode
Autonomous mode (`/sdd.go`) where the agent completes the entire flow with minimal interaction.

### Execution Mode
Framework setting that controls interaction level. Express mode runs autonomously; Standard mode (default) provides balanced control with optional granular flags.

---

## F

### Feature
Unit of work in SDD. Has its own folder in `sdd/wip/` with specifications and tasks.

### Finish Phase
Final phase of SDD where code is validated, tested, and prepared for deployment.

### Functional Specification
Document describing WHAT a feature does from the user's perspective. Contains user stories, acceptance criteria, and business rules.

### 
project's cloud platform for deploying and managing applications.

### 
MCP server providing access to project services information.

---

## G

### Governance
Rules and standards that guide development decisions. Defined in `standards/governance.md`.

### Greenfield
New project starting from scratch. No existing code.

---

## H

### Hook
Script that runs automatically on specific events (session start, tool use, etc.).

---

## K

### KeyValueStore (Key-Value Store)
's distributed key-value storage service. Tier 1 core service.

---

## M

### MCP (Model Context Protocol)
Protocol for Platform AI docs models to interact with external tools and services.

### Meta
Metadata file (`meta.md`) containing feature configuration: mode, testing level, etc.

### project
your team - Latin American e-commerce and fintech company.

---

## P

### Phase
Stage in the SDD workflow: Spec → Plan → Build → Finish.

### Plan Mode (Claude Code)
Native Claude Code feature (`EnterPlanMode`/`ExitPlanMode` tools) that enforces read-only exploration before implementation. Used in `/sdd.fix` for complex bugs and `/sdd.spec technical` for brownfield architecture. **Different from `/sdd.plan`** - Plan Mode is a Claude Code capability for user approval workflows, while `/sdd.plan` is the SDD command for generating tasks from specs.

### Plan Phase
Second phase of SDD where specifications are broken into concrete tasks.

### Progress
Tracking file (`progress.md`) showing feature completion status.

### Prototype Mode
Development mode with no tests, focus on speed. For exploratory work.

---

## R

### Recovery
Process of fixing errors during development. See `RECOVERY.md`.

### Reverse Engineering
Process of documenting existing code (`/sdd.reverse-eng`). Used for brownfield projects.

### Rollback
Reverting to a previous phase. Example: `/sdd.rollback spec`.

---

## S

### SDD (Specification-Driven Development)
Methodology where development follows: Spec → Plan → Test (tests-first gate) → Build → Check → Finish.

### Security Rules
Set of agentic security guidelines that AI agents must follow during code generation and review. Optionally integrated with a dependency security scanner to validate compliance against known vulnerabilities and security best practices. Rules are technology-specific and cover input validation, authentication, secrets management, and other security patterns.

### Skill
Reusable knowledge module for Platform AI docs agents. Located in `.claude/skills/`.

### Spec Phase
First phase of SDD where functional and technical specifications are created.

### Specification
Detailed description of what to build. Two types: functional and technical.

---

## T

### Task
Atomic unit of work within a feature. Listed in `tasks.json`.

### Technical Specification
Document describing HOW a feature is implemented. Contains architecture, APIs, data models.

### Tier
Priority level for project services. Tier 1 (core) → Tier 2 (common) → Tier 3 (specialized).

---

## V

### Validation
Process of checking specifications and code for correctness. Runs in `/sdd.check`.

---

## W

### WIP (Work in Progress)
Active features being developed. Located in `sdd/wip/`.

### Workflow
Sequence of phases and commands in SDD development.

---

## Acronyms / Acrónimos

> **Usage Rule**: First occurrence of any acronym MUST be expanded.
> **Regla de uso**: La primera aparición de cualquier acrónimo DEBE expandirse.

| Acronym | Full Name | Spanish |
|---------|-----------|---------|
| ADR | Architecture Decision Record | Registro de decisión arquitectónica |
| API | Application Programming Interface | API *(mismo en ambos idiomas)* |
| CDC | Change Data Capture | Captura de cambios de datos |
| CI/CD | Continuous Integration/Continuous Deployment | Integración/Despliegue continuo |
| CRUD | Create, Read, Update, Delete | Crear, Leer, Actualizar, Eliminar |
| DOCaaS | Documentation as a Service | DOCaaS *(nombre interno )* |
| E2E | End-to-End | De punta a punta |
| FAQ | Frequently Asked Questions | Preguntas frecuentes |
| KeyValueStore | Key-Value Store | KeyValueStore *(nombre interno )* |
| E2E | Large Testing Platform | Plataforma de pruebas E2E de  |
| MCP | Model Context Protocol | MCP *(mismo en ambos idiomas)* |
| PR | Pull Request | Solicitud de cambios |
| REST | Representational State Transfer | REST *(mismo en ambos idiomas)* |
| SDD | Specification-Driven Development | Desarrollo guiado por especificaciones |
| SDK | Software Development Kit | Kit de desarrollo |
| SLA | Service Level Agreement | Acuerdo de nivel de servicio |
| SLO | Service Level Objective | Objetivo de nivel de servicio |
| TTL | Time To Live | Tiempo de vida |
| WIP | Work in Progress | Trabajo en progreso |

---

## Project-Specific Services

This framework does not hardcode a catalog of internal platform services — every org has
different ones. Document your org's actual services (message queue, cache, key-value store,
object storage, etc.) in `sdd/PROJECT.md`, and the `sdd-system-designer` skill will use that
list when recommending services during `/sdd.spec technical`.

---

## Usage Rules / Reglas de Uso

1. **First occurrence**: Always expand → `Pull Request (PR)`
   - *Primera aparición*: Siempre expandir → `Pull Request (PR)`

2. **Subsequent uses**: Acronym only → `PR`
   - *Usos posteriores*: Solo acrónimo → `PR`

3. **Language match**: Expand in user's language
   - *Coincidir idioma*: Expandir en el idioma del usuario

4. **If unsure**: Ask the user for clarification
   - *Si hay duda*: Preguntar al usuario

---

## References

- **Acronym expansion rules**: Always expand acronyms on first use
-  documentation - Official service names
