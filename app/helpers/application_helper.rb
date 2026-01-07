module ApplicationHelper

  # Colors for Pareto radar chart
  RADAR_COLORS = [
    "rgba(59, 130, 246, 1)",   # blue
    "rgba(239, 68, 68, 1)",    # red
    "rgba(34, 197, 94, 1)",    # green
    "rgba(168, 85, 247, 1)",   # purple
    "rgba(249, 115, 22, 1)",   # orange
    "rgba(236, 72, 153, 1)",   # pink
    "rgba(20, 184, 166, 1)",   # teal
    "rgba(245, 158, 11, 1)"    # amber
  ].freeze

  def radar_color(index, alpha = 1)
    base = RADAR_COLORS[index % RADAR_COLORS.length]
    base.sub(/1\)$/, "#{alpha})")
  end

  # Icons for Pareto categories
  def category_icon(category)
    icons = {
      price: "💰",
      quality: "⭐",
      speed: "🚀",
      reputation: "🏆",
      relevance: "🎯",
      balanced: "⚖️"
    }
    icons[category.to_sym] || "📊"
  end

  # Score badge with color based on value
  def score_badge(score)
    return content_tag(:span, "-", class: "text-neutral-400") unless score

    color_class = case score
                  when 80..100 then "bg-green-100 text-green-800"
                  when 60..79 then "bg-blue-100 text-blue-800"
                  when 40..59 then "bg-yellow-100 text-yellow-800"
                  else "bg-red-100 text-red-800"
                  end

    content_tag(:span, "#{score}分", class: "inline-flex px-2 py-1 text-xs font-medium rounded-full #{color_class}")
  end

  # Objective labels in Chinese
  def objective_label(objective)
    labels = {
      price: "價格",
      quality: "品質",
      speed: "速度",
      reputation: "信譽",
      relevance: "相關"
    }
    labels[objective.to_sym] || objective.to_s
  end

  # ESE state icons
  def state_icon(state)
    icons = {
      exploration: '<svg class="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>',
      exploitation: '<svg class="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>',
      convergence: '<svg class="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>',
      stagnation: '<svg class="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" /></svg>'
    }
    (icons[state.to_sym] || icons[:exploration]).html_safe
  end

  def pagy_tailwind_nav(pagy)
    return "" if pagy.pages < 2

    content_tag :nav, class: "flex items-center justify-center gap-2 mt-12" do
      html = []

      # Previous
      if pagy.prev
        html << link_to("← Prev", url_for(page: pagy.prev),
          class: "px-4 py-2 text-sm text-neutral-600 hover:text-neutral-900 transition-colors")
      end

      # Page info
      html << content_tag(:span,
        "Page #{pagy.page} of #{pagy.pages}",
        class: "text-sm text-neutral-400")

      # Next
      if pagy.next
        html << link_to("Next →", url_for(page: pagy.next),
          class: "px-4 py-2 text-sm text-neutral-600 hover:text-neutral-900 transition-colors")
      end

      safe_join(html)
    end
  end
end
