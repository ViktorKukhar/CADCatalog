# Thread-local request context — isolates per-request state safely across threads.
# Set once per request in ApplicationController; read by Auditable callbacks
# to stamp audit log entries with the acting user without coupling models to controllers.
class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :ip_address
end
