require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = Project.create!(name: "Alpha Project")
    @standalone_note = Note.create!(title: "Note A", body: "# Standalone Body")
    @project_note = Note.create!(project: @project, title: "Note AA", body: "# Assigned Body")
  end

  test "should get index with standalone scope by default" do
    get notes_url
    assert_response :success
    assert_select "h1", text: /Standalone Notes/
    assert_select "a", text: @standalone_note.title
  end

  test "should get index with all scope" do
    get notes_url(scope: "all")
    assert_response :success
    assert_select "h1", text: /All Notes/
    assert_select "a", text: @standalone_note.title
    assert_select "a", text: @project_note.title
  end

  test "should search notes" do
    get notes_url(q: "Assigned")
    assert_response :success
    assert_select "a", text: @project_note.title
  end

  test "should get show with rendered markdown" do
    get note_url(@standalone_note)
    assert_response :success
    assert_select "h1", text: @standalone_note.title
    assert_select "#rendered_markdown_container h1", text: "Standalone Body"
  end

  test "should get new" do
    get new_note_url
    assert_response :success
  end

  test "should create standalone note" do
    assert_difference("Note.count") do
      post notes_url, params: { note: { title: "New Note", body: "Sample body" } }
    end

    new_note = Note.last
    assert_nil new_note.project_id
    assert_redirected_to note_url(new_note)
  end

  test "should create note assigned to project" do
    assert_difference("Note.count") do
      post notes_url, params: { note: { title: "Assigned Note", body: "Body", project_id: @project.id } }
    end

    new_note = Note.last
    assert_equal @project.id, new_note.project_id
    assert_redirected_to note_url(new_note)
  end

  test "should update note via HTML" do
    patch note_url(@standalone_note), params: { note: { title: "Renamed Title", body: "Updated **markdown**" } }
    assert_redirected_to note_url(@standalone_note)
    assert_equal "Renamed Title", @standalone_note.reload.title
  end

  test "should update note via JSON for auto-save" do
    patch note_url(@standalone_note, format: :json), params: { note: { body: "Auto-saved content" } }
    assert_response :ok
    assert_equal "Auto-saved content", @standalone_note.reload.body
  end

  test "should attach files via ActiveStorage endpoint" do
    FileUtils.mkdir_p(Rails.root.join("test/fixtures/files"))
    File.write(Rails.root.join("test/fixtures/files/sample.txt"), "Sample note attachment content")
    file = fixture_file_upload("sample.txt", "text/plain")

    assert_difference("@standalone_note.files.count", 1) do
      post attach_files_note_url(@standalone_note), params: { files: [ file ] }
    end

    assert_redirected_to note_url(@standalone_note)
    assert_equal "sample.txt", @standalone_note.files.last.filename.to_s
  end

  test "should purge attachment" do
    FileUtils.mkdir_p(Rails.root.join("test/fixtures/files"))
    File.write(Rails.root.join("test/fixtures/files/sample.txt"), "Sample note attachment content")
    file = fixture_file_upload("sample.txt", "text/plain")
    @standalone_note.files.attach(file)
    attachment = @standalone_note.files.last

    assert_difference("@standalone_note.files.count", -1) do
      delete attachment_note_url(@standalone_note, attachment.id)
    end

    assert_redirected_to note_url(@standalone_note)
  end

  test "should destroy note" do
    assert_difference("Note.count", -1) do
      delete note_url(@standalone_note)
    end

    assert_redirected_to root_url
  end

  test "should toggle pin for note" do
    assert_not @standalone_note.pinned?
    patch toggle_pin_note_url(@standalone_note)
    assert_redirected_to note_url(@standalone_note)
    assert @standalone_note.reload.pinned?

    patch toggle_pin_note_url(@standalone_note, format: :json)
    assert_response :ok
    assert_not @standalone_note.reload.pinned?
  end

  test "should reorder pinned notes" do
    n1 = Note.create!(title: "N1", pinned: true, pinned_position: 1)
    n2 = Note.create!(title: "N2", pinned: true, pinned_position: 2)

    patch reorder_pinned_notes_url(format: :json), params: { note_ids: [ n2.id, n1.id ] }
    assert_response :ok

    assert_equal 1, n2.reload.pinned_position
    assert_equal 2, n1.reload.pinned_position
  end

  test "sidebar displays project names without nested notes" do
    get notes_url
    assert_response :success
    # Projects header and project name are present
    assert_select "span", text: "Projects"
    assert_select "span", text: @project.name
    # Project notes are not nested in sidebar
    assert_select "nav a", text: /↳/, count: 0
  end

  test "sidebar displays clickable Standalone Notes and Pinned Notes" do
    @standalone_note.toggle_pin!
    get notes_url
    assert_response :success

    assert_select "nav a[href=?]", notes_path(scope: "standalone"), text: /Standalone Notes/
    assert_select "span", text: "Pinned Notes"
    assert_select "[data-controller='pinned-sortable'] a", text: @standalone_note.title
  end
end
