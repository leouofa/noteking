require "test_helper"

class NoteTest < ActiveSupport::TestCase
  test "validates presence of title" do
    note = Note.new(title: "")
    assert_not note.valid?
    assert_includes note.errors[:title], "can't be blank"

    note.title = "Valid Title"
    assert note.valid?
  end

  test "can be standalone without a project" do
    note = Note.create!(title: "Standalone Note", body: "# Standalone")
    assert_nil note.project
    assert_includes Note.standalone, note
  end

  test "search scope filters by title and body" do
    n1 = Note.create!(title: "Rails Optimization", body: "Use bullet for N+1 queries")
    n2 = Note.create!(title: "Python Tips", body: "List comprehensions are fast")

    assert_includes Note.search("Optimization"), n1
    assert_not_includes Note.search("Optimization"), n2

    assert_includes Note.search("bullet"), n1
    assert_not_includes Note.search("bullet"), n2
  end

  test "toggle_pin! toggles pinned state and manages pinned_position" do
    n1 = Note.create!(title: "Note 1")
    n2 = Note.create!(title: "Note 2")

    assert_not n1.pinned?
    n1.toggle_pin!
    assert n1.pinned?
    assert_equal 1, n1.pinned_position

    n2.toggle_pin!
    assert n2.pinned?
    assert_equal 2, n2.pinned_position

    assert_equal [ n1, n2 ], Note.pinned.to_a

    n1.toggle_pin!
    assert_not n1.pinned?
    assert_nil n1.pinned_position
    assert_equal [ n2 ], Note.pinned.to_a
  end
end
