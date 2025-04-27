class NotesController < ApplicationController
  before_action :set_note, only: [ :destroy ]

  def create
    @note = Current.user.notes.create(note_params)

    respond_to do |format|
      format.html { redirect_to notes_path }
      format.turbo_stream
      format.json { render json: @note, status: :created }
    end
  end

  def update
    @note.update(note_params)

    respond_to do |format|
      format.html { redirect_to notes_path }
      format.turbo_stream
      format.json { render json: @note, status: :ok }
    end
  end

  def destroy
    @note.destroy

    respond_to do |format|
      format.html { redirect_to notes_path }
      format.turbo_stream
      format.json { render json: { success: true, message: "Note with id #{@note.id} deleted" }, status: :ok }
    end
  end

  private

  def note_params
    params.require(:note).permit(:project_id, :content)
  end

  def set_note
    @note = Current.user.notes.find(params[:id])
  end
end
