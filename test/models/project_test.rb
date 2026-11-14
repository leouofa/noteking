require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "validates presence of name" do
    project = Project.new(name: "")
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"

    project.name = "My Project"
    assert project.valid?
  end

  test "has_many notes with dependent nullify" do
    project = Project.create!(name: "Project A")
    note = Note.create!(project: project, title: "Note AA", body: "Test body")

    assert_equal 1, project.notes.count
    project.destroy
    assert_nil note.reload.project_id
  end
end
