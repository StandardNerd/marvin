import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  static values = { open: { type: Boolean, default: false } }

  toggle() {
    this.openValue = !this.openValue
    this.contentTarget.style.display = this.openValue ? 'block' : 'none'
    if (this.hasIconTarget) {
      this.iconTarget.style.transform = this.openValue ? 'rotate(180deg)' : ''
    }
  }
}
