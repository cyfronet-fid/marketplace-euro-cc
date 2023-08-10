# frozen_string_literal: true

class ResearchProductsController < ApplicationController
  before_action :authenticate_user!, :project_research_product
  before_action :find_research_product, :load_projects, only: :new

  def new; end

  def create
    template = permitted_attributes(ProjectResearchProduct)
    if @project_research_product.update(template)
      redirect_to project_services_path(@project_research_product.project)
    else
      @research_product = @project_research_product.research_product || ResearchProduct.new
      load_projects
      render :new
    end
  end

  def project_research_product
    @project_research_product ||= ProjectResearchProduct.new
  end

  def load_projects
    @projects = policy_scope(current_user.projects.active)
  end

  def find_research_product
    if params.key?(:resource_id) && params.key?(:resource_type)
      @research_product = ResearchProduct.find_or_initialize_by(params.permit(%i[resource_id resource_type]))
      download_research_product_data
    else
      flash[:alert] = "No research product parameters"
      @research_product = ResearchProduct.new
    end
  end

  def download_research_product_data
    base_url = Mp::Application.config.search_service_base_url
    endpoint = Mp::Application.config.search_service_research_product_endpoint
    path = "#{@research_product.resource_type}/#{CGI.escape(@research_product.resource_id)}"
    response = Faraday.get(base_url + endpoint + path)
    @research_product.update(JSON.parse(response.body))
  end
end
