class Users::ProfilesController < ApplicationController
  before_action :set_user

  def show
    @records = @user.records.order(created_at: :desc)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
