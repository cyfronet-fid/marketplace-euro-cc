# frozen_string_literal: true

module Services::OrderingConfiguration::Bundles
  class DraftsController < Services::OrderingConfiguration::ApplicationController
    before_action :find_and_authorize

    def create
      if Bundle::Draft.call(@bundle)
        redirect_to backoffice_service_path(@service)
      else
        flash[:alert] =
          "Bundle not drafted, errors: " +
            "#{@bundle.errors.messages.each.map { |k, v| "The field #{k} #{v.join(", ")}" }.join(", ")}"
        redirect_to edit_backoffice_service_offer_path(@service, @bundle)
      end
    end

    private

    def find_and_authorize
      @service = Service.friendly.find(params[:service_id])
      @bundle = Bundle.find_by(iid: params[:bundle_id])
      authorize(@bundle, :draft?)
    end
  end
end
