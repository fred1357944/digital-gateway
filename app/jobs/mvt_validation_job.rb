# frozen_string_literal: true

class MvtValidationJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    product = Product.find(product_id)
    return unless product.pending_review?

    # Fetch content from external URL for validation
    content = fetch_content(product.content_url)

    if content.blank?
      create_failed_report(product, "無法取得內容")
      product.reject!
      return
    end

    # Run MVT validation (使用 AI 驗證器，自動降級到規則驗證器)
    # 優先使用賣家自己的 Gemini API Key，否則用系統的
    seller_api_key = product.seller_profile&.user&.gemini_api_key
    validator = Mvt::AiValidator.new(api_key: seller_api_key)
    report = validator.validate(content, context: { name: product.title })

    # Save report
    mvt_report = product.build_mvt_report(
      score: report.score_mvt,
      status: determine_status(report),
      details: report.to_h
    )
    mvt_report.save!

    # Approve or reject based on MVT result
    if report.viable?
      product.approve!
    else
      product.reject!
    end
  rescue StandardError => e
    Rails.logger.error("MVT Validation failed for product #{product_id}: #{e.message}")
    create_failed_report(product, e.message)
    product.reject! if product.may_reject?
  end

  private

  def fetch_content(url)
    # For now, just return the URL as placeholder
    # In production, this would fetch and parse the actual content
    # from Notion, Heptabase, etc.
    "Content from: #{url}"
  rescue StandardError => e
    Rails.logger.error("Failed to fetch content from #{url}: #{e.message}")
    nil
  end

  def determine_status(report)
    if report.is_nullity
      :nullity
    elsif report.is_zombie
      :zombie
    elsif !report.viable?
      :fail
    elsif report.has_warnings?
      :warning
    else
      :pass
    end
  end

  def create_failed_report(product, message)
    product.create_mvt_report!(
      score: 0.0,
      status: :fail,
      details: { error: message, results: [] }
    )
  end
end
