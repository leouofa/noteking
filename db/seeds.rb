# Noteking Seeds:
# Projects -> Project A -> Note AA, Note AB
# Standalone Notes -> Note A, Note B

puts "Seeding Noteking..."

Note.destroy_all
Project.destroy_all

project_a = Project.create!(
  name: "Project A",
  description: "Core engineering notes and architecture decisions"
)

# Notes assigned to Project A
Note.create!(
  project: project_a,
  title: "Note AA",
  body: <<~MARKDOWN
    # ADR 001: Local-First Storage Architecture

    ## Status
    **Accepted** — 2026-11-13

    ## Context
    We need zero-latency, private, and offline-capable note storage without third-party subscription lock-in.

    ## Decision
    Adopt a local PostgreSQL-backed Rails engine with client-side optimistic UI transitions and ActiveStorage attachments.

    ### Action Items:
    - [x] Configure connection pooling for local threads
    - [x] Setup Redcarpet server-side Markdown sanitizer
    - [ ] Evaluate SQLite / SQLite-WASM replication for full offline mode

    ```ruby
    # Example database configuration check
    ActiveRecord::Base.connection_pool.with_connection do |conn|
      puts "Connected to: \#{conn.current_database}"
    end
    ```

    > Simplicity and data ownership are the primary design drivers.
  MARKDOWN
)

Note.create!(
  project: project_a,
  title: "Note AB",
  body: <<~MARKDOWN
    # API Specification & Data Model Reference

    Notes and Projects schema summary for integration endpoints.

    ### Schema Summary:
    | Entity | Field | Type | Description |
    | :--- | :--- | :--- | :--- |
    | `Project` | `name` | string | Workspace title |
    | `Note` | `title` | string | Note headline |
    | `Note` | `body` | text | GFM markdown source |
    | `Note` | `pinned` | boolean | Top-level pin flag |

    ### Planned Endpoints:
    - `GET /api/v1/notes`
    - `GET /api/v1/projects`
    - `POST /api/v1/notes`
  MARKDOWN
)

# Standalone Notes (no project assigned)
Note.create!(
  project: nil,
  title: "Note A",
  body: <<~MARKDOWN
    # Weekly Engineering Sync Notes

    ## Highlights & Discussion
    - Discussed migrating engineering notes to a universal structure
    - Reviewed GFM preview rendering performance on large documents

    ### Key Takeaways:
    1. Keep keyboard shortcuts aligned (`⌘S` save, `⌘\\` toggle sidebar)
    2. Maintain one-click raw markdown copy directly from card previews
    3. Retain drag-and-drop ActiveStorage attachments
  MARKDOWN
)

Note.create!(
  project: nil,
  title: "Note B",
  body: <<~MARKDOWN
    # Reading List & Research Scratchpad

    - [Distributed Systems for Fun and Profit](https://book.mixu.net/distsys/)
    - [Crafting Interpreters](https://craftinginterpreters.com/)
    - [Hotwire Reference Guide](https://hotwired.dev/)

    ```bash
    # Quick benchmark command
    bin/rails test:system
    ```
  MARKDOWN
)

puts "Seeded #{Project.count} projects and #{Note.count} notes successfully!"
