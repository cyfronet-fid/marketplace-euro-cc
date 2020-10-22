# frozen_string_literal: true

class Service::Create
  def initialize(service)
    @service = service
  end

  def call
    @service.save
    Offer::Create.new(Offer.new(name: "Offer",
                                description: "#{@service.name} Offer",
                                order_type: @service.order_type,
                                order_url: @service.order_url,
                                webpage: @service.webpage_url, status: "published", service: @service)).call
    @service
  end
end
