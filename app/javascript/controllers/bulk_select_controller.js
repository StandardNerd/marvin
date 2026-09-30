import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "checkbox", "actions"]

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(cb => cb.checked = checked)
    this.updateActions()
  }

  toggleOne() {
    this.updateActions()
  }

  updateActions() {
    const anyChecked = this.checkboxTargets.some(cb => cb.checked)
    this.actionsTarget.style.display = anyChecked ? 'flex' : 'none'
  }
}
