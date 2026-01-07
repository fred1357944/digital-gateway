# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    # 載入首頁分類區塊資料
    @featured_products = Product.kept.published
                                .where("ai_metadata->>'ai_enhanced' = ?", "true")
                                .order(created_at: :desc)
                                .limit(4)

    @recent_products = Product.kept.published
                              .order(created_at: :desc)
                              .limit(4)

    @programming_courses = Product.kept.published
                                  .where("title ILIKE ? OR description ILIKE ?", "%程式%", "%程式%")
                                  .or(Product.kept.published.where("title ILIKE ? OR description ILIKE ?", "%Rails%", "%Rails%"))
                                  .or(Product.kept.published.where("title ILIKE ? OR description ILIKE ?", "%JavaScript%", "%JavaScript%"))
                                  .order(created_at: :desc)
                                  .limit(4)

    @beginner_courses = Product.kept.published
                               .where("ai_metadata->>'difficulty' = ?", "入門")
                               .order(created_at: :desc)
                               .limit(4)

    # 統計資料
    @stats = {
      products: Product.kept.published.count,
      sellers: SellerProfile.joins(:user).where(users: { discarded_at: nil }).count,
      ai_enhanced: Product.kept.published.where("ai_metadata->>'ai_enhanced' = ?", "true").count
    }
  end
end
