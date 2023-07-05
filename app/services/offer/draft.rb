# frozen_string_literal: true

class Offer::Draft < ApplicationService
  def initialize(offer)
    super()
    @offer = offer
  end

  def call
    result = @offer.update(status: :draft)
    unbundle!
    result
  end

  private

  def unbundle!
    @offer.bundles.each do |bundle|
      Bundle::Update.call(bundle, { offers: bundle.offers.to_a.reject { |o| o == @offer } }, external_update: true)
    end
  end
end
