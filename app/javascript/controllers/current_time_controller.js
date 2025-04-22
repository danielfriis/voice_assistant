import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator"]

  connect() {
    this.updatePosition()
    this.interval = setInterval(() => this.updatePosition(), 60000) // Update every minute
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  updatePosition() {
    const now = new Date()
    const minutes = now.getHours() * 60 + now.getMinutes()
    
    // Convert minutes to grid row position
    // Each hour takes up 12 rows (5-minute intervals)
    // Add 2 for the header row (1.75rem)
    const rowPosition = Math.round(2 + (minutes / 5))
    this.indicatorTarget.style.display = "block"
    this.indicatorTarget.style.gridRow = `${rowPosition}`
  }
} 