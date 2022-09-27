# frozen_string_literal: true

class DatasourcesController < ApplicationController
  def index
    @datasources = Datasource.visible.sort_by(&:name)
  end

  def show
    @datasource = Datasource.friendly.find(params[:id])
  end
end
