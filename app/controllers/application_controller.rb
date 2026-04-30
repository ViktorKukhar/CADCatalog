class ApplicationController < ActionController::Base
  before_action :set_current_request_context

  private

  # Populates thread-local Current attributes so models can stamp audit logs
  # with the authenticated user and IP without depending on the controller layer.
  def set_current_request_context
    Current.user       = current_user
    Current.ip_address = request.remote_ip
  end
end
