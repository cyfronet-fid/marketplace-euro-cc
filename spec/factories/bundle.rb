# frozen_string_literal: true

FactoryBot.define do
  factory :bundle do
    sequence(:iid) { |n| n }
    sequence(:name) { |n| "bundle #{n}" }
    sequence(:description) { |n| "Bundle #{n} description" }
    sequence(:bundle_goals) { |_n| [create(:bundle_goal)] }
    sequence(:capabilities_of_goals) { |_n| [create(:bundle_capability_of_goal)] }
    sequence(:resource_organisation) { |_n| service.resource_organisation }
    sequence(:contact_email) { |n| "contact#{n}@email.com" }
    sequence(:related_training) { true }
    sequence(:related_training_url) { |n| "https://related#{n}.training.com" }
    sequence(:order_type) { :order_required }
    sequence(:service) { |_n| create(:service, offers_count: 1, order_type: order_type) }
    sequence(:status) { :published }
    sequence(:main_offer) { |_n| create(:offer, service: service) }
    sequence(:offers) { |_n| [create(:offer)] }
    sequence(:scientific_domains) { |_n| [create(:scientific_domain)] }
    sequence(:helpdesk_url) { |n| "https://example#{n}.com" }
  end
end
