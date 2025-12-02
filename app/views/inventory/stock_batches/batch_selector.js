// app/javascript/batch_selector.js
// Helper for selecting batches in GRN, Stock Issue, Transfer forms

document.addEventListener('DOMContentLoaded', function() {
  
  // Initialize batch selection functionality
  initBatchSelectors();
  
  // Re-initialize when new line items are added (for nested forms)
  document.addEventListener('cocoon:after-insert', function() {
    initBatchSelectors();
  });
  
});

function initBatchSelectors() {
  // Find all product selects that need batch functionality
  const productSelects = document.querySelectorAll('.product-select');
  
  productSelects.forEach(function(select) {
    select.addEventListener('change', function() {
      handleProductChange(this);
    });
    
    // Trigger on page load if product already selected
    if (select.value) {
      handleProductChange(select);
    }
  });
}

function handleProductChange(productSelect) {
  const lineItem = productSelect.closest('.line-item');
  const productId = productSelect.value;
  const warehouseId = document.querySelector('#warehouse_id')?.value;
  
  if (!productId || !lineItem) return;
  
  // Find batch field container
  const batchContainer = lineItem.querySelector('.batch-field-container');
  const batchSelect = lineItem.querySelector('.batch-select');
  
  if (!batchContainer || !batchSelect) return;
  
  // Check if product is batch tracked
  fetch(`/products/${productId}/is_batch_tracked`)
    .then(response => response.json())
    .then(data => {
      if (data.is_batch_tracked) {
        // Show batch field
        batchContainer.style.display = 'block';
        batchSelect.required = true;
        
        // Load available batches
        loadBatches(productId, warehouseId, batchSelect);
      } else {
        // Hide batch field
        batchContainer.style.display = 'none';
        batchSelect.required = false;
        batchSelect.value = '';
      }
    })
    .catch(error => {
      console.error('Error checking batch tracking:', error);
    });
}

function loadBatches(productId, warehouseId, selectElement) {
  // Show loading state
  selectElement.disabled = true;
  selectElement.innerHTML = '<option value="">Loading batches...</option>';
  
  // Build URL with parameters
  let url = `/stock_batches/search?product_id=${productId}`;
  if (warehouseId) {
    url += `&warehouse_id=${warehouseId}`;
  }
  
  fetch(url)
    .then(response => response.json())
    .then(batches => {
      // Clear existing options
      selectElement.innerHTML = '<option value="">Select Batch</option>';
      
      if (batches.length === 0) {
        selectElement.innerHTML = '<option value="">No batches available</option>';
        selectElement.disabled = true;
        
        // Show warning message
        showBatchWarning(selectElement, 'No batches available for this product. Create a batch first.');
        return;
      }
      
      // Populate with batches
      batches.forEach(batch => {
        const option = document.createElement('option');
        option.value = batch.id;
        option.textContent = batch.display;
        
        // Add data attributes for additional info
        option.dataset.availableQty = batch.available_qty;
        option.dataset.expiryDate = batch.expiry_date;
        option.dataset.isExpired = batch.is_expired;
        
        // Disable expired batches
        if (batch.is_expired) {
          option.disabled = true;
          option.textContent += ' - EXPIRED';
        }
        
        selectElement.appendChild(option);
      });
      
      selectElement.disabled = false;
      
      // Initialize Select2 if available
      if (typeof $.fn.select2 !== 'undefined') {
        $(selectElement).select2({
          theme: 'bootstrap-5',
          width: '100%'
        });
      }
    })
    .catch(error => {
      console.error('Error loading batches:', error);
      selectElement.innerHTML = '<option value="">Error loading batches</option>';
      selectElement.disabled = true;
    });
}

function showBatchWarning(element, message) {
  const lineItem = element.closest('.line-item');
  
  // Remove existing warning
  const existingWarning = lineItem.querySelector('.batch-warning');
  if (existingWarning) {
    existingWarning.remove();
  }
  
  // Create warning element
  const warning = document.createElement('div');
  warning.className = 'alert alert-warning batch-warning mt-2';
  warning.innerHTML = `
    <i class="fas fa-exclamation-triangle me-2"></i>
    ${message}
    <a href="/stock_batches/new" target="_blank" class="alert-link">Create Batch</a>
  `;
  
  element.parentElement.appendChild(warning);
}

// Batch quantity validation
function validateBatchQuantity(batchSelect, quantityInput) {
  const selectedOption = batchSelect.options[batchSelect.selectedIndex];
  
  if (!selectedOption || !selectedOption.value) return true;
  
  const availableQty = parseFloat(selectedOption.dataset.availableQty || 0);
  const requestedQty = parseFloat(quantityInput.value || 0);
  
  if (requestedQty > availableQty) {
    quantityInput.setCustomValidity(
      `Insufficient stock. Available: ${availableQty}`
    );
    quantityInput.reportValidity();
    return false;
  }
  
  quantityInput.setCustomValidity('');
  return true;
}

// Export functions for external use
window.BatchSelector = {
  init: initBatchSelectors,
  loadBatches: loadBatches,
  validateQuantity: validateBatchQuantity
};
