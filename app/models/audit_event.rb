class AuditEvent < ApplicationRecord
  belongs_to :community
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, presence: true
end
