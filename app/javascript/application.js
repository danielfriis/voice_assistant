// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "channels"

document.addEventListener('DOMContentLoaded', () => {
  if (!document.cookie.split('; ').some(cookie => cookie.startsWith('timezone='))) {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    let cookieString = `timezone=${timezone};path=/;max-age=31536000;`;
    if (location.protocol === 'https:') {
      cookieString += 'Secure;';
    }
    // Try without SameSite first
    document.cookie = cookieString;
    // Log for debugging
    setTimeout(() => {
      if (document.cookie.includes('timezone=')) {
        console.log('Timezone cookie set successfully:', document.cookie);
      } else {
        console.warn('Failed to set timezone cookie. Current cookies:', document.cookie);
      }
    }, 100);
  }
});
