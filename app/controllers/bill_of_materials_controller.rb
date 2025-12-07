class BillOfMaterialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product
  before_action :set_bill_of_material, only: %i[ show edit update destroy activate ]

  def show
  end

  def new
    @bill_of_material = BillOfMaterial.new
  end

  def create
    @bill_of_material = BillOfMaterial.new(bill_of_material_params)
    @bill_of_material.created_by = current_user

    if @bill_of_material.save
      process_bom_items
      redirect_to [@product, @bill_of_material], notice: "BOM created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @bill_of_material.update(bill_of_material_params)
      process_bom_items
      redirect_to [@product, @bill_of_material], notice: "BOM updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @bill_of_material.update_attribute(:deleted, true)
    redirect_to product_path(@product), alert: "BOM deleted."
  end

  def activate
    if @bill_of_material.update(status: 'ACTIVE')
      redirect_to product_path(@product), alert: "BOM Activated."
    else
      redirect_to product_path(@product), alert: "BOM could not be activated due to following errors: #{@bill_of_material.errors.to_sentence}"
    end

  end

  private

  def set_bill_of_material
    @bill_of_material = BillOfMaterial.non_deleted.find_by(id: params[:id], product_id: params[:product_id])
    redirect_to @product, notice: 'BOM not found!' if @bill_of_material.blank?
  end

  def set_product
    @product = Product.non_deleted.find_by(id: params[:product_id])
    redirect_to products_path, notice: 'Product not found!' if @product.blank?
  end

  def process_bom_items

    new_items = (params["bom_item"]["new"] || {})
    existing_items = (params["bom_item"]["existing"] || {})
    @bill_of_material.bom_items.non_deleted.where.not(id: existing_items.keys).delete_all

    new_items.each do |id, value|
      item = @bill_of_material.bom_items.build(component_id: value[:component], uom_id: value[:uom], quantity: value[:quantity], scrap_percent: value[:scrap_percent], line_note: value[:line_note])
      item.save(validate: false)
    end
    existing_items.each do |id, value|
      item = @bill_of_material.bom_items.build(component_id: value[:component], uom_id: value[:uom], quantity: value[:quantity], scrap_percent: value[:scrap_percent], line_note: value[:line_note])
      item.save(validate: false)
    end
  end

  def bom_item_params
    params.permit(
      :component_id, :quantity, :uom_id, :scrap_percent, :line_note
    )
  end

  def bill_of_material_params
    params.require(:bill_of_material).permit(
      :product_id,
      :code,
      :name,
      :revision,
      :status,
      :effective_from,
      :effective_to,
      :is_default,
      :notes,
    )
  end
end