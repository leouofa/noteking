# frozen_string_literal: true

require "test_helper"

class NoteVersionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @note = Note.create!(title: "Architecture v1", body: "# Heading\nInitial line")
    @v1 = @note.latest_version
    @note.update!(title: "Architecture v2", body: "# Heading\nUpdated line\nExtra line")
    @v2 = @note.latest_version
  end

  test "should get versions index and show latest version diff by default" do
    get note_versions_url(@note)
    assert_response :success
    assert_select "h1", text: /Version History/
    assert_select "#version_timeline a", count: 2
    assert_select "#version_diff_container", text: /Updated line/
    assert_select "#title_diff_banner", text: /Architecture v1/
  end

  test "should get specific version in diff, rendered, and raw modes" do
    get note_version_url(@note, @v1, view: "rendered")
    assert_response :success
    assert_select "#version_rendered_container h1", text: "Heading"

    get note_version_url(@note, @v1, view: "raw")
    assert_response :success
    assert_select "#version_raw_container pre", text: /Initial line/
  end

  test "should restore previous version and create a new version" do
    assert_difference("@note.versions.count", 1) do
      post restore_note_version_url(@note, @v1)
    end

    assert_redirected_to note_url(@note)
    @note.reload
    assert_equal 3, @note.current_version_number
    assert_equal "Architecture v1", @note.title
    assert_equal "# Heading\nInitial line", @note.body
  end

  test "background auto_save updates note without creating a version while explicit update creates a version" do
    assert_no_difference("@note.versions.count") do
      patch note_url(@note, format: :json), params: {
        auto_save: "1",
        note: { body: "Auto-saved body change" }
      }
    end
    assert_response :ok
    assert_equal "Auto-saved body change", @note.reload.body

    # Explicit save (auto_save: "0") commits the auto-saved draft as a new version
    assert_difference("@note.versions.count", 1) do
      patch note_url(@note, format: :json), params: {
        auto_save: "0",
        note: { body: "Auto-saved body change" }
      }
    end
    assert_response :ok
    assert_equal 3, @note.reload.current_version_number
  end
end
