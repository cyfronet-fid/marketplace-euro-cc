# frozen_string_literal: true

class Backoffice::DatasourcePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  MP_INTERNAL_FIELDS = [:upstream_id, [sources_attributes: %i[id source_type eid _destroy]]].freeze

  def index?
    service_portfolio_manager?
  end

  def show?
    service_portfolio_manager?
  end

  def new?
    service_portfolio_manager?
  end

  def create?
    service_portfolio_manager?
  end

  def edit?
    service_portfolio_manager?
  end

  def update?
    service_portfolio_manager?
  end

  def destroy?
    service_portfolio_manager?
  end

  def publish?
    service_portfolio_manager? && (record.draft? || record.unverified?) && !record.deleted?
  end

  def publish_unverified?
    service_portfolio_manager? && (record.draft? || record.published?) && !record.deleted?
  end

  def draft?
    service_portfolio_manager? && (record.published? || record.unverified?) && !record.deleted?
  end

  def permitted_attributes
    attrs = [
      # Basic
      :name,
      :abbreviation,
      :resource_organisation_id,
      [provider_ids: []],
      :webpage_url,
      # Marketing
      :description,
      :tagline,
      :logo,
      # Classification
      [scientific_domain_ids: []],
      [category_ids: []],
      [research_step_ids: []],
      :horizontal,
      [target_user_ids: []],
      [access_type_ids: []],
      [access_mode_ids: []],
      [tag_list: []],
      # Availability
      [geographical_availabilities: []],
      [language_availability: []],
      # Location
      [geographic_locations: []],
      # Contact
      :helpdesk_email,
      :security_contact_email,
      # Maturity
      [trl_ids: []],
      [life_cycle_status_ids: []],
      [certifications: []],
      [standards: []],
      [open_source_technologies: []],
      :version,
      :last_update,
      [changelog: []],
      #Dependencies
      [required_service_ids: []],
      [related_service_ids: []],
      [platform_ids: []],
      [catalogue_ids: []],
      # Attribution,
      [funding_body_ids: []],
      [funding_program_ids: []],
      [grant_project_names: []],
      # Management
      :helpdesk_url,
      :user_manual_url,
      :terms_of_use_url,
      :privacy_policy_url,
      :access_policies_url,
      :resource_level_url,
      :training_information_url,
      :status_monitoring_url,
      :maintenance_url,
      # Order
      :order_type,
      :order_url,
      # Financial
      :payment_model_url,
      :pricing_url,
      # Datasource Policies
      :submission_policy_url,
      :preservation_policy_url,
      :version_control,
      # Datasource content
      :jurisdiction_id,
      :datasource_classification_id,
      [research_entity_type_ids: []],
      :thematic,
      # Research Product Policies
      [research_product_access_policy_ids: []],
      # Reseach Product Metadata
      [research_product_metadata_access_policy_ids: []],
      # Other
      :upstream_id,
      [sources_attributes: %i[id source_type eid _destroy]],
      [main_contact_attributes: %i[id first_name last_name email phone organisation position]],
      [public_contacts_attributes: %i[id first_name last_name email phone organisation position _destroy]],
      [
        persistent_identity_systems_attributes: [
          :id,
          :datasource_id,
          :entity_type_id,
          [entity_type_scheme_ids: []],
          :_destroy
        ]
      ],
      [link_multimedia_urls_attributes: %i[id name url _destroy]],
      [link_use_cases_urls_attributes: %i[id name url _destroy]],
      [link_research_product_license_urls_attributes: %i[id name url _destroy]],
      [link_research_product_metadata_license_urls_attributes: %i[id name url _destroy]]
    ]

    !@record.is_a?(Provider) || @record.upstream_id.blank? ? attrs : attrs & MP_INTERNAL_FIELDS
  end

  def data_administrator?
    record.administered_by?(user)
  end

  private

  def service_portfolio_manager?
    user&.service_portfolio_manager?
  end
end
