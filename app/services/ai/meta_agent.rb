# frozen_string_literal: true

module Ai
  # Meta-Agent - 彈性工具存取模式
  #
  # 參考圖中的 Meta-Agent Mode:
  # - search_tool: 搜尋可用工具
  # - create_tool: 動態創建工具
  # - ask_user: 與用戶確認
  # - create_agent_config: 生成配置
  #
  # 適用於：比較、規劃、複雜推理
  #
  class MetaAgent
    MAX_ITERATIONS = 5

    # 可用工具註冊表
    TOOL_REGISTRY = {
      search_products: {
        description: "搜尋商品資料庫",
        handler: ->(params, ctx) { Ai::Tools::SearchTool.new(client: ctx[:client], user: ctx[:user]).execute(params) }
      },
      compare_products: {
        description: "比較多個商品的優劣",
        handler: ->(params, ctx) { Ai::Tools::CompareTool.new(client: ctx[:client], user: ctx[:user]).execute(params) }
      },
      get_product_details: {
        description: "取得商品詳細資訊",
        handler: ->(params, ctx) { Product.find_by(id: params[:product_id])&.attributes }
      },
      calculate_score: {
        description: "計算商品評分",
        handler: ->(params, ctx) { Ai::Tools::ScoreTool.new.execute(params) }
      }
    }.freeze

    def initialize(query, user: nil)
      @query = query
      @user = user
      @api_key = user&.gemini_api_key
      @client = GeminiClient.new(api_key: @api_key)
      @context = { client: @client, user: @user }
      @execution_log = []
      @iteration = 0
    end

    def execute
      log_action("meta_agent_start", { query: @query })

      # 初始規劃
      plan = create_execution_plan

      return error_result(plan[:error]) unless plan[:success]

      # 迭代執行計畫
      result = execute_plan(plan[:steps])

      {
        success: true,
        mode: :meta_agent,
        plan: plan,
        result: result,
        execution_log: @execution_log,
        cost_estimate: estimate_cost
      }
    rescue StandardError => e
      error_result("Meta-Agent 執行錯誤: #{e.message}")
    end

    private

    # 創建執行計畫
    def create_execution_plan
      result = @client.analyze_content(@query, prompt: planning_prompt)
      json_str = result.text.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
      data = JSON.parse(json_str, symbolize_names: true)

      {
        success: true,
        intent: data[:intent],
        steps: data[:steps] || [],
        expected_output: data[:expected_output]
      }
    rescue JSON::ParserError => e
      { success: false, error: "無法解析執行計畫: #{e.message}" }
    end

    def planning_prompt
      tool_descriptions = TOOL_REGISTRY.map { |name, info| "- #{name}: #{info[:description]}" }.join("\n")

      <<~PROMPT
        你是 Meta-Agent 規劃器。分析用戶需求，創建執行計畫。

        ## 可用工具
        #{tool_descriptions}

        ## 輸出格式
        ```json
        {
          "intent": "用戶意圖描述",
          "steps": [
            {
              "tool": "工具名稱",
              "params": { "參數": "值" },
              "purpose": "這步驟的目的"
            }
          ],
          "expected_output": "預期輸出描述"
        }
        ```

        注意：
        1. 步驟數量控制在 1-5 步
        2. 每步使用一個工具
        3. 後續步驟可引用前步結果

        只回覆 JSON。
      PROMPT
    end

    # 執行計畫
    def execute_plan(steps)
      results = []
      step_results = {}

      steps.each_with_index do |step, index|
        @iteration += 1
        break if @iteration > MAX_ITERATIONS

        log_action("execute_step", {
          step: index + 1,
          tool: step[:tool],
          purpose: step[:purpose]
        })

        # 解析參數（支援引用前步結果）
        params = resolve_params(step[:params], step_results)

        # 執行工具
        result = execute_tool(step[:tool].to_sym, params)

        step_results["step_#{index + 1}"] = result
        results << {
          step: index + 1,
          tool: step[:tool],
          result: result
        }
      end

      # 整合結果
      synthesize_results(results)
    end

    def execute_tool(tool_name, params)
      tool = TOOL_REGISTRY[tool_name]

      if tool
        log_action("tool_execute", { tool: tool_name, params: params })
        tool[:handler].call(params, @context)
      else
        log_action("tool_not_found", { tool: tool_name })
        { error: "工具不存在: #{tool_name}" }
      end
    end

    # 解析參數，支援 $step_1.field 引用
    def resolve_params(params, step_results)
      return {} unless params.is_a?(Hash)

      params.transform_values do |value|
        if value.is_a?(String) && value.start_with?("$")
          # 引用前步結果，如 $step_1.products
          parts = value[1..].split(".")
          step_key = parts[0]
          field = parts[1]

          step_result = step_results[step_key]
          field ? step_result&.dig(field.to_sym) : step_result
        else
          value
        end
      end
    end

    # 整合所有步驟結果
    def synthesize_results(results)
      # 取最後一步的結果作為主要輸出
      last_result = results.last&.dig(:result)

      {
        steps_completed: results.size,
        final_result: last_result,
        all_results: results
      }
    end

    def log_action(action, details = {})
      @execution_log << {
        action: action,
        details: details,
        timestamp: Time.current
      }
    end

    def estimate_cost
      # Meta-Agent 通常需要更多 tokens
      {
        model: "gemini-2.0-flash",
        estimated_tokens: 1500,
        estimated_cost_usd: 0.0015
      }
    end

    def error_result(message)
      {
        success: false,
        mode: :meta_agent,
        error: message,
        execution_log: @execution_log
      }
    end
  end
end
