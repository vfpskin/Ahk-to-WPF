using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Controls.DataVisualization.Charting;

namespace AhkControls
{
    public class ChartDataPoint
    {
        public string IndependentValue { get; set; }
        public double DependentValue { get; set; }
    }

    public class ChartControl : AhkControlBase
    {
        private Chart _chart;
        private string _chartType = "Column";
        private List<List<ChartDataPoint>> _seriesData = new List<List<ChartDataPoint>>();

        public ChartControl()
        {
            _chart = new Chart();
            _chart.HorizontalAlignment = HorizontalAlignment.Stretch;
            _chart.VerticalAlignment = VerticalAlignment.Stretch;
            _chart.Background = Brushes.White;
            Child = _chart;
        }

        private ISeries CreateSeries(string type, IEnumerable data)
        {
            switch (type.ToLower())
            {
                case "line":
                    return new LineSeries { IndependentValuePath = "IndependentValue", DependentValuePath = "DependentValue", ItemsSource = data };
                case "bar":
                    return new BarSeries { IndependentValuePath = "IndependentValue", DependentValuePath = "DependentValue", ItemsSource = data };
                case "pie":
                    return new PieSeries { IndependentValuePath = "IndependentValue", DependentValuePath = "DependentValue", ItemsSource = data };
                case "area":
                    return new AreaSeries { IndependentValuePath = "IndependentValue", DependentValuePath = "DependentValue", ItemsSource = data };
                case "scatter":
                    return new ScatterSeries { IndependentValuePath = "IndependentValue", DependentValuePath = "DependentValue", ItemsSource = data };
                default:
                    return new ColumnSeries { IndependentValuePath = "IndependentValue", DependentValuePath = "DependentValue", ItemsSource = data };
            }
        }

        private void RebuildSeries()
        {
            _chart.Series.Clear();
            for (int i = 0; i < _seriesData.Count; i++)
                _chart.Series.Add(CreateSeries(_chartType, _seriesData[i]));
        }

        public override bool SetProperty(string property, string value)
        {
            switch (property)
            {
                case "ChartType":
                    _chartType = value;
                    if (_seriesData.Count > 0)
                        RebuildSeries();
                    return true;

                case "Title":
                    _chart.Title = value;
                    return true;

                case "Data":
                    _seriesData.Clear();
                    ParseSeries(value);
                    RebuildSeries();
                    return true;

                case "AddSeries":
                    ParseSeries(value);
                    RebuildSeries();
                    return true;

                case "Clear":
                    _chart.Series.Clear();
                    _seriesData.Clear();
                    return true;
            }
            return false;
        }

        private void ParseSeries(string val)
        {
            string[] parts = val.Split('|');
            if (parts.Length < 3) return;

            var data = new List<ChartDataPoint>();
            for (int i = 1; i < parts.Length - 1; i += 2)
            {
                string cat = parts[i];
                double d;
                if (double.TryParse(parts[i + 1], NumberStyles.Any, CultureInfo.InvariantCulture, out d))
                    data.Add(new ChartDataPoint { IndependentValue = cat, DependentValue = d });
            }

            if (data.Count > 0)
                _seriesData.Add(data);
        }

        public override string GetValue()
        {
            return _chartType + "|" + (_chart.Title != null ? _chart.Title.ToString() : "");
        }
    }
}
