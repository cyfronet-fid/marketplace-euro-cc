# frozen_string_literal: true

class Favourites::ServicesController < FavouritesController
  skip_before_action :authenticate_user!, only: :update

  def update
    @service = Service.where(slug: params.fetch(:favourite)).first
    cookies[:favourites] ||= []
    added = Array(cookies[:favourites].split("&"))
    if params.fetch(:update) == "true"
      current_user.present? ? UserService.new(user: current_user, service: @service).save : added << @service.slug
      respond_to { |format| format.js { render_popup_json(title, text, logged?) } } unless has_many?
    elsif current_user.present?
      UserService.find_by(user: current_user, service: @service)&.destroy
    else
      added.delete(@service.slug)
    end
    respond_to { |format| format.js { render_empty_box } } if current_user&.favourite_services&.empty?
    cookies[:favourites] = added.reject(&:blank?)
  end

  private

  def has_many?
    UserService.where(user: current_user).size > 1 || cookies[:favourites]&.size > 1
  end

  def text
    if logged?
      "You have added the first EOSC Resource to your favourites list. \n" \
        "You can reach your Favourite Resources using My EOSC Marketplace menu available in the top right corner."
    else
      "If you want this EOSC resource to be added to your Favourite Resources list, " \
        "please log in. In other case, we won't be able to remember this resource as your favourite."
    end
  end

  def title
    logged? ? "Great!" : "Save your favourites!"
  end

  def logged?
    current_user.present?
  end
end
