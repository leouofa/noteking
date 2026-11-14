require "application_system_test_case"

class NotesTest < ApplicationSystemTestCase
  setup do
    @note = Note.create!(title: "System Test Note", body: "# Hello World\n\nThis is a system test note.")
  end

  test "visiting the index and viewing note" do
    visit root_url
    assert_selector "h1", text: "Standalone Notes"
    assert_text "System Test Note"

    within "main" do
      click_on "System Test Note"
    end
    assert_selector "h1", text: "System Test Note"
    assert_text "Hello World"
  end

  test "creating a new note" do
    visit root_url
    within "main" do
      click_on "New Note"
    end

    fill_in "Note Title", with: "Created via System Test"
    fill_in "Markdown Content", with: "System test body content"
    click_on "Create Note"

    assert_text "Note created successfully."
    assert_text "Created via System Test"
  end

  test "clicking note card navigates to note details" do
    visit root_url
    find(".group.relative", text: "System Test Note").click
    assert_selector "h1", text: "System Test Note"
  end

  test "pinning and unpinning a note from card" do
    visit root_url
    assert_text "No pinned notes yet."

    within "main" do
      click_on "Pin"
    end

    assert_text "Pinned"
    within "aside" do
      assert_text "System Test Note"
    end

    within "main" do
      click_on "Pinned"
    end

    within "aside" do
      assert_text "No pinned notes yet."
    end
  end

  test "pin, copy, and toolbar buttons have pointer cursor" do
    visit root_url
    assert_equal "pointer", find("button", text: "Pin").native.css_value("cursor")
    assert_equal "pointer", find("button", text: "Copy").native.css_value("cursor")

    within "main" do
      click_on "System Test Note"
    end
    assert_selector "h1", text: "System Test Note"

    assert_equal "pointer", find("button", text: "Pin").native.css_value("cursor")
    assert_equal "pointer", find("button", text: "Copy Markdown").native.css_value("cursor")
    assert_equal "pointer", find("[data-markdown-editor-target='previewTab']").native.css_value("cursor")
    assert_equal "pointer", find("[data-markdown-editor-target='editTab']").native.css_value("cursor")
    assert_equal "pointer", find("[data-markdown-editor-target='splitTab']").native.css_value("cursor")
  end
end
