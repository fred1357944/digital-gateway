# frozen_string_literal: true

# Demo products for Smart Commerce feature testing

puts "Creating demo data for Smart Commerce..."

# Create demo user
user = User.find_or_create_by!(email: "demo@example.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end
puts "User: #{user.email}"

# Create seller profile
seller = SellerProfile.find_or_create_by!(user: user) do |s|
  s.store_name = "智慧學院"
  s.description = "提供高品質數位課程"
  s.status = :verified
end
puts "Seller: #{seller.store_name}"

# Product data with varying characteristics
products_data = [
  {
    title: "Python 全端開發實戰",
    price: 1990,
    desc: "從零到一學會 Python 全端開發",
    scores: { price: 85, quality: 78, speed: 90, reputation: 82, relevance: 88 }
  },
  {
    title: "JavaScript 進階精通班",
    price: 2490,
    desc: "深入理解 JS 核心概念與設計模式",
    scores: { price: 65, quality: 95, speed: 85, reputation: 92, relevance: 90 }
  },
  {
    title: "Rails API 開發指南",
    price: 1590,
    desc: "建立高效能 RESTful API 服務",
    scores: { price: 88, quality: 82, speed: 78, reputation: 85, relevance: 75 }
  },
  {
    title: "React + TypeScript 實戰",
    price: 2990,
    desc: "企業級前端開發完整課程",
    scores: { price: 55, quality: 98, speed: 70, reputation: 95, relevance: 85 }
  },
  {
    title: "DevOps 入門到精通",
    price: 1290,
    desc: "CI/CD、Docker、Kubernetes 一次學會",
    scores: { price: 92, quality: 75, speed: 95, reputation: 78, relevance: 80 }
  },
  {
    title: "資料結構與演算法",
    price: 990,
    desc: "程式設計師必備的基礎知識",
    scores: { price: 98, quality: 88, speed: 85, reputation: 80, relevance: 70 }
  }
]

products_data.each do |data|
  product = Product.find_or_initialize_by(title: data[:title], seller_profile: seller)
  product.assign_attributes(
    description: data[:desc],
    price: data[:price],
    content_url: "https://example.com/courses/#{data[:title].parameterize}",
    status: :published
  )
  product.save!

  # Create or update score
  score = product.product_score || product.build_product_score
  score.update!(
    price_score: data[:scores][:price],
    quality_score: data[:scores][:quality],
    speed_score: data[:scores][:speed],
    reputation_score: data[:scores][:reputation],
    relevance_score: data[:scores][:relevance],
    calculated_at: Time.current
  )

  puts "  Created: #{product.title} (Price: #{data[:scores][:price]}, Quality: #{data[:scores][:quality]})"
end

puts "\nDemo data created!"
puts "Total published products: #{Product.published.count}"
puts "Products with scores: #{ProductScore.count}"
