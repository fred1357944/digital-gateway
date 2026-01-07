import { Controller } from "@hotwired/stimulus"

// Chart.js is loaded via CDN UMD, access via window.Chart
// Pareto Radar Chart Controller
// Visualizes multi-objective optimization results for product comparison
export default class extends Controller {
  static values = {
    products: Array,
    objectives: { type: Array, default: [
      { key: "price", label: "價格效益" },
      { key: "quality", label: "品質評分" },
      { key: "speed", label: "交付速度" },
      { key: "reputation", label: "賣家信譽" },
      { key: "relevance", label: "相關性" }
    ]}
  }

  static targets = ["canvas", "legend"]

  connect() {
    if (this.productsValue.length > 0) {
      this.renderChart()
    }
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  productsValueChanged() {
    if (this.chart) {
      this.chart.destroy()
    }
    if (this.productsValue.length > 0) {
      this.renderChart()
    }
  }

  renderChart() {
    // Wait for Chart.js to be available
    if (typeof Chart === 'undefined') {
      console.warn('Chart.js not loaded yet, retrying...')
      setTimeout(() => this.renderChart(), 100)
      return
    }

    const ctx = this.canvasTarget.getContext('2d')

    this.chart = new Chart(ctx, {
      type: 'radar',
      data: {
        labels: this.objectivesValue.map(o => o.label),
        datasets: this.productsValue.map((product, index) => ({
          label: product.title,
          data: this.objectivesValue.map(o => product.scores[o.key] || 50),
          borderColor: this.getColor(index),
          backgroundColor: this.getColor(index, 0.15),
          pointBackgroundColor: this.getColor(index),
          pointBorderColor: '#fff',
          pointHoverBackgroundColor: '#fff',
          pointHoverBorderColor: this.getColor(index),
          borderWidth: 2,
          pointRadius: 4
        }))
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          r: {
            beginAtZero: true,
            max: 100,
            min: 0,
            ticks: {
              stepSize: 20,
              backdropColor: 'transparent',
              color: '#737373',
              font: { size: 10 }
            },
            grid: {
              color: '#e5e5e5'
            },
            angleLines: {
              color: '#e5e5e5'
            },
            pointLabels: {
              color: '#171717',
              font: { size: 12, weight: '500' }
            }
          }
        },
        plugins: {
          legend: {
            display: true,
            position: 'bottom',
            labels: {
              usePointStyle: true,
              padding: 20,
              font: { size: 12 }
            }
          },
          tooltip: {
            backgroundColor: '#171717',
            titleFont: { size: 13, weight: '600' },
            bodyFont: { size: 12 },
            padding: 12,
            cornerRadius: 8,
            callbacks: {
              label: (context) => {
                const objective = this.objectivesValue[context.dataIndex]
                return `${context.dataset.label}: ${context.raw}分`
              }
            }
          }
        },
        interaction: {
          intersect: false,
          mode: 'index'
        }
      }
    })
  }

  getColor(index, alpha = 1) {
    const colors = [
      [59, 130, 246],   // blue
      [239, 68, 68],    // red
      [34, 197, 94],    // green
      [168, 85, 247],   // purple
      [249, 115, 22],   // orange
      [236, 72, 153],   // pink
      [20, 184, 166],   // teal
      [245, 158, 11]    // amber
    ]
    const [r, g, b] = colors[index % colors.length]
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }

  // Action: highlight a specific product
  highlight(event) {
    const productIndex = event.params.index
    if (this.chart) {
      this.chart.setActiveElements([
        { datasetIndex: productIndex, index: 0 }
      ])
      this.chart.update()
    }
  }

  // Action: reset highlight
  resetHighlight() {
    if (this.chart) {
      this.chart.setActiveElements([])
      this.chart.update()
    }
  }
}
