import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    this.draggedItem = null
  }

  dragStart(event) {
    this.draggedItem = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", event.currentTarget.dataset.noteId)
    event.currentTarget.classList.add("opacity-40")
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const targetItem = event.currentTarget.closest("[data-note-id]")
    if (!targetItem || targetItem === this.draggedItem) return

    const bounding = targetItem.getBoundingClientRect()
    const offset = event.clientY - bounding.top
    if (offset > bounding.height / 2) {
      targetItem.after(this.draggedItem)
    } else {
      targetItem.before(this.draggedItem)
    }
  }

  dragEnd(event) {
    if (this.draggedItem) {
      this.draggedItem.classList.remove("opacity-40")
      this.draggedItem = null
    }
    this.saveOrder()
  }

  saveOrder() {
    const items = Array.from(this.element.querySelectorAll("[data-note-id]"))
    const noteIds = items.map(el => el.dataset.noteId)

    if (!this.hasUrlValue || noteIds.length === 0) return

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken || "",
        "Accept": "application/json"
      },
      body: JSON.stringify({ note_ids: noteIds })
    }).catch(error => {
      console.error("Failed to persist pinned note order:", error)
    })
  }
}
