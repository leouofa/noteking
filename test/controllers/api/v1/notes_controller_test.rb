require "test_helper"

class Api::V1::NotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = Project.create!(name: "API Studio")
    @standalone_note = Note.create!(title: "Standalone Note", body: "# Markdown Header\nSome *content*")
    @assigned_note = Note.create!(project: @project, title: "Assigned Note", body: "Assigned note body")
    @pinned_note = Note.create!(title: "Pinned Note", body: "Important content", pinned: true, pinned_position: 1)
  end

  test "GET /api/v1/notes lists all notes" do
    get api_v1_notes_url, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("notes")
    assert json.key?("meta")
    assert_equal 3, json["meta"]["total_count"]
    titles = json["notes"].map { |n| n["title"] }
    assert_includes titles, @standalone_note.title
    assert_includes titles, @assigned_note.title
    assert_includes titles, @pinned_note.title
  end

  test "GET /api/v1/notes filters by project_id" do
    get api_v1_notes_url, params: { project_id: @project.id }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["notes"].size
    assert_equal @assigned_note.title, json["notes"].first["title"]
  end

  test "GET /api/v1/notes filters by standalone scope" do
    get api_v1_notes_url, params: { scope: "standalone" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    titles = json["notes"].map { |n| n["title"] }
    assert_includes titles, @standalone_note.title
    assert_includes titles, @pinned_note.title
    refute_includes titles, @assigned_note.title
  end

  test "GET /api/v1/notes filters by pinned state" do
    get api_v1_notes_url, params: { pinned: "true" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["notes"].size
    assert_equal @pinned_note.title, json["notes"].first["title"]
  end

  test "GET /api/v1/notes searches by keyword" do
    get api_v1_notes_url, params: { q: "Markdown" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["notes"].size
    assert_equal @standalone_note.title, json["notes"].first["title"]
  end

  test "GET /api/v1/notes/:id returns note details and attachments" do
    get api_v1_note_url(@standalone_note), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @standalone_note.id, json["id"]
    assert_equal "Standalone Note", json["title"]
    assert_equal @standalone_note.body, json["body"]
    assert json.key?("attachments")
    assert_equal 0, json["attachments"].size
  end

  test "GET /api/v1/notes/:id with render_markdown=true includes rendered_html" do
    get api_v1_note_url(@standalone_note), params: { render_markdown: "true" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("rendered_html")
    assert_includes json["rendered_html"], "<h1>Markdown Header</h1>"
    assert_includes json["rendered_html"], "<em>content</em>"
  end

  test "POST /api/v1/notes creates a note" do
    assert_difference("Note.count", 1) do
      post api_v1_notes_url, params: {
        note: {
          title: "New API Note",
          body: "Note contents here",
          project_id: @project.id,
          pinned: false
        }
      }, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New API Note", json["title"]
    assert_equal "Note contents here", json["body"]
    assert_equal @project.id, json["project_id"]
    assert_equal "API Studio", json["project_name"]
  end

  test "POST /api/v1/notes with invalid params returns 422" do
    assert_no_difference("Note.count") do
      post api_v1_notes_url, params: { note: { title: "" } }, as: :json
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "Validation failed", json["error"]
    assert_includes json["details"], "Title can't be blank"
  end

  test "PATCH /api/v1/notes/:id updates note" do
    patch api_v1_note_url(@standalone_note), params: {
      note: {
        title: "Updated Title",
        body: "Updated Body"
      }
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated Title", json["title"]
    assert_equal "Updated Body", json["body"]
    assert_equal "Updated Title", @standalone_note.reload.title
  end

  test "DELETE /api/v1/notes/:id deletes note" do
    assert_difference("Note.count", -1) do
      delete api_v1_note_url(@standalone_note), as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
  end

  test "PATCH /api/v1/notes/:id/toggle_pin toggles pin state" do
    # Currently unpinned -> should become pinned
    patch toggle_pin_api_v1_note_url(@standalone_note), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal true, json["pinned"]
    assert_not_nil json["pinned_position"]
    assert @standalone_note.reload.pinned?

    # Toggle again -> should become unpinned
    patch toggle_pin_api_v1_note_url(@standalone_note), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal false, json["pinned"]
    assert_nil json["pinned_position"]
    refute @standalone_note.reload.pinned?
  end

  test "PATCH /api/v1/notes/reorder_pinned reorders pinned notes" do
    note2 = Note.create!(title: "Second Pinned", pinned: true, pinned_position: 2)

    patch reorder_pinned_api_v1_notes_url, params: { note_ids: [ note2.id, @pinned_note.id ] }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
    assert_equal 1, note2.reload.pinned_position
    assert_equal 2, @pinned_note.reload.pinned_position
  end
end
