class ProjectsController < ApplicationController
  before_action :set_project, only: [ :update, :destroy ]

  def create
    @project = Current.user.projects.create(project_params)

    respond_to do |format|
      format.html { redirect_to projects_path }
      format.turbo_stream
      format.json { render json: @project, status: :created }
    end
  end

  def update
    @project.update(project_params)

    respond_to do |format|
      format.html { redirect_to projects_path }
      format.turbo_stream
      format.json { render json: @project, status: :ok }
    end
  end

  def destroy
    @project.destroy

    respond_to do |format|
      format.html { redirect_to projects_path }
      format.turbo_stream
      format.json { render json: { success: true, message: "Project with id #{@project.id} deleted" }, status: :ok }
    end
  end

  private

  def project_params
    params.require(:project).permit(:title, :description, :archived_at)
  end

  def set_project
    @project = Current.user.projects.find(params[:id])
  end
end
