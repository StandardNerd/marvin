module Api
  module V1
    class DatasetsController < BaseController
      def export
        dataset = Dataset.find(params[:id])
        examples = dataset.dataset_examples.accepted

        # Stream JSONL response
        response.headers['Content-Type'] = 'application/x-jsonl'
        response.headers['Content-Disposition'] = "attachment; filename=\"dataset-#{dataset.id}.jsonl\""

        self.response_body = Enumerator.new do |yielder|
          examples.find_each do |example|
            yielder << { messages: example.messages }.to_json + "\n"
          end
        end
      end
    end
  end
end
