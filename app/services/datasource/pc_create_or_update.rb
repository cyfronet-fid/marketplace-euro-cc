# frozen_string_literal: true

require "mini_magick"

class Datasource::PcCreateOrUpdate
  class ConnectionError < StandardError
  end

  class NotUpdatedError < StandardError
  end

  def initialize(eosc_registry_datasource, modified_at)
    @error_message = "Datasource haven't been updated. Message #{eosc_registry_datasource}"
    @source_type = "eosc_registry"
    @mp_datasource =
      Service
        .joins(:sources)
        .find_by(
          "service_sources.source_type": @source_type,
          "service_sources.eid": eosc_registry_datasource["serviceId"]
        )
    @datasource_hash = Importers::Datasource.call(eosc_registry_datasource, modified_at)
    @datasource_hash["status"] = @is_active ? "published" : "draft"
    @new_update_available = Datasource::PcCreateOrUpdate.new_update_available(@mp_datasource, modified_at)
  end

  def call
    create_new = @mp_datasource.nil?
    return Datasource::PcCreateOrUpdate.create_datasource(@datasource_hash) if create_new
    return @mp_datasource unless @new_update_available

    source_id = @mp_datasource&.sources&.find_by(source_type: @source_type)
    can_update = @mp_datasource.present? && source_id.present?
    unless can_update
      Datasource::PcCreateOrUpdate.handle_invalid_data(@mp_datasource, @datasource_hash, @error_message)
      return @mp_datasource
    end

    update_valid = Service::Update.call(@mp_datasource, @datasource_hash)
    unless update_valid
      Datasource::PcCreateOrUpdate.handle_invalid_data(@mp_datasource, @datasource_hash, @error_message)
      return @mp_datasource
    end

    if source_id.present?
      @mp_datasource.update(upstream_id: source_id.id)
      @mp_datasource.sources.first.update(errored: nil)
    end

    @mp_datasource.save!
    @mp_datasource
  rescue Errno::ECONNREFUSED
    raise ConnectionError, "[WARN] Connection refused."
  end

  def self.new_update_available(datasource, modified_at)
    return true unless datasource&.synchronized_at.present? && modified_at.present?
    modified_at >= datasource.synchronized_at
  end

  def self.handle_invalid_data(mp_datasource, datasource_hash, error_message)
    Rails.logger.warn error_message
    validatable_datasource = Datasource.new(datasource_hash)
    datasource_errors = validatable_datasource&.errors&.to_hash if validatable_datasource.invalid?
    mp_datasource&.sources&.first&.update(errored: datasource_errors)
  end

  def self.create_datasource(datasource_hash)
    datasource = Service.new(datasource_hash)
    if datasource.valid?
      Service::Create.call(datasource)
    else
      datasource.status = "errored"
      datasource.save(validate: false)
    end

    datasource.save!(validate: false)
    datasource
  end
end
