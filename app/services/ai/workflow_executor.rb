# frozen_string_literal: true

module Ai
  # Workflow Executor - 確定性 4 階段管線
  #
  # 參考圖中的 Workflow Mode:
  # Stage 1: Intent Decomposition
  # Stage 2: Tool Retrieval & Ad-hoc Tool Synthesis
  # Stage 3: Prompt Generation
  # Stage 4: Config Assembly & Execute
  #
  # 優點：成本低、可預測、適合簡單任務
  #
  class WorkflowExecutor
    AVAILABLE_TOOLS = {
      search: Ai::Tools::SearchTool,
      filter: Ai::Tools::FilterTool,
      preview: Ai::Tools::PreviewTool,
      summarize: Ai::Tools::SummarizeTool
    }.freeze

    def initialize(query, user: nil)
      @query = query
      @user = user
      @api_key = user&.gemini_api_key
      @client = GeminiClient.new(api_key: @api_key)
      @execution_log = []
    end

    def execute
      # Stage 1: Intent Decomposition
      log_stage(1, "Intent Decomposition")
      intent = decompose_intent

      return error_result(intent[:error]) unless intent[:success]

      # Stage 2: Tool Retrieval
      log_stage(2, "Tool Retrieval")
      tool = retrieve_tool(intent[:tool_type])

      # Stage 3: Prompt Generation (模板化，零成本)
      log_stage(3, "Prompt Generation")
      config = generate_config(intent, tool)

      # Stage 4: Execute
      log_stage(4, "Execute")
      result = tool.execute(config)

      {
        success: true,
        mode: :workflow,
        intent: intent,
        result: result,
        execution_log: @execution_log,
        cost_estimate: estimate_cost
      }
    rescue StandardError => e
      error_result("Workflow 執行錯誤: #{e.message}")
    end

    private

    # Stage 1: 意圖分解（用 Gemini Flash，便宜）
    def decompose_intent
      response = @client.analyze_content(@query, prompt: intent_decomposition_prompt)
      json_str = response.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
      data = JSON.parse(json_str, symbolize_names: true)

      {
        success: true,
        keywords: data[:keywords] || [],
        tool_type: (data[:tool_type] || "search").to_sym,
        filters: data[:filters] || {},
        user_need: data[:user_need] || @query
      }
    rescue JSON::ParserError
      # Fallback: 規則分解
      {
        success: true,
        keywords: @query.split(/\s+/),
        tool_type: :search,
        filters: {},
        user_need: @query
      }
    end

    def intent_decomposition_prompt
      <<~PROMPT
        你是意圖分解器。解析用戶查詢，輸出 JSON：

        可用工具：search（搜尋）、filter（篩選）、preview（預覽）、summarize（摘要）

        ```json
        {
          "keywords": ["關鍵字1", "關鍵字2"],
          "tool_type": "search|filter|preview|summarize",
          "filters": {
            "category": "分類（可選）",
            "price_max": 數字（可選）,
            "difficulty": "入門|進階|專家（可選）"
          },
          "user_need": "用戶需求一句話描述"
        }
        ```

        只回覆 JSON。
      PROMPT
    end

    # Stage 2: 工具檢索
    def retrieve_tool(tool_type)
      tool_class = AVAILABLE_TOOLS[tool_type] || AVAILABLE_TOOLS[:search]
      tool_class.new(client: @client, user: @user)
    end

    # Stage 3: 配置生成
    def generate_config(intent, _tool)
      {
        keywords: intent[:keywords],
        filters: intent[:filters],
        user_need: intent[:user_need],
        limit: 20
      }
    end

    def log_stage(number, name)
      @execution_log << {
        stage: number,
        name: name,
        timestamp: Time.current
      }
    end

    def estimate_cost
      # Gemini Flash: ~$0.001 per 1K tokens
      # 假設平均 500 tokens per call
      {
        model: "gemini-2.0-flash",
        estimated_tokens: 500,
        estimated_cost_usd: 0.0005
      }
    end

    def error_result(message)
      {
        success: false,
        mode: :workflow,
        error: message,
        execution_log: @execution_log
      }
    end
  end
end
