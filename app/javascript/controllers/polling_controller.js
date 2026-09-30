import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 5000 },
    url: String
  }

  connect() {
    if (this.urlValue) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.timer = setInterval(() => {
      this.poll()
    }, this.intervalValue)
  }

  stopPolling() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }

  async poll() {
    try {
      const response = await fetch(this.urlValue, {
        headers: { 'Accept': 'application/json' }
      })
      const data = await response.json()

      // If training is no longer active, reload the page to show final state
      if (['completed', 'failed', 'cancelled'].includes(data.status)) {
        this.stopPolling()
        window.location.reload()
      }
    } catch (e) {
      console.error('Polling error:', e)
    }
  }
}
