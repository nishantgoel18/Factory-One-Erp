# frozen_string_literal: true
# app/models/concerns/user_trackable.rb

# ============================================================================
# CONCERN: UserTrackable
# ============================================================================
# Tracks who created/updated records
# Use with OrganizationScoped for complete audit trail
# ============================================================================

module UserTrackable
  extend ActiveSupport::Concern
  
  included do
    # ========================================
    # ASSOCIATIONS (if your models have these columns)
    # ========================================
    belongs_to :created_by, class_name: 'User', optional: true
    belongs_to :updated_by, class_name: 'User', optional: true
    
    # ========================================
    # CALLBACKS
    # ========================================
    before_create :set_created_by
    before_save :set_updated_by
    
    # ========================================
    # SCOPES
    # ========================================
    scope :created_by_user, ->(user_id) { where(created_by_id: user_id) }
    scope :created_by_current_user, -> { where(created_by_id: Current.user_id) if Current.user_id.present? }
    
    private
    
    def set_created_by
      self.created_by_id ||= Current.user_id if Current.user_id.present?
    end
    
    def set_updated_by
      self.updated_by_id = Current.user_id if Current.user_id.present?
    end
  end
  
  # ========================================
  # INSTANCE METHODS
  # ========================================
  def created_by_name
    created_by&.full_name || 'System'
  end
  
  def updated_by_name
    updated_by&.full_name || 'System'
  end
  
  def created_by_current_user?
    created_by_id == Current.user_id
  end
end