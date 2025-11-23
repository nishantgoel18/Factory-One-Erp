class UnitOfMeasuresController < ApplicationController
  before_action :set_unit_of_measure, only: %i[ show edit update destroy ]

  # GET /unit_of_measures or /unit_of_measures.json
  def index
    @unit_of_measures = UnitOfMeasure.all
  end

  # GET /unit_of_measures/1 or /unit_of_measures/1.json
  def show
  end

  # GET /unit_of_measures/new
  def new
    @unit_of_measure = UnitOfMeasure.new
  end

  # GET /unit_of_measures/1/edit
  def edit
  end

  # POST /unit_of_measures or /unit_of_measures.json
  def create
    @unit_of_measure = UnitOfMeasure.new(unit_of_measure_params)

    respond_to do |format|
      if @unit_of_measure.save
        format.html { redirect_to @unit_of_measure, notice: "Unit of measure was successfully created." }
        format.json { render :show, status: :created, location: @unit_of_measure }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @unit_of_measure.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /unit_of_measures/1 or /unit_of_measures/1.json
  def update
    respond_to do |format|
      if @unit_of_measure.update(unit_of_measure_params)
        format.html { redirect_to @unit_of_measure, notice: "Unit of measure was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @unit_of_measure }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @unit_of_measure.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /unit_of_measures/1 or /unit_of_measures/1.json
  def destroy
    @unit_of_measure.destroy!

    respond_to do |format|
      format.html { redirect_to unit_of_measures_path, notice: "Unit of measure was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unit_of_measure
      @unit_of_measure = UnitOfMeasure.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def unit_of_measure_params
      params.expect(unit_of_measure: [ :name, :symbol, :is_decimal ])
    end
end
