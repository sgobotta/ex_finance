import RealtimeLineChart from '../charts/line_chart'

export default {
  destroyed() {
    this.chart.destroy()
  },
  mounted() {
    this.chart = new RealtimeLineChart(this.el)

    this.handleEvent('reset-dataset', ({ label }) => {
      this.chart.resetDataset(label)
    })

    this.handleEvent('new-point', ({
      background_color,
      border_color,
      data_label,
      label,
      value
    }) => {
      this.chart.addPoint(
        data_label, label, value, background_color, border_color
      )
    })
  }
}
