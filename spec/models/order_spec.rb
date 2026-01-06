require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:product) }
    it { should have_one(:access_token).dependent(:destroy) }
  end

  describe 'validations' do
    subject { create(:order) }
    it { should validate_uniqueness_of(:merchant_trade_no).allow_nil }
  end

  describe 'callbacks' do
    describe 'before_create' do
      let(:order) { build(:order) }

      it 'generates merchant_trade_no' do
        expect(order.merchant_trade_no).to be_nil
        order.save!
        expect(order.merchant_trade_no).to match(/^DG\d{14}[A-F0-9]{8}$/)
      end

      it 'sets total_amount from product price' do
        order.save!
        expect(order.total_amount).to eq(order.product.price)
      end
    end
  end

  describe 'AASM state machine' do
    let(:order) { create(:order) }

    describe 'initial state' do
      it 'starts as pending' do
        expect(order).to be_pending
      end
    end

    describe '#pay' do
      it 'transitions from pending to paid' do
        # Stub mailer to avoid errors
        allow(OrderMailer).to receive_message_chain(:confirmation, :deliver_later)

        expect { order.pay! }.to change(order, :status).from('pending').to('paid')
      end

      it 'creates access token after payment' do
        allow(OrderMailer).to receive_message_chain(:confirmation, :deliver_later)

        expect { order.pay! }.to change { order.access_token.present? }.from(false).to(true)
      end

      it 'cannot pay from expired' do
        order.update!(status: :expired)
        expect(order.may_pay?).to be false
      end
    end

    describe '#expire' do
      it 'transitions from pending to expired' do
        expect { order.expire! }.to change(order, :status).from('pending').to('expired')
      end
    end

    describe '#refund' do
      let(:order) { create(:order, :paid) }

      before do
        # Create access token for paid order
        order.create_access_token!
      end

      it 'transitions from paid to refunded' do
        expect { order.refund! }.to change(order, :status).from('paid').to('refunded')
      end

      it 'revokes access token after refund' do
        order.refund!
        expect(order.access_token.reload).to be_revoked
      end
    end
  end

  describe 'scopes' do
    let!(:recent_order) { create(:order, created_at: 1.day.ago) }
    let!(:old_order) { create(:order, created_at: 1.week.ago) }

    describe '.recent' do
      it 'orders by created_at desc' do
        expect(Order.recent.first).to eq(recent_order)
      end
    end

    describe '.for_user' do
      let(:user) { create(:user) }
      let!(:user_order) { create(:order, user: user) }

      it 'returns orders for specific user' do
        expect(Order.for_user(user.id)).to include(user_order)
        expect(Order.for_user(user.id)).not_to include(recent_order)
      end
    end
  end

  describe '#create_access_token!' do
    let(:order) { create(:order) }

    it 'creates an access token with correct attributes' do
      token = order.create_access_token!

      expect(token).to be_persisted
      expect(token.order).to eq(order)
      expect(token.user).to eq(order.user)
      expect(token.expires_at).to be > 29.days.from_now
      expect(token.max_uses).to eq(10)
    end
  end

  describe 'delegations' do
    let(:order) { create(:order) }

    it 'delegates product_title to product' do
      expect(order.product_title).to eq(order.product.title)
    end

    it 'delegates product_content_url to product' do
      expect(order.product_content_url).to eq(order.product.content_url)
    end
  end
end
