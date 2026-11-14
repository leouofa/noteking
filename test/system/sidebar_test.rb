require "application_system_test_case"

class SidebarTest < ApplicationSystemTestCase
  test "No Auth badge is removed from sidebar header" do
    visit root_url
    assert_no_text "No Auth"
    assert_no_text "NO AUTH"
  end

  test "toggling sidebar with collapse and expand buttons on desktop" do
    visit root_url

    # Sidebar is visible initially
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible
    assert_no_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible

    # Click collapse button
    find("button[aria-label='Collapse sidebar']").click

    # Sidebar is now collapsed
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :hidden
    assert_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible

    # Click expand button
    find("button[aria-label='Expand sidebar']").click

    # Sidebar is restored
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible
    assert_no_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible
  end

  test "toggling sidebar with Cmd+\\ / Ctrl+\\ keyboard shortcut" do
    visit root_url

    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible

    # Trigger Cmd+\
    page.execute_script("window.dispatchEvent(new KeyboardEvent('keydown', { key: '\\\\', metaKey: true, bubbles: true }))")

    # Should collapse
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :hidden
    assert_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible

    # Trigger Ctrl+\
    page.execute_script("window.dispatchEvent(new KeyboardEvent('keydown', { key: '\\\\', ctrlKey: true, bubbles: true }))")

    # Should expand again
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible
    assert_no_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible
  end

  test "persisting collapsed state across page reload via localStorage" do
    visit root_url

    find("button[aria-label='Collapse sidebar']").click
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :hidden

    # Reload the page
    visit root_url

    # State persists as collapsed
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :hidden
    assert_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible

    # Expand again
    find("button[aria-label='Expand sidebar']").click
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible

    # Reload again
    visit root_url
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible
  end

  test "mobile view: sidebar takes full screen and notes are invisible until toggled away" do
    note = Note.create!(title: "Mobile Test Note", body: "Content for mobile test", pinned: true)

    page.driver.browser.manage.window.resize_to(375, 667)
    visit root_url

    # On mobile initial load, sidebar is full screen and main notes are invisible
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible
    assert_selector "main[data-sidebar-target='main']", visible: :hidden
    assert_no_text "Standalone Notes"

    # Click collapse button to toggle sidebar out of the way
    find("button[aria-label='Collapse sidebar']").click

    # Notes are now visible and sidebar is invisible
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :hidden
    assert_selector "main[data-sidebar-target='main']", visible: :visible
    assert_text "Standalone Notes"
    assert_selector "div[data-sidebar-target='expandTrigger'] button", visible: :visible

    # Re-open sidebar using expand button
    find("button[aria-label='Expand sidebar']").click

    # Sidebar is full screen again and notes are invisible
    assert_selector "aside[data-sidebar-target='sidebar']", visible: :visible
    assert_selector "main[data-sidebar-target='main']", visible: :hidden

    # Tapping a note in sidebar auto-closes sidebar to reveal the note
    click_on "Mobile Test Note"
    assert_selector "main[data-sidebar-target='main']", visible: :visible
    assert_text "Mobile Test Note"
    assert_text "Content for mobile test"

    # Reset screen size for subsequent tests
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
