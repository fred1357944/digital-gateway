# frozen_string_literal: true

module Ai
  module Tools
    # 工具基底類別
    class BaseTool
      attr_reader :client, :user

      def initialize(client: nil, user: nil)
        @client = client
        @user = user
      end

      def execute(_config)
        raise NotImplementedError, "子類別必須實作 execute 方法"
      end

      protected

      def log(message)
        Rails.logger.info "[AI::Tool::#{self.class.name.demodulize}] #{message}"
      end
    end
  end
end
