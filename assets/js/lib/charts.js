const DEFAULT_TIMESERIES_OPTIONS = {
  colors: ["#0c9ef4", "#bdc5d4"],
  chart: {
    toolbar: {
      show: false
    },
    zoom: {
      enabled: false
    }
  },
  dataLabels: {
    style: {
      colors: ["#131823", "#bdc5d4"]
    }
  },
  fill: {
    type: "solid",
    opacity: [0.2, 0]
  },
  grid: {
    borderColor: "#f7f8fb",
    padding: {
      left: 20,
      right: 20,
      top: 20,
      bottom: 0
    }
  },
  legend: {
    show: false
  },
  markers: {
    colors: "#fff",
    strokeColor: "#0c9ef4",
    size: [5, 0],
    hover: {
      size: 7
    }
  },
  stroke: {
    curve: "smooth",
    dashArray: [[], [10, 5]]
  },
  xaxis: {
    axisBorder: {
      color: "#bdc5d4"
    },
    axisTicks: {
      color: "transparent"
    },
    labels: {
      style: {
        colors: "#bdc5d4"
      }
    },
    type: "datetime"
  },
  yaxis: {
    show: false
  }
};

export function makeTimeseriesOptions(options = {}) {
  return Object.assign({}, DEFAULT_TIMESERIES_OPTIONS, options);
}
