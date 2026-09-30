import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = { data: Array }

  connect() {
    if (this.dataValue.length > 0) {
      this.drawChart()
    }
  }

  drawChart() {
    const canvas = this.canvasTarget
    const ctx = canvas.getContext('2d')
    const data = this.dataValue // [[step, loss], ...]
    
    // Set canvas size
    const rect = canvas.parentElement.getBoundingClientRect()
    canvas.width = rect.width
    canvas.height = rect.height
    
    const padding = { top: 20, right: 20, bottom: 40, left: 60 }
    const chartWidth = canvas.width - padding.left - padding.right
    const chartHeight = canvas.height - padding.top - padding.bottom
    
    if (data.length < 2) return
    
    const steps = data.map(d => d[0])
    const losses = data.map(d => d[1])
    const minStep = Math.min(...steps)
    const maxStep = Math.max(...steps)
    const minLoss = Math.min(...losses) * 0.95
    const maxLoss = Math.max(...losses) * 1.05
    
    // Background
    ctx.fillStyle = '#1f2937'
    ctx.fillRect(0, 0, canvas.width, canvas.height)
    
    // Grid lines
    ctx.strokeStyle = '#374151'
    ctx.lineWidth = 1
    for (let i = 0; i <= 4; i++) {
      const y = padding.top + (chartHeight * i / 4)
      ctx.beginPath()
      ctx.moveTo(padding.left, y)
      ctx.lineTo(canvas.width - padding.right, y)
      ctx.stroke()
      
      // Y-axis labels
      const value = maxLoss - (maxLoss - minLoss) * i / 4
      ctx.fillStyle = '#9ca3af'
      ctx.font = '11px monospace'
      ctx.textAlign = 'right'
      ctx.fillText(value.toFixed(3), padding.left - 8, y + 4)
    }
    
    // X-axis labels
    ctx.textAlign = 'center'
    ctx.fillStyle = '#9ca3af'
    for (let i = 0; i <= 4; i++) {
      const x = padding.left + (chartWidth * i / 4)
      const step = Math.round(minStep + (maxStep - minStep) * i / 4)
      ctx.fillText(step.toString(), x, canvas.height - 10)
    }
    
    // Axis labels
    ctx.fillStyle = '#6b7280'
    ctx.font = '12px sans-serif'
    ctx.textAlign = 'center'
    ctx.fillText('Step', canvas.width / 2, canvas.height - 2)
    
    ctx.save()
    ctx.translate(12, canvas.height / 2)
    ctx.rotate(-Math.PI / 2)
    ctx.fillText('Loss', 0, 0)
    ctx.restore()
    
    // Draw line
    ctx.strokeStyle = '#818cf8'
    ctx.lineWidth = 2
    ctx.beginPath()
    data.forEach((point, i) => {
      const x = padding.left + ((point[0] - minStep) / (maxStep - minStep || 1)) * chartWidth
      const y = padding.top + ((maxLoss - point[1]) / (maxLoss - minLoss || 1)) * chartHeight
      if (i === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    })
    ctx.stroke()
    
    // Draw points (for small datasets)
    if (data.length < 50) {
      ctx.fillStyle = '#818cf8'
      data.forEach(point => {
        const x = padding.left + ((point[0] - minStep) / (maxStep - minStep || 1)) * chartWidth
        const y = padding.top + ((maxLoss - point[1]) / (maxLoss - minLoss || 1)) * chartHeight
        ctx.beginPath()
        ctx.arc(x, y, 3, 0, Math.PI * 2)
        ctx.fill()
      })
    }
  }
}
