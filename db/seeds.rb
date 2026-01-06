# frozen_string_literal: true

# Digital Gateway - Seed Data
# Run with: rails db:seed
#
# Creates demo users, sellers, products for testing and demonstration.
# Idempotent - safe to run multiple times.

puts "Seeding Digital Gateway..."

# ============================================
# 1. Demo Users
# ============================================

puts "Creating users..."

# Admin user
admin = User.find_or_create_by!(email: "admin@digitalgateway.com") do |u|
  u.password = "password123"
  u.role = :admin
end
puts "  Admin: #{admin.email}"

# Seller user (your test account)
seller_user = User.find_or_create_by!(email: "fred1357944@gmail.com") do |u|
  u.password = "24682468"
  u.role = :seller
end
puts "  Seller: #{seller_user.email}"

# Demo seller
demo_seller = User.find_or_create_by!(email: "seller@demo.com") do |u|
  u.password = "password123"
  u.role = :seller
end
puts "  Demo Seller: #{demo_seller.email}"

# Demo buyer
buyer = User.find_or_create_by!(email: "buyer@demo.com") do |u|
  u.password = "password123"
  u.role = :buyer
end
puts "  Buyer: #{buyer.email}"

# ============================================
# 2. Seller Profiles
# ============================================

puts "Creating seller profiles..."

# Your seller profile
fred_profile = SellerProfile.find_or_create_by!(user: seller_user) do |sp|
  sp.store_name = "Fred's Digital Shop"
  sp.status = :verified
end
puts "  Profile: #{fred_profile.store_name}"

# Demo seller profile
demo_profile = SellerProfile.find_or_create_by!(user: demo_seller) do |sp|
  sp.store_name = "Demo Creator Studio"
  sp.status = :verified
end
puts "  Profile: #{demo_profile.store_name}"

# ============================================
# 3. Demo Products
# ============================================

puts "Creating products..."

products_data = [
  {
    seller_profile: fred_profile,
    title: "Rails 8 Complete Guide",
    description: "A comprehensive guide to building modern web applications with Ruby on Rails 8. Covers everything from setup to deployment, including Hotwire, Turbo, and Stimulus.",
    price: 990,
    content_url: "https://example.com/rails8-guide",
    status: :published
  },
  {
    seller_profile: fred_profile,
    title: "Tailwind CSS Masterclass",
    description: "Learn to build beautiful, responsive UIs with Tailwind CSS v4. Includes real-world projects and best practices.",
    price: 790,
    content_url: "https://example.com/tailwind-course",
    status: :published
  },
  {
    seller_profile: demo_profile,
    title: "Notion Template Pack",
    description: "50+ premium Notion templates for productivity, project management, and personal knowledge management.",
    price: 490,
    content_url: "https://example.com/notion-templates",
    status: :published
  },
  {
    seller_profile: demo_profile,
    title: "Startup Pitch Deck Template",
    description: "Professional pitch deck template used by YC-backed startups. Includes 20 slides with examples and guidance.",
    price: 590,
    content_url: "https://example.com/pitch-deck",
    status: :published
  },
  {
    seller_profile: fred_profile,
    title: "AI Prompt Engineering Guide",
    description: "Master the art of prompt engineering for ChatGPT, Claude, and other LLMs. Includes 100+ proven prompts.",
    price: 690,
    content_url: "https://example.com/prompt-guide",
    status: :published
  },
  {
    seller_profile: demo_profile,
    title: "Digital Product Launch Playbook",
    description: "Step-by-step guide to launching your first digital product. From idea validation to marketing strategies.",
    price: 890,
    content_url: "https://example.com/launch-playbook",
    status: :published
  }
]

products_data.each do |data|
  product = Product.find_or_create_by!(
    seller_profile: data[:seller_profile],
    title: data[:title]
  ) do |p|
    p.description = data[:description]
    p.price = data[:price]
    p.content_url = data[:content_url]
    p.status = data[:status]
  end

  # Create MVT report for published products
  if product.published? && product.mvt_report.blank?
    product.create_mvt_report!(
      score: rand(0.75..0.95).round(2),
      status: :pass,
      details: {
        results: [
          { dimension: "foundations", score: rand(0.7..1.0).round(2), pass: true },
          { dimension: "structure", score: rand(0.7..1.0).round(2), pass: true },
          { dimension: "logic", score: rand(0.7..1.0).round(2), pass: true },
          { dimension: "expression", score: rand(0.7..1.0).round(2), pass: true }
        ],
        validated_at: Time.current.iso8601
      }
    )
  end

  puts "  Product: #{product.title} (#{product.status})"
end

# ============================================
# 4. Demo Order (optional)
# ============================================

puts "Creating demo order..."

demo_order = Order.find_or_create_by!(
  user: buyer,
  product: Product.published.first
) do |o|
  o.amount = Product.published.first.price
  o.status = :paid
end

# Create access token for demo order
if demo_order.paid? && demo_order.access_token.blank?
  demo_order.create_access_token!(
    token: SecureRandom.urlsafe_base64(32),
    expires_at: 7.days.from_now,
    max_uses: 10
  )
end

puts "  Order: ##{demo_order.id} for #{demo_order.product.title}"

# ============================================
# Summary
# ============================================

puts "\n" + "=" * 50
puts "Seed completed!"
puts "=" * 50
puts "\nDemo Accounts:"
puts "  Admin:  admin@digitalgateway.com / password123"
puts "  Seller: fred1357944@gmail.com / 24682468"
puts "  Seller: seller@demo.com / password123"
puts "  Buyer:  buyer@demo.com / password123"
puts "\nProducts: #{Product.count}"
puts "Published: #{Product.published.count}"
puts "Orders: #{Order.count}"
puts "=" * 50
