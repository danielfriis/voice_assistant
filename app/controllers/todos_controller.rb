class TodosController < ApplicationController
  before_action :set_todo, only: [ :update, :destroy, :complete, :uncomplete ]

  def create
    @todo = Current.user.todos.create(todo_params)

    respond_to do |format|
      format.html { redirect_to todos_path }
      format.turbo_stream
      format.json { render json: @todo, status: :created }
    end
  end

  def update
    if todo_params[:toggle_completed] == "1"
      @todo.completed_at = Time.current
    else
      @todo.completed_at = nil
    end
    @todo.assign_attributes(todo_params)
    @todo.save!

    respond_to do |format|
      format.html { redirect_to todos_path }
      format.turbo_stream
      format.json { render json: @todo, status: :ok }
    end
  end

  def complete
    @todo.completed_at = Time.current
    @todo.save!

    respond_to do |format|
      format.html { redirect_to todos_path }
      format.turbo_stream
      format.json { render json: @todo, status: :ok }
    end
  end

  def uncomplete
    @todo.completed_at = nil
    @todo.save!

    respond_to do |format|
      format.html { redirect_to todos_path }
      format.turbo_stream
      format.json { render json: @todo, status: :ok }
    end
  end

  def destroy
    @todo.destroy

    respond_to do |format|
      format.html { redirect_to todos_path }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("todos", partial: "todos/todo", locals: { todo: @todo }) }
      format.json { render json: { success: true, message: "Todo with id #{@todo.id} deleted" }, status: :ok }
    end
  end

  private

  def todo_params
    params.require(:todo).permit(:title, :description, :due_date, :due_time, :completed_at, :toggle_completed, :project_id, :time_estimate)
  end

  def set_todo
    @todo = Current.user.todos.find(params[:id])
  end
end
