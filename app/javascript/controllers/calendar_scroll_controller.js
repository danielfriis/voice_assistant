import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    this.scrollToCurrentTime()
  }

  scrollToCurrentTime() {
    // Each hour block is 7rem (2 * 3.5rem) tall
    const hourHeight = 7 * 16 // 7rem * 16px = 112px
    
    // Get current hour and subtract 1 to show the previous hour
    const currentHour = new Date().getHours()
    const scrollHour = Math.max(0, currentHour - 1)
    
    // Calculate scroll position (including the 1.75rem header offset)
    const scrollPosition = (scrollHour * hourHeight) + (1.75 * 16)
    
    // Smooth scroll to position
    this.containerTarget.scrollTo({
      top: scrollPosition,
      behavior: 'smooth'
    })
  }
}
