# ============================================================================
# PURCHASE ORDER HELPER - RFQ Integration Methods
# ============================================================================
# Add these methods to app/helpers/purchase_orders_helper.rb
# Or create the file if it doesn't exist
# ============================================================================
module Inventory
  module PurchaseOrdersHelper
    # ===================================
    # RFQ SOURCE HELPERS
    # ===================================
    
    # Display PO source badge (RFQ or Manual)
    def po_source_badge(purchase_order)
      if purchase_order.from_rfq?
        content_tag :span, class: "badge bg-info" do
          concat content_tag(:i, "", class: "bi bi-link-45deg me-1")
          concat "From RFQ"
        end
      else
        content_tag :span, class: "badge bg-secondary" do
          concat content_tag(:i, "", class: "bi bi-pencil me-1")
          concat "Manual Entry"
        end
      end
    end
    
    # Display RFQ reference link
    def po_rfq_reference(purchase_order)
      return nil unless purchase_order.from_rfq?
      
      content_tag :div, class: "alert alert-info py-2 mb-0" do
        concat content_tag(:i, "", class: "bi bi-info-circle me-2")
        concat "Generated from RFQ: "
        concat link_to(purchase_order.rfq.rfq_number, 
                      rfq_path(purchase_order.rfq),
                      class: "alert-link fw-bold")
      end
    end
    
    # Display mini RFQ info card
    def po_rfq_info_card(purchase_order)
      return nil unless purchase_order.from_rfq?
      
      rfq = purchase_order.rfq
      
      content_tag :div, class: "card border-info shadow-sm" do
        concat content_tag(:div, class: "card-header bg-info bg-opacity-10") do
          content_tag(:h6, class: "mb-0 text-info") do
            concat content_tag(:i, "", class: "bi bi-link-45deg me-2")
            concat "Source RFQ Information"
          end
        end
        concat content_tag(:div, class: "card-body") do
          content_tag(:dl, class: "row mb-0") do
            # RFQ Number
            concat content_tag(:dt, "RFQ Number:", class: "col-sm-4 text-muted")
            concat content_tag(:dd, class: "col-sm-8") do
              link_to rfq.rfq_number, rfq_path(rfq), class: "fw-bold"
            end
            
            # Description
            if rfq.description.present?
              concat content_tag(:dt, "Description:", class: "col-sm-4 text-muted")
              concat content_tag(:dd, rfq.description, class: "col-sm-8")
            end
            
            # Award Date
            if rfq.award_date.present?
              concat content_tag(:dt, "Award Date:", class: "col-sm-4 text-muted")
              concat content_tag(:dd, rfq.award_date.strftime('%B %d, %Y'), class: "col-sm-8")
            end
            
            # Cost Savings
            if rfq.cost_savings.present? && rfq.cost_savings > 0
              concat content_tag(:dt, "Cost Savings:", class: "col-sm-4 text-muted")
              concat content_tag(:dd, class: "col-sm-8") do
                content_tag(:span, class: "text-success fw-bold") do
                  concat number_to_currency(rfq.cost_savings)
                  concat " "
                  concat content_tag(:span, "(#{number_to_percentage(rfq.cost_savings_percentage, precision: 1)})", 
                                    class: "badge bg-success")
                end
              end
            end
          end
        end
      end
    end
    
    # ===================================
    # LINE ITEM TRACEABILITY
    # ===================================
    
    # Display line item RFQ source
    def po_line_rfq_reference(line)
      return nil unless line.from_rfq?
      
      content_tag :small, class: "text-muted d-block mt-1" do
        concat content_tag(:i, "", class: "bi bi-arrow-return-right me-1")
        concat "RFQ Line #"
        concat content_tag(:code, line.rfq_item.line_number)
      end
    end
    
    # Display price comparison with RFQ target
    def po_line_price_comparison(line)
      return nil unless line.from_rfq? && line.rfq_item.target_unit_price.present?
      
      variance = line.price_variance_from_target
      
      badge_class = case variance[:over_under_target]
                    when 'UNDER' then 'bg-success'
                    when 'OVER'
                      variance[:variance_percentage] <= 5 ? 'bg-warning text-dark' : 'bg-danger'
                    end
      
      content_tag :div, class: "mt-1" do
        concat content_tag(:small, "Target: #{number_to_currency(line.rfq_item.target_unit_price)}", 
                          class: "text-muted me-2")
        concat content_tag(:span, class: "badge #{badge_class}") do
          "#{variance[:variance_percentage] > 0 ? '+' : ''}#{number_to_percentage(variance[:variance_percentage], precision: 1)}"
        end
      end
    end
    
    # Display vendor quote score
    def po_line_quote_score(line)
      return nil unless line.vendor_quote.present? && line.vendor_quote.overall_score.present?
      
      score = line.vendor_quote.overall_score
      badge_class = if score >= 80
                     'bg-success'
                   elsif score >= 60
                     'bg-warning text-dark'
                   else
                     'bg-danger'
                   end
      
      content_tag :span, class: "badge #{badge_class} ms-2" do
        concat "Score: "
        concat score.round(1).to_s
      end
    end
    
    # ===================================
    # COST SAVINGS DISPLAY
    # ===================================
    
    # Display RFQ cost savings summary card
    def rfq_cost_savings_card(purchase_order)
      return nil unless purchase_order.from_rfq?
      
      savings = purchase_order.rfq_cost_savings_summary
      return nil if savings.blank?
      
      content_tag :div, class: "card border-success shadow-sm" do
        concat content_tag(:div, class: "card-header bg-success bg-opacity-10") do
          content_tag(:h6, class: "mb-0 text-success") do
            concat content_tag(:i, "", class: "bi bi-piggy-bank me-2")
            concat "RFQ Cost Savings Analysis"
          end
        end
        concat content_tag(:div, class: "card-body") do
          content_tag(:div, class: "row text-center") do
            # Lowest Quote
            concat content_tag(:div, class: "col-md-3") do
              concat content_tag(:small, "Lowest Quote", class: "text-muted d-block")
              concat content_tag(:strong, number_to_currency(savings[:lowest_quote]), class: "fs-5")
            end
            
            # Highest Quote
            concat content_tag(:div, class: "col-md-3") do
              concat content_tag(:small, "Highest Quote", class: "text-muted d-block")
              concat content_tag(:strong, number_to_currency(savings[:highest_quote]), class: "fs-5")
            end
            
            # Awarded Amount
            concat content_tag(:div, class: "col-md-3") do
              concat content_tag(:small, "Awarded Amount", class: "text-muted d-block")
              concat content_tag(:strong, number_to_currency(savings[:awarded_amount]), 
                                class: "fs-5 text-primary")
            end
            
            # Total Savings
            concat content_tag(:div, class: "col-md-3") do
              concat content_tag(:small, "Total Savings", class: "text-muted d-block")
              concat content_tag(:strong, number_to_currency(savings[:total_savings]), 
                                class: "fs-5 text-success")
              concat content_tag(:div, class: "badge bg-success mt-1") do
                number_to_percentage(savings[:savings_percentage], precision: 2)
              end
            end
          end
        end
      end
    end
    
    # ===================================
    # BREADCRUMB HELPERS
    # ===================================
    
    # Enhanced breadcrumb with RFQ link
    def po_breadcrumb_with_rfq(purchase_order)
      content_tag :nav, "aria-label": "breadcrumb" do
        content_tag :ol, class: "breadcrumb" do
          concat content_tag(:li, class: "breadcrumb-item") do
            link_to "Home", root_path
          end
          
          if purchase_order.from_rfq?
            concat content_tag(:li, class: "breadcrumb-item") do
              link_to "RFQs", rfqs_path
            end
            concat content_tag(:li, class: "breadcrumb-item") do
              link_to purchase_order.rfq.rfq_number, rfq_path(purchase_order.rfq)
            end
          end
          
          concat content_tag(:li, class: "breadcrumb-item") do
            link_to "Purchase Orders", inventory_purchase_orders_path
          end
          
          concat content_tag(:li, purchase_order.po_number, 
                            class: "breadcrumb-item active", 
                            "aria-current": "page")
        end
      end
    end
    
    # ===================================
    # STATUS & VALIDATION HELPERS
    # ===================================
    
    # Check if PO can be edited (considering RFQ source)
    def po_editable_warning(purchase_order)
      return nil if purchase_order.can_edit?
      return nil unless purchase_order.from_rfq?
      
      content_tag :div, class: "alert alert-warning" do
        concat content_tag(:i, "", class: "bi bi-exclamation-triangle me-2")
        concat content_tag(:strong, "Note: ")
        concat "This PO was generated from RFQ #{purchase_order.rfq.rfq_number}. "
        concat "Major changes may affect traceability."
      end
    end
    
    # Display traceability status
    def po_traceability_status(purchase_order)
      return nil unless purchase_order.from_rfq?
      
      if purchase_order.fully_traceable_to_rfq?
        content_tag :div, class: "alert alert-success py-2" do
          concat content_tag(:i, "", class: "bi bi-check-circle-fill me-2")
          concat content_tag(:strong, "Full Traceability: ")
          concat "All #{purchase_order.lines.count} line items are linked to RFQ items."
        end
      else
        linked_count = purchase_order.lines.count { |l| l.rfq_item_id.present? }
        content_tag :div, class: "alert alert-warning py-2" do
          concat content_tag(:i, "", class: "bi bi-exclamation-triangle me-2")
          concat content_tag(:strong, "Partial Traceability: ")
          concat "#{linked_count} of #{purchase_order.lines.count} line items linked to RFQ."
        end
      end
    end
    
    # ===================================
    # DISPLAY FORMATTING
    # ===================================
    
    # Format RFQ comparison basis
    def format_comparison_basis(basis)
      return "N/A" if basis.blank?
      
      {
        'LOWEST_PRICE' => 'Lowest Price',
        'BEST_VALUE' => 'Best Overall Value',
        'FASTEST_DELIVERY' => 'Fastest Delivery',
        'BALANCED_SCORE' => 'Balanced Score'
      }[basis] || basis.titleize
    end
    
    # Display RFQ to PO conversion date
    def rfq_to_po_conversion_date(purchase_order)
      return nil unless purchase_order.from_rfq? && purchase_order.rfq.conversion_date.present?
      
      content_tag :small, class: "text-muted" do
        concat "Converted from RFQ on "
        concat content_tag(:strong, purchase_order.rfq.conversion_date.strftime('%B %d, %Y'))
      end
    end
  end
end