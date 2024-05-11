// assets/js/line_chart.js

// https://www.chartjs.org/docs/3.6.1/getting-started/integration
// html#bundlers-webpack-rollup-etc
import Chart from 'chart.js/auto'

Chart.defaults.color = '#71717acc';
Chart.defaults.borderColor = '#71717a44';

// A wrapper of Chart.js that configures the realtime line chart.
export default class {
  constructor(ctx) {
    this.colors = [
      'rgba(74, 222, 128, 1)'
    ]

    const config = {
      data: {datasets: [], labels: []},
      options: {
        datasets: {
       // https://www.chartjs.org/docs/3.6.0/charts/line.html#dataset-properties
          line: {
            tension: 0.09
          }
        },
        plugins: {
    // https://nagix.github.io/chartjs-plugin-streaming/2.0.0/guide/options.html
          streaming: {
            delay: 1500,
            duration: 60 * 1000
          }
        },
        scales: {
          x: {
            // chartjs-plugin-streaming
            suggestedMax: 200,
            suggestedMin: 50
          },
          y: {
            suggestedMax: 1200,
            suggestedMin: 800
          }
        }
      },
      type: 'line'
    }

    this.chart = new Chart(ctx, config)
  }

  resetDataset(label) {
    const dataset = this._findDataset(label)
    if (dataset) {
      dataset.data = []
    }
    this.chart.config.data.labels = []
    this.chart.update()
  }

  addPoint(data_label, label, value, backgroundColor, borderColor) {   
    this.chart.config.data.labels.push(data_label)
    const dataset = this._findDataset(label) || this._createDataset(
      label, backgroundColor, borderColor
    )
    dataset.data.push({x: Date.now(), y: value})
    
    const numericYValues = dataset.data.map(point => parseFloat(point.y))
    const suggestedMin = Math.min(...numericYValues);
    const suggestedMax = Math.max(...numericYValues);
    this.chart.config.options.scales.y.suggestedMin = suggestedMin - 50
    this.chart.config.options.scales.y.suggestedMax = suggestedMax + 50
    
    this.chart.update()
  }

  destroy() {
    this.chart.destroy()
  }

  _findDataset(label) {
    return this.chart.data.datasets.find((dataset) => dataset.label === label)
  }

  _createDataset(label, backgroundColor, borderColor) {
    const newDataset = {
      backgroundColor,
      borderColor,
      data: [],
      fill: 'origin',
      label
    }
    this.chart.data.datasets.push(newDataset)
    return newDataset
  }
}
