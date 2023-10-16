# frozen_string_literal: true

class Datasource::Draft < ApplicationService
  def initialize(service_eid, source: "eosc_registry")
    super()
    @service =
      Service.joins(:sources).find_by("service_sources.source_type": source, "service_sources.eid": service_eid)
  end

  def call
    if @service
      @service.update(type: "Service")
      @service
    end
  end
end
