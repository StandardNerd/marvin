class TrainingRunsController < ApplicationController
  before_action :set_project
  before_action :set_training_run, only: [:show, :edit, :update, :destroy, :start, :cancel, :metrics]

  def new
    @datasets = @project.datasets.ready
    @training_run = @project.training_runs.build(
      base_model: @project.base_model,
      configuration: TrainingRun::DEFAULT_CONFIGURATION,
      status: 'pending'
    )
  end

  def create
    @training_run = @project.training_runs.build(training_run_params)
    @training_run.status = 'pending'
    @training_run.base_model ||= @project.base_model

    # Build configuration from form params
    @training_run.configuration = build_configuration

    if @training_run.save
      redirect_to project_training_run_path(@project, @training_run), notice: 'Experiment created.'
    else
      @datasets = @project.datasets.ready
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @latest_metrics = @training_run.training_metrics.ordered.last
    @metrics_data = @training_run.training_metrics.ordered.pluck(:step, :loss)
  end

  def edit
    @datasets = @project.datasets.ready
  end

  def update
    if @training_run.pending?
      @training_run.configuration = build_configuration
      if @training_run.update(training_run_params)
        redirect_to project_training_run_path(@project, @training_run), notice: 'Experiment updated.'
      else
        @datasets = @project.datasets.ready
        render :edit, status: :unprocessable_entity
      end
    else
      redirect_to project_training_run_path(@project, @training_run), alert: 'Cannot edit a non-pending experiment.'
    end
  end

  def destroy
    if @training_run.active?
      redirect_to project_training_run_path(@project, @training_run), alert: 'Cannot delete an active experiment.'
    else
      @training_run.destroy
      redirect_to project_path(@project), notice: 'Experiment deleted.'
    end
  end

  def start
    if @training_run.status == 'pending'
      accepted_count = @training_run.dataset.dataset_examples.accepted.count
      if accepted_count < 1
        redirect_to project_training_run_path(@project, @training_run), alert: 'Dataset must have at least one accepted example.'
        return
      end
      @training_run.queue!
      TrainingRunJob.perform_later(@training_run.id)
      redirect_to project_training_run_path(@project, @training_run), notice: 'Training queued.'
    else
      redirect_to project_training_run_path(@project, @training_run), alert: 'Training can only be started from pending status.'
    end
  end

  def cancel
    if @training_run.active?
      TrainingRunCancelJob.perform_later(@training_run.id)
      redirect_to project_training_run_path(@project, @training_run), notice: 'Cancellation requested.'
    else
      redirect_to project_training_run_path(@project, @training_run), alert: 'Training is not active.'
    end
  end

  def metrics
    @metrics_data = @training_run.training_metrics.ordered.pluck(:step, :loss)
    @latest_metrics = @training_run.training_metrics.ordered.last
    respond_to do |format|
      format.json {
        render json: {
          status: @training_run.status,
          metrics: @metrics_data,
          latest: @latest_metrics&.attributes,
          duration: @training_run.formatted_duration
        }
      }
      format.turbo_stream
    end
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_training_run
    @training_run = @project.training_runs.find(params[:id])
  end

  def training_run_params
    params.require(:training_run).permit(:name, :base_model, :dataset_id)
  end

  def build_configuration
    config = params[:training_run][:configuration] || {}
    {
      'method' => 'qlora',
      'lora_r' => (config[:lora_r] || 16).to_i,
      'lora_alpha' => (config[:lora_alpha] || 32).to_i,
      'lora_dropout' => (config[:lora_dropout] || 0.05).to_f,
      'learning_rate' => (config[:learning_rate] || 0.0002).to_f,
      'epochs' => (config[:epochs] || 3).to_i,
      'batch_size' => (config[:batch_size] || 1).to_i,
      'gradient_accumulation_steps' => (config[:gradient_accumulation_steps] || 8).to_i,
      'max_seq_length' => (config[:max_seq_length] || 2048).to_i,
      'quantization' => config[:quantization] || '4bit_nf4'
    }
  end
end
