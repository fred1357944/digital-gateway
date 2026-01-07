require "ostruct"

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Simple pagination helper (replacing Pagy for now)
  def paginate(collection, limit: 12)
    page = (params[:page] || 1).to_i
    offset = (page - 1) * limit
    total = collection.count
    pages = (total.to_f / limit).ceil
    pages = 1 if pages < 1

    pagy_info = OpenStruct.new(
      page: page,
      pages: pages,
      prev: page > 1 ? page - 1 : nil,
      next: page < pages ? page + 1 : nil,
      count: total
    )

    [pagy_info, collection.offset(offset).limit(limit)]
  end
end
