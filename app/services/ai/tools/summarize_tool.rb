# frozen_string_literal: true

module Ai
  module Tools
    # 摘要工具 - 生成內容摘要
    class SummarizeTool < BaseTool
      def execute(config)
        content = config[:content]
        log "生成摘要: #{content&.truncate(50)}"

        return { success: false, error: "無內容可摘要" } if content.blank?

        prompt = <<~PROMPT
          請用 2-3 句話摘要以下內容的重點：

          #{content.truncate(2000)}

          只回覆摘要，不要其他文字。
        PROMPT

        summary = client.analyze_content("", prompt: prompt)

        {
          success: true,
          summary: summary.strip,
          original_length: content.length,
          summary_length: summary.length
        }
      rescue StandardError => e
        { success: false, error: e.message }
      end
    end
  end
end
