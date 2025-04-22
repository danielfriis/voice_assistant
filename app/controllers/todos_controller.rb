class TodosController < ApplicationController
  before_action :set_todo, only: [ :update, :destroy ]

  def index
    @todos = Current.user.todos
  end

  def create
    @todo = Current.user.todos.create(todo_params)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("todos", partial: "todos/todo", locals: { todo: @todo }) }
      format.html { redirect_to todos_path }
    end
  end

  def update
  end

  def destroy
  end

  private

  def set_todo
    @todo = Current.user.todos.find(params[:id])
  end
end
