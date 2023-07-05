# frozen_string_literal: true

require "rails_helper"

GRANTED_USERS = %i[service_portfolio_manager owner].freeze
USERS = (GRANTED_USERS + %i[stranger]).freeze

RSpec.describe Backoffice::OfferPolicy, backend: true do
  let(:service_portfolio_manager) { create(:user, roles: [:service_portfolio_manager]) }
  let(:owner) { create(:user) }
  let(:stranger) { create(:user) }
  let(:service) { create(:service, owners: [owner]) }

  subject { described_class }

  shared_examples "basic_test" do
    USERS.each do |user|
      granted = user.in? GRANTED_USERS
      it "#{granted ? "grants" : "denies"} access to #{user}" do
        expect(subject).to permit(send(user.to_s), offer) if granted
        expect(subject).to_not permit(send(user.to_s), offer) unless granted
      end
    end
  end

  shared_examples "deny_test" do
    USERS.each do |user|
      it "danies access to #{user}" do
        expect(subject).to_not permit(send(user.to_s), offer)
      end
    end
  end

  permissions :new? do
    let(:offer) { build(:offer, service: service) }
    it_behaves_like "basic_test"
  end

  permissions :destroy? do
    let(:offer) { create(:offer, service: service) }

    context "service is ordered using this offer" do
      before { create(:project_item, offer: offer) }
      it_behaves_like "deny_test"
    end
  end

  context "when offer is published" do
    let(:offer) { build(:offer, service: service, status: :published) }

    permissions :create?, :edit?, :update? do
      it_behaves_like "basic_test"
    end

    permissions :destroy? do
      USERS.each do |user|
        it "denies access to not persisted offer for #{user}" do
          expect(subject).to_not permit(send(user.to_s), build(:offer))
        end
      end

      before { offer.save }
      it_behaves_like "basic_test"
    end
  end

  context "when offer is a draft" do
    let(:offer) { build(:offer, service: service, status: :draft) }

    permissions :create?, :edit?, :update? do
      it_behaves_like "basic_test"
    end
  end

  context "When offer is published and service is deleted" do
    let(:service) { create(:service, owners: [owner], status: :deleted) }
    let(:offer) { build(:offer, service: service, status: :published) }

    permissions :create?, :edit?, :update?, :destroy? do
      it_behaves_like "deny_test"
    end
  end

  context "When offer is draft and service is deleted" do
    let(:service) { create(:service, owners: [owner], status: :deleted) }
    let(:offer) { build(:offer, service: service, status: :draft) }

    permissions :create?, :edit?, :update?, :destroy? do
      it_behaves_like "deny_test"
    end
  end
end
