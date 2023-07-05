# frozen_string_literal: true

class Bundle::Update < ApplicationService
  def initialize(bundle, params, external_update: false)
    super()
    @bundle = bundle
    @params = params
    @external_update = external_update
    @current_offer_ids = @params[:offer_ids] || @params[:offers]&.map(&:id) || []
    @added_bundled_offer_ids = @current_offer_ids - @bundle.offers.map(&:id)
    @removed_bundled_offer_ids = @bundle.offers.map(&:id) - @current_offer_ids
  end

  def call
    public_before = @bundle.published?
    current_main_offer = Offer&.find_by(id: @params["main_offer_id"] || @bundle.main_offer_id)
    @params["order_type"] = current_main_offer&.order_type
    notify_bundled_offers! if @bundle.update(@params) && !@external_update && public_before
    notify_own_offer! if @external_update
    @bundle = Bundle::Draft.call(@bundle, empty_offers: @current_offer_ids == []) if @external_update
    @bundle.service.reindex
    @bundle.offers.reindex
    @bundle.reindex
    @bundle.valid? || @bundle.draft?
  end

  private

  def notify_bundled_offers!
    if @added_bundled_offer_ids.size.positive?
      Offer
        .where(id: @added_bundled_offer_ids)
        .each { |added_bundled_offer| Offer::Mailer::Bundled.call(added_bundled_offer, @bundle.main_offer) }
    end

    if @removed_bundled_offer_ids.size.positive?
      Offer
        .where(id: @removed_bundled_offer_ids)
        .each { |removed_bundled_offer| Offer::Mailer::Unbundled.call(removed_bundled_offer, @bundle.main_offer) }
    end
  end

  def notify_own_offer!
    Offer
      .where(id: @removed_bundled_offer_ids)
      .each { |removed_bundled_offer| Offer::Mailer::Unbundled.call(@bundle.main_offer, removed_bundled_offer) }
  end
end
