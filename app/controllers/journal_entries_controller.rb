class JournalEntriesController < ApplicationController
  before_action :set_journal_entry, only: %i[ show edit update destroy ]

  # GET /journal_entries or /journal_entries.json
  def index
    @journal_entries = JournalEntry.all
  end

  # GET /journal_entries/1 or /journal_entries/1.json
  def show
  end

  # GET /journal_entries/new
  def new
    @journal_entry = JournalEntry.new
    2.times { @journal_entry.journal_lines.build }
  end

  # GET /journal_entries/1/edit
  def edit
    if !(@journal_entry.posted_at.nil? && !@journal_entry.reversed? && !@journal_entry.is_reversal?)
      redirect_to @journal_entry, alert: "Journal entry can be edited as it has either posted or reversed."
    end
  end

  # POST /journal_entries or /journal_entries.json
  def create
    @journal_entry = JournalEntry.new(journal_entry_params)

    respond_to do |format|
      if @journal_entry.save
        format.html { redirect_to @journal_entry, notice: "Journal entry was successfully created." }
        format.json { render :show, status: :created, location: @journal_entry }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @journal_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /journal_entries/1 or /journal_entries/1.json
  def update
    respond_to do |format|
      if @journal_entry.update(journal_entry_params)
        format.html { redirect_to @journal_entry, notice: "Journal entry was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @journal_entry }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @journal_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /journal_entries/1 or /journal_entries/1.json
  def destroy
    @journal_entry.destroy!

    respond_to do |format|
      format.html { redirect_to journal_entries_path, notice: "Journal entry was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def post
    @journal_entry = JournalEntry.find(params[:id])
    status = @journal_entry.post!(current_user)
    redirect_to @journal_entry, notice: status
  end

  def reverse
    original = JournalEntry.find(params[:id])

    if original.posted_at.blank?
      redirect_to original, alert: "Only posted entries can be reversed."
      return
    end

    if original.reversed? || original.reversal_entry_id.present?
      redirect_to original, alert: "Reversal entry cannot be reversed again."
      return
    end

    reversal = JournalEntry.new(
      entry_date: Date.today,
      description: "Reversal of #{original.entry_number}",
      accounting_period: original.accounting_period,
      reference_id: original.reference_id,
      reference_type: original.reference_type,
      is_reversal: true
    )

    original.journal_lines.non_deleted.each do |line|
      reversal.journal_lines.build(
        account_id: line.account_id,
        debit: line.credit,   # reverse!!!
        credit: line.debit,   # reverse!!!
        description: "Reversal of line ##{line.id}"
      )
    end

    if reversal.save
      reversal.post!(current_user)
      original.update!(
        reversed: true,
        reversed_at: Time.current,
        reversal_entry_id: reversal.id
      )

      redirect_to reversal, notice: "Reversal entry #{reversal.entry_number} created and posted."
    else
      redirect_to original, alert: "Reversal failed: #{reversal.errors.full_messages.join(', ')}"
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_journal_entry
      @journal_entry = JournalEntry.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def journal_entry_params
      params.require(:journal_entry).permit(
        :entry_date,
        :description,
        :accounting_period,
        :reference_id,
        :reference_type,
        journal_lines_attributes: [
          :id, :account_id, :debit, :credit, :description, :_destroy
        ]
      )
    end
end
