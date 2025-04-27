class MemoriesController < ApplicationController
  before_action :set_memory, only: [ :destroy ]

  def create
    @memory = Current.user.memories.create(memory_params)

    respond_to do |format|
      format.html { redirect_to memories_path }
      format.turbo_stream
      format.json { render json: @memory, status: :created }
    end
  end

  def update
    @memory.update(memory_params)

    respond_to do |format|
      format.html { redirect_to memories_path }
      format.turbo_stream
      format.json { render json: @memory, status: :ok }
    end
  end

  def destroy
    @memory.destroy

    respond_to do |format|
      format.html { redirect_to memories_path }
      format.turbo_stream
      format.json { render json: { success: true, message: "Memory with id #{@memory.id} deleted" }, status: :ok }
    end
  end

  private

  def memory_params
    params.require(:memory).permit(:subject, :content)
  end

  def set_memory
    @memory = Current.user.memories.find(params[:id])
  end
end
