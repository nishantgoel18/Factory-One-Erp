class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  mount_uploader :avatar, ImageUploader

  has_many :assigned_work_order_operations, class_name: 'WorkOrderOperation', foreign_key: :assigned_operator_id
  belongs_to :organization
  
  # ========================================
  # ENUMS (ADD THESE)
  # ========================================
  enum :role, {
    org_owner: 0,      # Full access - created during signup
    org_admin: 1,      # Admin access - can manage users
    manager: 2,        # Department manager
    planner: 3,        # MRP planner
    buyer: 4,          # Procurement
    operator: 5,       # Shop floor operator
    viewer: 6          # Read-only access
  }
  
  # ========================================
  # VALIDATIONS (ADD THESE)
  # ========================================
  validates :organization_id, presence: true
  validates :email, uniqueness: { scope: :organization_id }
  validates :role, presence: true
  
  # ========================================
  # SCOPES (ADD THESE)
  # ========================================
  scope :active_users, -> { where(deleted: [false, nil]) }
  scope :admins, -> { where(role: [:org_owner, :org_admin]) }
  scope :operators_only, -> { where(role: :operator) }
  
  # ========================================
  # ROLE CHECKS (ADD THESE)
  # ========================================
  def admin?
    org_owner? || org_admin?
  end
  
  def can_manage_users?
    admin?
  end
  
  def can_manage_settings?
    org_owner?
  end
  
  def can_approve_pos?
    admin? || manager? || buyer?
  end
  
  def can_manage_mrp?
    admin? || planner?
  end
  
  def shop_floor_user?
    operator?
  end
  
  # ========================================
  # DISPLAY HELPERS (ADD THESE)
  # ========================================
  def role_name
    role.humanize
  end
  
  def role_badge_class
    case role
    when 'org_owner' then 'danger'
    when 'org_admin' then 'warning'
    when 'manager' then 'info'
    when 'planner' then 'primary'
    when 'buyer' then 'success'
    when 'operator' then 'secondary'
    when 'viewer' then 'light'
    else 'secondary'
    end
  end
  
  # Keep your existing methods...
end