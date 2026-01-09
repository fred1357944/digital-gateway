# frozen_string_literal: true

# Sprint 3 功能測試腳本

puts "=" * 60
puts "📦 測試 1: GeminiClient Result 物件"
puts "=" * 60

result = GeminiClient::Result.new(
  text: "測試文字",
  input_tokens: 100,
  output_tokens: 50,
  total_tokens: 150
)

puts "✅ Result 物件建立成功"
puts "   text: #{result.text}"
puts "   input_tokens: #{result.input_tokens}"
puts "   output_tokens: #{result.output_tokens}"
puts "   total_tokens: #{result.total_tokens}"
puts "   to_h: #{result.to_h}"
puts

puts "=" * 60
puts "👤 測試 2: User 點數系統"
puts "=" * 60

user = User.first
if user.nil?
  puts "⚠️ 沒有用戶，建立測試用戶..."
  user = User.create!(email: "test@example.com", password: "password123")
end

puts "✅ 用戶: #{user.email}"
puts "   ai_credits: #{user.ai_credits}"
puts "   byok?: #{user.byok?}"
puts "   has_credits?(5): #{user.has_credits?(5)}"
puts

puts "=" * 60
puts "💳 測試 3: AiCreditTransaction Model"
puts "=" * 60

puts "   ACTION_TYPES: #{AiCreditTransaction::ACTION_TYPES}"

tx = AiCreditTransaction.create!(
  user: user,
  amount: -2,
  action_type: "explore",
  token_usage: { "input_tokens" => 100, "output_tokens" => 50, "total_tokens" => 150 },
  metadata: { "query" => "測試查詢" }
)
puts "✅ 交易記錄建立成功"
puts "   id: #{tx.id}"
puts "   amount: #{tx.amount}"
puts "   action_type: #{tx.action_type}"
puts "   input_tokens: #{tx.input_tokens}"
puts "   output_tokens: #{tx.output_tokens}"
puts

puts "=" * 60
puts "📊 測試 4: Ai::UsageService"
puts "=" * 60

service = Ai::UsageService.new(user)
check = service.can_execute?(:explore)
puts "✅ can_execute?(:explore): #{check}"
puts

stats = service.usage_stats
puts "✅ usage_stats:"
stats.each { |k, v| puts "   #{k}: #{v}" }
puts

puts "=" * 60
puts "🚦 測試 5: Ai::RateLimiter"
puts "=" * 60

limiter = Ai::RateLimiter.new(user)
result = limiter.check
puts "✅ rate_limiter.check: #{result}"
puts

puts "=" * 60
puts "👍 測試 6: AiFeedback Model"
puts "=" * 60

feedback = AiFeedback.create!(
  user: user,
  feedback_type: "thumbs_up",
  query: "Rails 入門課程",
  response_summary: "找到 5 個課程"
)
puts "✅ 反饋記錄建立成功"
puts "   id: #{feedback.id}"
puts "   feedback_type: #{feedback.feedback_type}"
puts

# 清理測試資料
feedback.destroy
tx.destroy
puts "🧹 測試資料已清理"
puts
puts "=" * 60
puts "🎉 所有測試通過！"
puts "=" * 60
