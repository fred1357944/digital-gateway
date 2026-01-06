require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'associations' do
    it { should belong_to(:seller_profile) }
    it { should have_many(:orders).dependent(:restrict_with_error) }
    it { should have_one(:mvt_report).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(200) }
    it { should validate_presence_of(:content_url) }
    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:price).is_greater_than(0) }
  end

  describe 'AASM state machine' do
    let(:product) { create(:product) }

    describe 'initial state' do
      it 'starts as draft' do
        expect(product).to be_draft
      end
    end

    describe '#submit_for_review' do
      it 'transitions from draft to pending_review' do
        expect { product.submit_for_review! }.to change(product, :status).from('draft').to('pending_review')
      end

      it 'cannot submit from published' do
        product.update!(status: :published)
        expect(product.may_submit_for_review?).to be false
      end
    end

    describe '#approve' do
      let(:product) { create(:product, :pending_review) }

      it 'transitions from pending_review to published' do
        expect { product.approve! }.to change(product, :status).from('pending_review').to('published')
      end
    end

    describe '#reject' do
      let(:product) { create(:product, :pending_review) }

      it 'transitions from pending_review to rejected' do
        expect { product.reject! }.to change(product, :status).from('pending_review').to('rejected')
      end
    end

    describe '#unpublish' do
      let(:product) { create(:product, :published) }

      it 'transitions from published to draft' do
        expect { product.unpublish! }.to change(product, :status).from('published').to('draft')
      end
    end
  end

  describe 'scopes' do
    let!(:published_product) { create(:product, :published) }
    let!(:draft_product) { create(:product) }
    let!(:discarded_product) { create(:product, :published, discarded_at: Time.current) }

    describe '.available' do
      it 'returns only published and kept products' do
        expect(Product.available).to include(published_product)
        expect(Product.available).not_to include(draft_product)
        expect(Product.available).not_to include(discarded_product)
      end
    end

    describe '.by_seller' do
      it 'returns products for a specific seller' do
        expect(Product.by_seller(published_product.seller_profile_id)).to include(published_product)
        expect(Product.by_seller(published_product.seller_profile_id)).not_to include(draft_product)
      end
    end
  end

  describe '#content_type' do
    let(:product) { build(:product) }

    it 'returns E-book for pdf' do
      product.content_url = 'https://example.com/book.pdf'
      expect(product.content_type).to eq('E-book')
    end

    it 'returns Video for mp4' do
      product.content_url = 'https://example.com/video.mp4'
      expect(product.content_type).to eq('Video')
    end

    it 'returns Audio for mp3' do
      product.content_url = 'https://example.com/audio.mp3'
      expect(product.content_type).to eq('Audio')
    end

    it 'returns Template for psd' do
      product.content_url = 'https://example.com/design.psd'
      expect(product.content_type).to eq('Template')
    end

    it 'returns Digital for unknown extension' do
      product.content_url = 'https://example.com/content'
      expect(product.content_type).to eq('Digital')
    end
  end

  describe '#mvt_viable?' do
    let(:product) { create(:product) }

    context 'without mvt_report' do
      it 'returns nil' do
        expect(product.mvt_viable?).to be_nil
      end
    end

    context 'with passing mvt_report' do
      before { create(:mvt_report, product: product) }

      it 'returns true' do
        expect(product.mvt_viable?).to be true
      end
    end
  end
end
