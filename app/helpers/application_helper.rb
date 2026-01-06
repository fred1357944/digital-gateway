module ApplicationHelper
  include Pagy::Frontend

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
