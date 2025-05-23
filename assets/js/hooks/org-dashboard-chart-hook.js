const OrgDashboardChart = {
  init(selector = "#org-dashboard-chart") {
    const chartElement = document.querySelector(selector);
    if (!chartElement) return null;

    // ✅ Função melhorada para detectar tema
    const detectTheme = () => {
      return (
        document.documentElement.classList.contains("dark") ||
        document.body.classList.contains("dark") ||
        window.matchMedia("(prefers-color-scheme: dark)").matches
      );
    };

    const baseConfig = {
      series: [
        {
          name: "Store sales",
          data: [0, 27000, 5000, 27000, 40000, 30000, 48000],
        },
        {
          name: "Online sales",
          data: [19500, 10000, 1000, 17500, 6000, 20500, 24000],
        },
        {
          name: "Others",
          data: [12500, 7000, 4000, 8000, 10000, 12800, 8500],
        },
      ],
      chart: {
        height: 100,
        type: "line",
        sparkline: {
          enabled: true,
        },
        background: "transparent",
        // ✅ Melhorar responsividade
        parentHeightOffset: 0,
        redrawOnParentResize: true,
      },
      stroke: {
        curve: "straight",
        width: 3,
      },
      xaxis: {
        type: "category",
        categories: [
          "25 January 2023",
          "1 February 2023",
          "5 February 2023",
          "10 February 2023",
          "15 February 2023",
          "20 February 2023",
          "25 February 2023",
        ],
        crosshairs: {
          show: false,
        },
      },
      markers: {
        hover: {
          size: 0,
        },
      },
      tooltip: {
        enabled: true,
        shared: true,
        intersect: false,
        custom: function ({ series, seriesIndex, dataPointIndex, w }) {
          const categories = w.globals.categoryLabels;
          const title = categories[dataPointIndex];

          let tooltipContent = `
                <div class="min-w-48 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg p-3">
                  <div class="text-sm font-medium text-gray-900 dark:text-white mb-2">${title}</div>
                  <div class="space-y-1">
              `;

          series.forEach((seriesData, index) => {
            const seriesName = w.globals.seriesNames[index];
            const value = seriesData[dataPointIndex];
            const color = w.globals.colors[index];

            tooltipContent += `
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <div class="w-2 h-2 rounded-full mr-2" style="background-color: ${color}"></div>
                      <span class="text-sm text-gray-600 dark:text-gray-300">${seriesName}:</span>
                    </div>
                    <span class="text-sm font-medium text-gray-900 dark:text-white ms-2">$${value.toLocaleString()}</span>
                  </div>
                `;
          });

          tooltipContent += `
                  </div>
                </div>
              `;

          return tooltipContent;
        },
      },
    };

    const lightThemeConfig = {
      colors: ["#2563EB", "#9333ea", "#d1d5db"],
      grid: {
        borderColor: "#e5e7eb",
      },
      fill: {
        type: "gradient",
        gradient: {
          shade: "light",
          type: "vertical",
          shadeIntensity: 0.5,
          gradientToColors: ["#60a5fa", "#c084fc", "#f3f4f6"],
          inverseColors: false,
          opacityFrom: 0.6,
          opacityTo: 0.3,
          stops: [0, 100],
        },
      },
    };

    const darkThemeConfig = {
      colors: ["#3b82f6", "#a855f7", "#737373"],
      grid: {
        borderColor: "#404040",
      },
      fill: {
        type: "gradient",
        gradient: {
          shade: "dark",
          type: "vertical",
          shadeIntensity: 0.5,
          gradientToColors: ["#1e40af", "#7c3aed", "#525252"],
          inverseColors: false,
          opacityFrom: 0.6,
          opacityTo: 0.3,
          stops: [0, 100],
        },
      },
    };

    // ✅ Função para criar configuração completa
    const createConfig = () => {
      const isDarkMode = detectTheme();
      const themeConfig = isDarkMode ? darkThemeConfig : lightThemeConfig;
      return { ...baseConfig, ...themeConfig };
    };

    // ✅ Aguardar um pouco para garantir que CSS está carregado
    return new Promise((resolve) => {
      setTimeout(() => {
        const finalConfig = createConfig();
        const chart = new ApexCharts(chartElement, finalConfig);

        chart.render().then(() => {
          // ✅ Forçar atualização após render para garantir tema correto
          const correctedConfig = createConfig();
          chart.updateOptions(correctedConfig, false, false);
        });

        // Watch for theme changes
        const observer = new MutationObserver((mutations) => {
          mutations.forEach((mutation) => {
            if (mutation.attributeName === "class") {
              const newConfig = createConfig();
              chart.updateOptions(newConfig, false, true);
            }
          });
        });

        observer.observe(document.documentElement, {
          attributes: true,
          attributeFilter: ["class"],
        });

        const chartInstance = {
          chart,
          observer,
          destroy() {
            observer.disconnect();
            chart.destroy();
          },
        };

        resolve(chartInstance);
      }, 50); // ✅ Pequeno delay para aguardar CSS
    });
  },
};

// ✅ Sintaxe correta do export
const OrgDashboardChartHook = {
  mounted() {
    // ✅ Aguardar promessa
    OrgDashboardChart.init(`#${this.el.id}`).then((instance) => {
      this.chartInstance = instance;
    });
  },

  destroyed() {
    if (this.chartInstance && this.chartInstance.destroy) {
      this.chartInstance.destroy();
    }
  },
};

export default OrgDashboardChartHook;
