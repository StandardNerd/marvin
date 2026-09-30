module ApplicationHelper
  include Pagy::Frontend

  def status_badge(status)
    colors = {
      'uploaded' => 'bg-blue-900/50 text-blue-300 border-blue-700',
      'processing' => 'bg-yellow-900/50 text-yellow-300 border-yellow-700',
      'ready' => 'bg-green-900/50 text-green-300 border-green-700',
      'pending' => 'bg-gray-700/50 text-gray-300 border-gray-600',
      'queued' => 'bg-blue-900/50 text-blue-300 border-blue-700',
      'running' => 'bg-yellow-900/50 text-yellow-300 border-yellow-700',
      'completed' => 'bg-green-900/50 text-green-300 border-green-700',
      'failed' => 'bg-red-900/50 text-red-300 border-red-700',
      'cancelled' => 'bg-gray-700/50 text-gray-400 border-gray-600'
    }
    css = colors[status.to_s.downcase] || 'bg-gray-700/50 text-gray-300 border-gray-600'
    content_tag :span, status.upcase, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border #{css}"
  end

  def page_header(title, &block)
    content_tag :div, class: 'flex items-center justify-between mb-8' do
      content_tag(:h1, title, class: 'text-2xl font-bold text-white') +
        (block ? capture(&block) : ''.html_safe)
    end
  end

  def card(&block)
    content_tag :div, class: 'bg-gray-800/50 rounded-lg border border-gray-700 p-6', &block
  end

  def empty_state(message, icon: nil)
    content_tag :div, class: 'text-center py-12' do
      content_tag(:p, message, class: 'text-gray-400 text-sm')
    end
  end
end
