# Reference: ASCII Architecture Diagram

**Used by**: `/sdd.spec` Step 6b.1 when presenting the technical summary for approval.

**Step 6b.1: Architecture Diagram (ASCII)**

> **MANDATORY**: After the text summary, generate an ASCII architecture diagram that visually represents the solution. This allows the user to understand the full picture at a glance before approving.

**What to include**:
- Apps/services and their interactions
- Data stores (databases, KeyValueStore, Object Storage)
- Message queues with the full flow: producer app → topic → consumer app
- External service integrations
- Data flow direction with arrows

**Component shapes** (use distinctive shapes per component type):

```
Apps/Services (rectangle):

  ┌──────────────┐
  │ platform_my-app  │
  └──────────────┘


Databases & Storage — MySQL, KeyValueStore, Object Storage (cylinder):

    __________
   /          \
   |  MySQL   |
   |  items   |
   \__________/


Queues/Topics — MessageQueue, KeyValueStore Stream (horizontal tube with segments):

    item-events (MessageQueue)
   ┌──┬──┬──┬──┬──┬──┬──┐
   │  │  │  │  │  │  │  │
   └──┴──┴──┴──┴──┴──┴──┘
```

**Rules**:
- Each component type MUST use its corresponding shape from above
- Arrows (`──▶`, `◀──`, `│`, `▼`) show data flow direction
- Queue topics only contain the topic name and technology type — producers and consumers are separate app boxes
- Keep it compact — focus on component interaction, not internal details
- Adapt complexity to the feature: simple features get simple diagrams

**Example** (feature with Object Storage + KeyValueStore + MessageQueue):

```
                       ┌──────────────┐
                       │ platform_my-app  │
                       └─┬──┬──┬───┬─┘
                         │  │  │   │
         ┌───────────────┘  │  │   └──────────────────────┐
         ▼                  ▼  ▼                           ▼
    __________      __________   _____________   item-events (MessageQueue)
   /          \    /          \ /             \  ┌──┬──┬──┬──┬──┬──┬──┐
   |  MySQL   |    |   KeyValueStore    | | Obj Storage |  │  │  │  │  │  │  │  │
   |  items   |    |   cache  | |    files    |  └──┴──┴──┴──┴──┴──┴──┘
   \__________/    \__________/ \_____________/           │
                                                         ▼
                                                ┌────────────────────┐
                                                │ platform_processor-app │
                                                └────────────────────┘
```

**Example** (simple feature — API + single DB):

```
         ┌──────────────┐
         │ platform_my-app  │
         └──────┬───────┘
                │
                ▼
           __________
          /          \
          |  MySQL   |
          |  users   |
          \__________/
```

**Example** (two apps communicating via MessageQueue):

```
                          order-updates (MessageQueue)
┌──────────────┐         ┌──┬──┬──┬──┬──┬──┬──┐         ┌───────────────────┐
│ platform_my-app  ├────▶    │  │  │  │  │  │  │  │    ────▶│ platform_notifier-app │
└──────────────┘         └──┴──┴──┴──┴──┴──┴──┘         └───────────────────┘
```

> **Note**: The diagram is generated from the technical spec content — it does NOT require additional user input. It's a visual representation of what was already specified in the Architecture,  Services, and Data Model sections.
