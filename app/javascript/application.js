// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "channels"

document.addEventListener('DOMContentLoaded', () => {
  // Only set the timezone cookie if it doesn't already exist
  if (!document.cookie.split('; ').some(cookie => cookie.startsWith('timezone='))) {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    console.log(`Setting timezone: ${timezone}`)
    document.cookie = `timezone=${timezone};path=/;max-age=31536000;SameSite=Lax`;
  }
});
