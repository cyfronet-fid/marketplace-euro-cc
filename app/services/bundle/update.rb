# frozen_string_literal: true

class Bundle::Update < ApplicationService
  def initialize(bundle, params)
    super()
    @bundle = bundle
    @params = params
  end

  def call
    @bundle.main_offer.reset_added_bundled_offers! if @bundle.main_offer_id != @params["main_offer_id"]
    notify_added_bundled_offers! if @bundle.update(@params)
    @bundle.service.reindex
    @bundle.offers.reindex
    @bundle.valid?
  end

  private

  def notify_added_bundled_offers!
    @bundle.main_offer.added_bundled_offers&.each do |added_bundled_offer|
      Offer::Mailer::Bundled.call(added_bundled_offer, @offer)
    end
  end
end
