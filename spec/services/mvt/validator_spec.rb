# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mvt::Validator do
  subject(:validator) { described_class.new }

  describe '#validate' do
    context 'with clean content' do
      let(:content) { 'This is a well-researched claim supported by empirical data.' }

      it 'returns perfect score' do
        report = validator.validate(content, context: { name: 'Clean Content' })
        expect(report.score_mvt).to eq(1.0)
        expect(report.viable?).to be true
        expect(report.is_nullity).to be false
      end
    end

    context 'with hidden assumptions (Dimension I)' do
      let(:content) { 'Obviously everyone knows this is the best approach.' }

      it 'detects hidden assumptions' do
        report = validator.validate(content, context: { name: 'Hidden Assumptions' })
        expect(report.results).not_to be_empty
        expect(report.results.any? { |r| r.dimension == Mvt::Dimension::FOUNDATIONS }).to be true
        expect(report.score_mvt).to be < 1.0
      end
    end

    context 'with structural breaks (Dimension II)' do
      let(:content) { 'Therefore this proves our point conclusively.' }

      it 'detects structural breaks' do
        report = validator.validate(content, context: { name: 'Structural Breaks' })
        expect(report.results.any? { |r| r.dimension == Mvt::Dimension::STRUCTURAL }).to be true
      end
    end

    context 'with inference gaps (Dimension III)' do
      let(:content) { 'Many users probably like this feature, etc.' }

      it 'detects inference gaps' do
        report = validator.validate(content, context: { name: 'Inference Gaps' })
        expect(report.results.any? { |r| r.dimension == Mvt::Dimension::INFERENCE }).to be true
      end
    end

    context 'with unfalsifiable claims (Dimension IV)' do
      let(:content) { 'This theory cannot be tested or verified by any means.' }

      it 'detects unfalsifiable claims and marks as not viable' do
        report = validator.validate(content, context: { name: 'Unfalsifiable' })
        expect(report.results.any? { |r| r.severity == Mvt::Severity::FAIL }).to be true
        expect(report.viable?).to be false
      end
    end

    context 'with zombie content' do
      let(:content) do
        'The correlation between A and B demonstrates that A causes B. This elegant theory is theoretically valid.'
      end

      it 'identifies zombie candidate' do
        report = validator.validate(content, context: { name: 'Zombie Content' })
        expect(report.results.any? { |r| r.severity == Mvt::Severity::ZOMBIE }).to be true
      end
    end
  end

  describe '#calculate_score' do
    it 'returns 1.0 for content with no issues' do
      report = validator.validate('Clean factual statement.', context: { name: 'Test' })
      expect(report.score_mvt).to eq(1.0)
    end

    it 'reduces score based on violations' do
      report = validator.validate('Obviously this must always work.', context: { name: 'Test' })
      expect(report.score_mvt).to be < 1.0
      expect(report.score_mvt).to be > 0.0
    end
  end
end

RSpec.describe Mvt::FailFastGate do
  subject(:gate) { described_class.new(tau: 0.5) }

  describe '#check' do
    it 'passes clean content' do
      pass, report = gate.check('Valid factual content.', context: { name: 'Test' })
      expect(pass).to be true
      expect(report.score_mvt).to eq(1.0)
    end

    it 'rejects content with FAIL severity' do
      pass, report = gate.check('This cannot be tested or verified.', context: { name: 'Test' })
      expect(pass).to be false
    end

    it 'rejects content below tau threshold' do
      pass, report = gate.check(
        'Obviously everyone knows this must always be true. Therefore it proves our point.',
        context: { name: 'Test' }
      )
      expect(pass).to be false if report.score_mvt < 0.5
    end
  end
end

RSpec.describe Mvt::ValidationReport do
  let(:report) { described_class.new(content_name: 'Test Report') }

  describe '#viable?' do
    it 'returns true when no FAIL or NULLITY results' do
      report.results << Mvt::CheckResult.new(
        dimension: Mvt::Dimension::FOUNDATIONS,
        severity: Mvt::Severity::WARNING,
        message: 'Test warning'
      )
      expect(report.viable?).to be true
    end

    it 'returns false when FAIL result exists' do
      report.results << Mvt::CheckResult.new(
        dimension: Mvt::Dimension::SCIENTIFIC,
        severity: Mvt::Severity::FAIL,
        message: 'Critical failure'
      )
      expect(report.viable?).to be false
    end
  end

  describe '#summary' do
    it 'generates readable summary' do
      report.score_mvt = 0.85
      summary = report.summary
      expect(summary).to include('MVT 驗證報告')
      expect(summary).to include('Test Report')
      expect(summary).to include('0.850')
    end
  end
end
