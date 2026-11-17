# frozen_string_literal: true

require "test_helper"

class NoteVersionTest < ActiveSupport::TestCase
  test "creating a note automatically creates initial v1 version" do
    note = Note.create!(title: "Initial Title", body: "Initial body content")

    assert_equal 1, note.versions.count
    assert_equal 1, note.current_version_number

    v1 = note.latest_version
    assert_equal 1, v1.version_number
    assert_equal "Initial Title", v1.title
    assert_equal "Initial body content", v1.body
    assert_not note.unversioned_changes?
  end

  test "updating title or body creates sequential versions" do
    note = Note.create!(title: "v1 Title", body: "v1 body")

    note.update!(body: "v2 body")
    assert_equal 2, note.versions.count
    assert_equal 2, note.current_version_number
    assert_equal "v2 body", note.latest_version.body

    note.update!(title: "v3 Title")
    assert_equal 3, note.versions.count
    assert_equal 3, note.current_version_number
    assert_equal "v3 Title", note.latest_version.title

    assert_equal [ 3, 2, 1 ], note.versions.ordered.pluck(:version_number)
  end

  test "updating non-content attributes like pinned does not create a version" do
    note = Note.create!(title: "Pin Test", body: "Body content")
    assert_equal 1, note.versions.count

    note.toggle_pin!
    assert_equal 1, note.versions.count
  end

  test "skip_versioning prevents version creation on background auto-save until explicit snapshot" do
    note = Note.create!(title: "Draft Note", body: "Original text")
    assert_equal 1, note.versions.count

    note.skip_versioning = true
    note.update!(body: "Auto-saved draft 1")
    assert_equal 1, note.versions.count
    assert note.unversioned_changes?

    note.skip_versioning = true
    note.update!(body: "Auto-saved draft 2")
    assert_equal 1, note.versions.count

    # Explicit save (even with no new column change on this call) snapshots the accumulated draft
    note.skip_versioning = false
    note.record_version_snapshot!
    assert_equal 2, note.versions.count
    assert_equal "Auto-saved draft 2", note.latest_version.body
    assert_not note.unversioned_changes?
  end

  test "restore_version! non-destructively restores a previous version as a new version" do
    note = Note.create!(title: "Original Title", body: "Line 1")
    v1 = note.latest_version

    note.update!(title: "Modified Title", body: "Line 1\nLine 2")
    assert_equal 2, note.current_version_number

    note.restore_version!(v1)
    note.reload

    assert_equal 3, note.current_version_number
    assert_equal "Original Title", note.title
    assert_equal "Line 1", note.body
    assert_equal "Original Title", note.latest_version.title
    assert_equal "Line 1", note.latest_version.body
  end

  test "restore_version! preserves unversioned auto-saved changes before restoring" do
    note = Note.create!(title: "v1", body: "First")
    v1 = note.latest_version

    note.skip_versioning = true
    note.update!(body: "Unversioned auto-saved work")
    assert_equal 1, note.versions.count

    note.restore_version!(v1)
    note.reload

    # v2 snapshots the unversioned draft, v3 is the restored v1
    assert_equal 3, note.versions.count
    assert_equal "Unversioned auto-saved work", note.versions.find_by(version_number: 2).body
    assert_equal "First", note.versions.find_by(version_number: 3).body
  end
end
