require 'rails_helper'

RSpec.describe "Products", type: :request do
  describe "GET /products" do
    it "returns http success" do
      get products_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /products/:id" do
    let!(:user) { User.create!(email: "seller@test.com", password: "password123", role: :seller) }
    let!(:seller_profile) { SellerProfile.create!(user: user, store_name: "Test Store", status: :verified) }
    let!(:product) do
      Product.create!(
        seller_profile: seller_profile,
        title: "Test Product",
        description: "A test product",
        price: 100,
        content_url: "https://example.com/content",
        status: :published
      )
    end

    it "returns http success" do
      get product_path(product)
      expect(response).to have_http_status(:success)
    end
  end
end
