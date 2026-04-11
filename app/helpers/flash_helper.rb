module FlashHelper
  # Returns true if this flash type should auto-close after a timeout.
  # Errors stay open so the user can read and act on them.
  def auto_close_for(type)
    %w[notice success warning info].include?(type.to_s)
  end

  # Maps a flash key to the corresponding DaisyUI alert colour class.
  def alert_class(type)
    case type.to_s
    when "notice", "success" then "alert-success"
    when "alert",  "error"   then "alert-error"
    when "warning"           then "alert-warning"
    when "info"              then "alert-info"
    else                          "alert-info"
    end
  end

  # Returns an html_safe SVG string appropriate for the flash type.
  def icon_for(type)
    case type.to_s
    when "notice", "success"
      # Checkmark circle
      <<~SVG.html_safe
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 shrink-0 stroke-current" fill="none" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      SVG
    when "alert", "error"
      # X circle
      <<~SVG.html_safe
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 shrink-0 stroke-current" fill="none" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      SVG
    when "warning"
      # Warning triangle
      <<~SVG.html_safe
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 shrink-0 stroke-current" fill="none" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
        </svg>
      SVG
    else
      # Info circle (covers :info and any unknown keys)
      <<~SVG.html_safe
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 shrink-0 stroke-current" fill="none" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      SVG
    end
  end
end
