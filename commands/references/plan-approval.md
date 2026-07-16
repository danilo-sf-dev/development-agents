# Reference: Plan Approval & Output

**Used by**: `/sdd.plan` Step 7.

### Step 7: Approval & Output

**BEFORE asking for approval, ALWAYS display full task list:**

1. Run display script (deterministic, ensures user sees all tasks):
   ```bash
   bash development-agents/framework/tools/state/display-tasks.sh sdd/wip/[feature]/3-tasks/tasks.json
   ```

2. Display the output **based on user profile**:

   <!-- PROFILE: TECHNICAL_ONLY -->
   **Technical Profile Display**:
   ```
   ## Tasks for Approval

   | ID | Title | Layer | Complexity | Dependencies |
   |----|-------|-------|------------|--------------|
   | TASK-001 | Setup project structure | 1 | Low | - |
   | TASK-002 | Create domain entities | 1 | Medium | TASK-001 |
   | TASK-003 | Implement REST endpoints | 1 | Medium | TASK-002 |
   | TASK-004 | Add KeyValueStore integration | 2 | Medium | TASK-003 |
   | TASK-005 | Performance review | 3 | Low | TASK-004 |
   | TASK-006 | Security review | 3 | Low | TASK-004 |

   **Total: 6 tasks**

   ### Layer Summary
   - Layer 1 (Local): 3 tasks
   -    - Layer 3 (Quality): 2 tasks
   ```

   <!-- PROFILE: NON_TECHNICAL_ONLY -->
   **Non-Technical Profile Display**:
   ```
   ## Plan de Implementación

   | Paso | Qué se hace | Esfuerzo |
   |------|-------------|----------|
   | 1 | Configuración inicial del proyecto | Sencillo |
   | 2 | Crear estructura de datos | Moderado |
   | 3 | Implementar funcionalidad principal | Moderado |
   | 4 | Conectar con servicios de plataforma | Moderado |
   | 5 | Revisión de calidad | Sencillo |

   **Total: 5 pasos**

   ✓ Estrategia: Recomendada (el agente optimizará automáticamente)
   ```

3. **THEN** ⛔ INVOKE TOOL (do not print this, CALL the tool):

   ```
   AskUserQuestion(
     questions=[{
       "question": "Approve these tasks?",
       "header": "Tasks",
       "options": [
         {"label": "Yes, approve", "description": "Approve tasks and continue"},
         {"label": "Adjust tasks", "description": "Modify task list before approving"},
         {"label": "Cancel", "description": "Cancel task generation"}
       ],
       "multiSelect": false
     }]
   )
   ```
   > **Non-technical profile**: Options simplified to "Sí, continuar" / "Ajustar" / "Cancelar"

4. If approved:
   - Validate tasks (see Validation Checks)
   - Write `tasks.json` to `sdd/wip/[feature]/3-tasks/`
   - Update `meta.md` with execution strategy
   - Set `Current Stage: tests` (next gate: `/sdd.test`)
   - Output success message
