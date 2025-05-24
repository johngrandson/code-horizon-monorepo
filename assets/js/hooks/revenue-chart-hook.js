const RevenueChartHook = {
  mounted() {
    this.initChart();
  },

  updated() {
    this.updateChart();
  },

  destroyed() {
    // Clean up chart instance to prevent memory leaks
    this.destroyChart();
  },

  initChart() {
    try {
      // Ensure element is a canvas
      if (!this.el || this.el.tagName !== "CANVAS") {
        console.error("RevenueChartHook: Element must be a canvas");
        return;
      }

      const ctx = this.el.getContext("2d");
      if (!ctx) {
        console.error("RevenueChartHook: Could not get canvas context");
        return;
      }

      const chartData = this.parseChartData();
      if (!chartData.length) {
        this.renderEmptyState();
        return;
      }

      // Destroy existing chart before creating new one
      this.destroyChart();

      this.chart = new Chart(ctx, {
        type: "line",
        data: {
          labels: chartData.map((d) => this.formatPeriodLabel(d.period_start)),
          datasets: [
            {
              label: "Revenue",
              data: chartData.map((d) => this.parseRevenue(d.value)),
              borderColor: "rgb(59, 130, 246)",
              backgroundColor: "rgba(59, 130, 246, 0.1)",
              fill: true,
              tension: 0.4,
              pointBackgroundColor: "rgb(59, 130, 246)",
              pointBorderColor: "#ffffff",
              pointBorderWidth: 2,
              pointRadius: 4,
              pointHoverRadius: 6,
            },
          ],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: {
            intersect: false,
            mode: "index",
          },
          plugins: {
            legend: {
              display: false,
            },
            tooltip: {
              backgroundColor: "rgba(0, 0, 0, 0.8)",
              titleColor: "#ffffff",
              bodyColor: "#ffffff",
              borderColor: "rgba(59, 130, 246, 0.8)",
              borderWidth: 1,
              callbacks: {
                label: (context) => {
                  const value = context.parsed.y;
                  return `Revenue: ${this.formatCurrency(value)}`;
                },
              },
            },
          },
          scales: {
            x: {
              grid: {
                display: false,
              },
              ticks: {
                color: "#6b7280",
                font: {
                  size: 12,
                },
              },
            },
            y: {
              beginAtZero: true,
              grid: {
                color: "rgba(107, 114, 128, 0.1)",
              },
              ticks: {
                color: "#6b7280",
                font: {
                  size: 12,
                },
                callback: (value) => this.formatCurrency(value),
              },
            },
          },
          elements: {
            point: {
              hoverBorderWidth: 3,
            },
          },
        },
      });
    } catch (error) {
      console.error("RevenueChartHook: Error initializing chart:", error);
      this.renderErrorState();
    }
  },

  updateChart() {
    try {
      if (!this.chart) {
        this.initChart();
        return;
      }

      const chartData = this.parseChartData();

      if (!chartData.length) {
        this.destroyChart();
        this.renderEmptyState();
        return;
      }

      // Update chart data
      this.chart.data.labels = chartData.map((d) =>
        this.formatPeriodLabel(d.period_start)
      );
      this.chart.data.datasets[0].data = chartData.map((d) =>
        this.parseRevenue(d.value)
      );

      // Animate the update
      this.chart.update("active");
    } catch (error) {
      console.error("RevenueChartHook: Error updating chart:", error);
      this.renderErrorState();
    }
  },

  destroyChart() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }
  },

  parseChartData() {
    try {
      const rawData = this.el.dataset.chartData;
      if (!rawData) return [];

      const data = JSON.parse(rawData);
      return Array.isArray(data) ? data : [];
    } catch (error) {
      console.error("RevenueChartHook: Error parsing chart data:", error);
      return [];
    }
  },

  parseRevenue(value) {
    const parsed = parseFloat(value);
    return isNaN(parsed) ? 0 : parsed;
  },

  formatCurrency(value) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
  },

  formatPeriodLabel(periodStart) {
    try {
      // Handle different date formats
      const date = new Date(periodStart);
      if (isNaN(date.getTime())) {
        return periodStart; // Return as-is if not a valid date
      }

      return date.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
      });
    } catch (error) {
      return periodStart;
    }
  },

  renderEmptyState() {
    if (this.el && this.el.getContext) {
      const ctx = this.el.getContext("2d");
      ctx.clearRect(0, 0, this.el.width, this.el.height);

      // Add empty state text
      ctx.fillStyle = "#6b7280";
      ctx.font = "14px system-ui, sans-serif";
      ctx.textAlign = "center";
      ctx.fillText(
        "No revenue data available",
        this.el.width / 2,
        this.el.height / 2
      );
    }
  },

  renderErrorState() {
    if (this.el && this.el.getContext) {
      const ctx = this.el.getContext("2d");
      ctx.clearRect(0, 0, this.el.width, this.el.height);

      // Add error state text
      ctx.fillStyle = "#ef4444";
      ctx.font = "14px system-ui, sans-serif";
      ctx.textAlign = "center";
      ctx.fillText(
        "Error loading chart data",
        this.el.width / 2,
        this.el.height / 2
      );
    }
  },
};

export default RevenueChartHook;
