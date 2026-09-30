class DatasetExamplesController < ApplicationController
  before_action :set_project
  before_action :set_dataset
  before_action :set_example, only: [:show, :edit, :update, :destroy, :accept, :reject]

  def show; end

  def edit; end

  def update
    messages = params[:dataset_example][:messages]
    if messages.is_a?(String)
      begin
        messages = JSON.parse(messages)
      rescue JSON::ParserError
        @example.errors.add(:messages, 'must be valid JSON')
        return render :edit, status: :unprocessable_entity
      end
    end

    if @example.update(messages: messages)
      redirect_to project_dataset_path(@project, @dataset), notice: 'Example updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @example.destroy
    redirect_to project_dataset_path(@project, @dataset), notice: 'Example deleted.'
  end

  def accept
    @example.accept!
    respond_to do |format|
      format.html { redirect_to project_dataset_path(@project, @dataset), notice: 'Example accepted.' }
      format.turbo_stream
    end
  end

  def reject
    @example.reject!
    respond_to do |format|
      format.html { redirect_to project_dataset_path(@project, @dataset), notice: 'Example rejected.' }
      format.turbo_stream
    end
  end

  def bulk_action
    action = params[:bulk_action]
    ids = params[:example_ids] || []
    examples = @dataset.dataset_examples.where(id: ids)

    case action
    when 'accept'
      examples.update_all(accepted: true)
      notice = "#{examples.count} examples accepted."
    when 'reject'
      examples.update_all(accepted: false)
      notice = "#{examples.count} examples rejected."
    when 'delete'
      count = examples.count
      examples.destroy_all
      notice = "#{count} examples deleted."
    else
      notice = 'Unknown action.'
    end

    redirect_to project_dataset_path(@project, @dataset), notice: notice
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_dataset
    @dataset = @project.datasets.find(params[:dataset_id])
  end

  def set_example
    @example = @dataset.dataset_examples.find(params[:id])
  end
end
